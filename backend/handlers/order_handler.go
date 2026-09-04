package handlers

import (
	"encoding/json"
	"fmt"
	"log"
	"math"
	"net/http"
	"strings"
	"sync"
	"time"

	"mario-backend/middleware"
	"mario-backend/models"
)

// OrderHandler manages order operations.
type OrderHandler struct {
	mu     sync.RWMutex
	orders map[string][]models.Order // keyed by userId
}

// NewOrderHandler creates a new OrderHandler with pre-seeded demo orders.
func NewOrderHandler() *OrderHandler {
	now := time.Now()
	yesterday := now.Add(-24 * time.Hour)
	twentyMinsAgo := now.Add(-25 * time.Minute)
	estimatedSoon := now.Add(15 * time.Minute)

	handler := &OrderHandler{
		orders: make(map[string][]models.Order),
	}

	demoOrders := []models.Order{
		{
			ID:     "ORD-98422",
			UserID: "user_demo_mario",
			Items: []models.OrderItem{
				{
					ID:            "item_bbq_1",
					PizzaID:       "bbq_chicken",
					PizzaName:     "BBQ Chicken",
					PizzaImageURL: "https://images.unsplash.com/photo-1594007654729-407eedc4be65?w=600&h=600&fit=crop",
					PizzaPrice:    13.99,
					Quantity:      1,
					Size:          "Large",
					Crust:         "Cheese Stuffed",
					Sauce:         "BBQ",
					ExtraToppings: []string{"Extra Cheese", "Onions"},
					ItemTotal:     15.99,
				},
			},
			Status:            models.OrderOutForDelivery,
			Subtotal:          15.99,
			DeliveryFee:       0.0,
			Discount:          0.0,
			Total:             15.99,
			DeliveryAddress:   "Hadda St, Building 14, Sanaa",
			PaymentMethod:     "Credit / Debit Card",
			CreatedAt:         twentyMinsAgo,
			EstimatedDelivery: &estimatedSoon,
		},
		{
			ID:     "ORD-98421",
			UserID: "user_demo_mario",
			Items: []models.OrderItem{
				{
					ID:            "item_pep_1",
					PizzaID:       "pepperoni",
					PizzaName:     "Pepperoni",
					PizzaImageURL: "https://images.unsplash.com/photo-1628840042765-356cda07504e?w=600&h=600&fit=crop",
					PizzaPrice:    10.99,
					Quantity:      1,
					Size:          "Medium",
					Crust:         "Classic",
					Sauce:         "Tomato",
					ExtraToppings: []string{},
					ItemTotal:     10.99,
				},
				{
					ID:            "item_mar_1",
					PizzaID:       "margherita",
					PizzaName:     "Margherita",
					PizzaImageURL: "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600&h=600&fit=crop",
					PizzaPrice:    8.99,
					Quantity:      1,
					Size:          "Medium",
					Crust:         "Thin Crust",
					Sauce:         "Tomato",
					ExtraToppings: []string{"Fresh Basil"},
					ItemTotal:     9.99,
				},
			},
			Status:            models.OrderDelivered,
			Subtotal:          20.98,
			DeliveryFee:       2.0,
			Discount:          0.0,
			Total:             22.98,
			DeliveryAddress:   "Hadda St, Building 14, Sanaa",
			PaymentMethod:     "Cash on Delivery",
			CreatedAt:         yesterday,
			EstimatedDelivery: &yesterday,
		},
	}

	handler.orders["user_demo_mario"] = demoOrders
	handler.orders["guest"] = demoOrders

	return handler
}

// PlaceOrder handles POST /api/orders
func (h *OrderHandler) PlaceOrder(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, `{"error":"Method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	userID := "user_demo_mario"
	if val := r.Context().Value(middleware.UserIDKey); val != nil {
		userID = val.(string)
	}

	var req models.PlaceOrderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error":"Invalid request body"}`, http.StatusBadRequest)
		return
	}

	if len(req.Items) == 0 {
		http.Error(w, `{"error":"Order must contain at least one item"}`, http.StatusBadRequest)
		return
	}

	// Server-side recalculation of subtotal and validation
	var calculatedSubtotal float64
	for _, it := range req.Items {
		itemSum := it.ItemTotal
		if itemSum <= 0 {
			itemSum = it.PizzaPrice * float64(it.Quantity)
		}
		calculatedSubtotal += itemSum
	}
	calculatedSubtotal = math.Round(calculatedSubtotal*100) / 100

	// Server-side delivery fee: Free for orders >= $25.00, otherwise $2.99
	deliveryFee := 2.99
	if calculatedSubtotal >= 25.00 {
		deliveryFee = 0.0
	}

	discount := req.Discount
	if discount < 0 {
		discount = 0
	}

	calculatedTotal := math.Round((calculatedSubtotal+deliveryFee-discount)*100) / 100
	if calculatedTotal < 0 {
		calculatedTotal = 0
	}

	now := time.Now()
	estimated := now.Add(30 * time.Minute)

	order := models.Order{
		ID:                fmt.Sprintf("ORD-%d", now.UnixMilli()%100000),
		UserID:            userID,
		Items:             req.Items,
		Status:            models.OrderConfirmed,
		Subtotal:          calculatedSubtotal,
		DeliveryFee:       deliveryFee,
		Discount:          discount,
		Total:             calculatedTotal,
		DeliveryAddress:   req.DeliveryAddress,
		PaymentMethod:     req.PaymentMethod,
		CreatedAt:         now,
		EstimatedDelivery: &estimated,
	}

	h.mu.Lock()
	// Prepend to top of user's orders
	h.orders[userID] = append([]models.Order{order}, h.orders[userID]...)
	// Also keep in guest demo list
	h.orders["guest"] = append([]models.Order{order}, h.orders["guest"]...)
	h.mu.Unlock()

	log.Printf("🍕 [ORDER CREATED] Placed %s for %s: %d item(s), Subtotal: $%.2f, Fee: $%.2f, Total: $%.2f",
		order.ID, userID, len(order.Items), order.Subtotal, order.DeliveryFee, order.Total)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(order)
}

// GetOrders handles GET /api/orders
func (h *OrderHandler) GetOrders(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"Method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	userID := "user_demo_mario"
	if val := r.Context().Value(middleware.UserIDKey); val != nil {
		userID = val.(string)
	}

	h.mu.RLock()
	userOrders := h.orders[userID]
	if len(userOrders) == 0 {
		userOrders = h.orders["user_demo_mario"]
	}
	h.mu.RUnlock()

	if userOrders == nil {
		userOrders = []models.Order{}
	}

	log.Printf("📦 [ORDERS] Returning %d orders for user %s", len(userOrders), userID)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(userOrders)
}

// GetOrderByID handles GET /api/orders/{id}
func (h *OrderHandler) GetOrderByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"Method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	// Extract order ID from path: /api/orders/{id}
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/api/orders/"), "/")
	orderID := parts[0]

	h.mu.RLock()
	defer h.mu.RUnlock()

	// Search across all orders
	for _, userOrderList := range h.orders {
		for _, order := range userOrderList {
			if order.ID == orderID {
				log.Printf("🔍 [ORDER TRACK] Found order %s (status: %s)", order.ID, order.Status)
				w.Header().Set("Content-Type", "application/json")
				json.NewEncoder(w).Encode(order)
				return
			}
		}
	}

	log.Printf("⚠️ [ORDER TRACK] Order %s not found", orderID)
	http.Error(w, `{"error":"Order not found"}`, http.StatusNotFound)
}
