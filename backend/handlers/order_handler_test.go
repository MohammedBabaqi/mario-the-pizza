package handlers

import (
	"testing"

	"mario-backend/models"
)

func TestCalculateUnitPriceUsesServerPrices(t *testing.T) {
	handler := NewOrderHandler(nil)
	price, valid := handler.calculateUnitPrice(10, models.OrderItem{
		Size: "Large", Crust: "Cheesy", Sauce: "Spicy",
		ExtraToppings: []string{"Extra Cheese"},
	})
	if !valid {
		t.Fatal("valid customization was rejected")
	}
	if price != 17.5 {
		t.Fatalf("expected 17.50, got %.2f", price)
	}
}

func TestCalculateUnitPriceRejectsUnknownCustomization(t *testing.T) {
	handler := NewOrderHandler(nil)
	_, valid := handler.calculateUnitPrice(10, models.OrderItem{
		Size: "Huge", Crust: "Classic", Sauce: "Tomato",
	})
	if valid {
		t.Fatal("unknown size was accepted")
	}
}
