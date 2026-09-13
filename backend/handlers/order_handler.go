package handlers

import (
	"encoding/json"
	"errors"
	"math"
	"net/http"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"mario-backend/data"
	"mario-backend/middleware"
	"mario-backend/models"
)

type OrderHandler struct {
	db               *pgxpool.Pool
	toppingModifiers map[string]float64
}

func NewOrderHandler(db *pgxpool.Pool) *OrderHandler {
	modifiers := make(map[string]float64)
	for _, ingredient := range data.SeedIngredients() {
		if ingredient.Type == "topping" || ingredient.Type == "cheese" {
			modifiers[strings.ToLower(ingredient.Name)] = ingredient.PriceModifier
		}
	}
	return &OrderHandler{db: db, toppingModifiers: modifiers}
}

func (h *OrderHandler) PlaceOrder(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req models.PlaceOrderRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	req.DeliveryAddress = strings.TrimSpace(req.DeliveryAddress)
	req.PaymentMethod = strings.TrimSpace(req.PaymentMethod)
	if len(req.Items) == 0 || len(req.Items) > 50 {
		writeError(w, http.StatusBadRequest, "Order must contain between 1 and 50 items")
		return
	}
	if req.DeliveryAddress == "" || len(req.DeliveryAddress) > 500 {
		writeError(w, http.StatusBadRequest, "A valid delivery address is required")
		return
	}
	if req.PaymentMethod == "" || len(req.PaymentMethod) > 100 {
		writeError(w, http.StatusBadRequest, "A valid payment method is required")
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to start order")
		return
	}
	defer tx.Rollback(r.Context())

	items := make([]models.OrderItem, 0, len(req.Items))
	var subtotal float64
	for _, requested := range req.Items {
		if requested.Quantity < 1 || requested.Quantity > 99 {
			writeError(w, http.StatusBadRequest, "Item quantity must be between 1 and 99")
			return
		}

		var pizza models.Pizza
		err := tx.QueryRow(r.Context(), `
			SELECT id, name, image_url, price FROM pizzas WHERE id = $1`, requested.PizzaID).Scan(
			&pizza.ID, &pizza.Name, &pizza.ImageURL, &pizza.Price,
		)
		if errors.Is(err, pgx.ErrNoRows) {
			writeError(w, http.StatusBadRequest, "Order contains an unknown pizza")
			return
		}
		if err != nil {
			writeError(w, http.StatusInternalServerError, "Failed to validate order")
			return
		}

		unitPrice, valid := h.calculateUnitPrice(pizza.Price, requested)
		if !valid {
			writeError(w, http.StatusBadRequest, "Order contains an invalid customization")
			return
		}
		itemID := strings.TrimSpace(requested.ID)
		if itemID == "" {
			itemID, err = randomID("item_")
			if err != nil {
				writeError(w, http.StatusInternalServerError, "Failed to create order item")
				return
			}
		}
		itemTotal := roundMoney(unitPrice * float64(requested.Quantity))
		item := models.OrderItem{
			ID: itemID, PizzaID: pizza.ID, PizzaName: pizza.Name,
			PizzaImageURL: pizza.ImageURL, PizzaPrice: pizza.Price,
			Quantity: requested.Quantity, Size: requested.Size, Crust: requested.Crust,
			Sauce: requested.Sauce, ExtraToppings: requested.ExtraToppings,
			ItemTotal: itemTotal,
		}
		items = append(items, item)
		subtotal += itemTotal
	}

	subtotal = roundMoney(subtotal)
	deliveryFee := 2.99
	if subtotal >= 25 {
		deliveryFee = 0
	}
	discount := 0.0
	total := roundMoney(subtotal + deliveryFee - discount)
	now := time.Now().UTC()
	estimated := now.Add(30 * time.Minute)
	orderID, err := randomID("ORD-")
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to create order")
		return
	}

	_, err = tx.Exec(r.Context(), `
		INSERT INTO orders (
			id, user_id, status, subtotal, delivery_fee, discount, total,
			delivery_address, payment_method, created_at, estimated_delivery
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)`,
		orderID, userID, models.OrderConfirmed, subtotal, deliveryFee, discount,
		total, req.DeliveryAddress, req.PaymentMethod, now, estimated,
	)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to save order")
		return
	}

	for _, item := range items {
		toppingsJSON, err := json.Marshal(item.ExtraToppings)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "Failed to encode order item")
			return
		}
		_, err = tx.Exec(r.Context(), `
			INSERT INTO order_items (
				order_id, id, pizza_id, pizza_name, pizza_image_url, pizza_price,
				quantity, size, crust, sauce, extra_toppings, item_total
			) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
			orderID, item.ID, item.PizzaID, item.PizzaName, item.PizzaImageURL,
			item.PizzaPrice, item.Quantity, item.Size, item.Crust, item.Sauce,
			toppingsJSON, item.ItemTotal,
		)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "Failed to save order item")
			return
		}
	}
	if err := tx.Commit(r.Context()); err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to complete order")
		return
	}

	writeJSON(w, http.StatusCreated, models.Order{
		ID: orderID, UserID: userID, Items: items, Status: models.OrderConfirmed,
		Subtotal: subtotal, DeliveryFee: deliveryFee, Discount: discount, Total: total,
		DeliveryAddress: req.DeliveryAddress, PaymentMethod: req.PaymentMethod,
		CreatedAt: now, EstimatedDelivery: &estimated,
	})
}

func (h *OrderHandler) GetOrders(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT id, user_id, status, subtotal, delivery_fee, discount, total,
		       delivery_address, payment_method, created_at, estimated_delivery
		FROM orders WHERE user_id = $1 ORDER BY created_at DESC`, userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to load orders")
		return
	}
	defer rows.Close()

	orders := make([]models.Order, 0)
	for rows.Next() {
		var order models.Order
		if err := rows.Scan(
			&order.ID, &order.UserID, &order.Status, &order.Subtotal,
			&order.DeliveryFee, &order.Discount, &order.Total, &order.DeliveryAddress,
			&order.PaymentMethod, &order.CreatedAt, &order.EstimatedDelivery,
		); err != nil {
			writeError(w, http.StatusInternalServerError, "Failed to read order data")
			return
		}
		order.Items, err = h.loadOrderItems(r, order.ID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "Failed to load order items")
			return
		}
		orders = append(orders, order)
	}
	if rows.Err() != nil {
		writeError(w, http.StatusInternalServerError, "Failed to load orders")
		return
	}
	writeJSON(w, http.StatusOK, orders)
}

