package models

import "time"

// OrderStatus represents the lifecycle status of an order.
type OrderStatus string

const (
	OrderConfirmed     OrderStatus = "confirmed"
	OrderPreparing     OrderStatus = "preparing"
	OrderBaking        OrderStatus = "baking"
	OrderOutForDelivery OrderStatus = "outForDelivery"
	OrderDelivered     OrderStatus = "delivered"
)

// OrderItem represents a single item in an order.
type OrderItem struct {
	ID             string   `json:"id"`
	PizzaID        string   `json:"pizzaId"`
	PizzaName      string   `json:"pizzaName"`
	PizzaImageURL  string   `json:"pizzaImageUrl"`
	PizzaPrice     float64  `json:"pizzaPrice"`
	Quantity       int      `json:"quantity"`
	Size           string   `json:"size"`
	Crust          string   `json:"crust"`
	Sauce          string   `json:"sauce"`
	ExtraToppings  []string `json:"extraToppings"`
	ItemTotal      float64  `json:"itemTotal"`
}

// Order represents a placed order.
type Order struct {
	ID                string      `json:"id"`
	UserID            string      `json:"userId"`
	Items             []OrderItem `json:"items"`
	Status            OrderStatus `json:"status"`
	Subtotal          float64     `json:"subtotal"`
	DeliveryFee       float64     `json:"deliveryFee"`
	Discount          float64     `json:"discount"`
	Total             float64     `json:"total"`
	DeliveryAddress   string      `json:"deliveryAddress"`
	PaymentMethod     string      `json:"paymentMethod"`
	CreatedAt         time.Time   `json:"createdAt"`
	EstimatedDelivery *time.Time  `json:"estimatedDelivery,omitempty"`
}

// PlaceOrderRequest is the payload for placing an order.
type PlaceOrderRequest struct {
	Items           []OrderItem `json:"items"`
	DeliveryAddress string      `json:"deliveryAddress"`
	PaymentMethod   string      `json:"paymentMethod"`
	Subtotal        float64     `json:"subtotal"`
	DeliveryFee     float64     `json:"deliveryFee"`
	Discount        float64     `json:"discount"`
	Total           float64     `json:"total"`
}