func (h *OrderHandler) GetOrderByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}
	orderID := strings.Split(strings.TrimPrefix(r.URL.Path, "/api/orders/"), "/")[0]

	var order models.Order
	err := h.db.QueryRow(r.Context(), `
		SELECT id, user_id, status, subtotal, delivery_fee, discount, total,
		       delivery_address, payment_method, created_at, estimated_delivery
		FROM orders WHERE id = $1 AND user_id = $2`, orderID, userID).Scan(
		&order.ID, &order.UserID, &order.Status, &order.Subtotal, &order.DeliveryFee,
		&order.Discount, &order.Total, &order.DeliveryAddress, &order.PaymentMethod,
		&order.CreatedAt, &order.EstimatedDelivery,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		writeError(w, http.StatusNotFound, "Order not found")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to load order")
		return
	}
	order.Items, err = h.loadOrderItems(r, order.ID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to load order items")
		return
	}
	writeJSON(w, http.StatusOK, order)
}

func (h *OrderHandler) loadOrderItems(r *http.Request, orderID string) ([]models.OrderItem, error) {
	rows, err := h.db.Query(r.Context(), `
		SELECT id, pizza_id, pizza_name, pizza_image_url, pizza_price, quantity,
		       size, crust, sauce, extra_toppings, item_total
		FROM order_items WHERE order_id = $1 ORDER BY id`, orderID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]models.OrderItem, 0)
	for rows.Next() {
		var item models.OrderItem
		var toppingsJSON []byte
		if err := rows.Scan(
			&item.ID, &item.PizzaID, &item.PizzaName, &item.PizzaImageURL,
			&item.PizzaPrice, &item.Quantity, &item.Size, &item.Crust,
			&item.Sauce, &toppingsJSON, &item.ItemTotal,
		); err != nil {
			return nil, err
		}
		if err := json.Unmarshal(toppingsJSON, &item.ExtraToppings); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (h *OrderHandler) calculateUnitPrice(base float64, item models.OrderItem) (float64, bool) {
	sizes := map[string]float64{"small": 0, "medium": 2, "large": 4}
	crusts := map[string]float64{"classic": 0, "thin": 0, "cheesy": 1.5, "stuffed": 2.5}
	sauces := map[string]float64{"tomato": 0, "spicy": 0.5, "creamy": 0.5}
	sizePrice, sizeOK := sizes[strings.ToLower(item.Size)]
	crustPrice, crustOK := crusts[strings.ToLower(item.Crust)]
	saucePrice, sauceOK := sauces[strings.ToLower(item.Sauce)]
	if !sizeOK || !crustOK || !sauceOK || len(item.ExtraToppings) > 20 {
		return 0, false
	}
	price := base + sizePrice + crustPrice + saucePrice
	for _, topping := range item.ExtraToppings {
		modifier, ok := h.toppingModifiers[strings.ToLower(strings.TrimSpace(topping))]
		if !ok {
			return 0, false
		}
		price += modifier
	}
	return roundMoney(price), true
}

func roundMoney(value float64) float64 {
	return math.Round(value*100) / 100
}
