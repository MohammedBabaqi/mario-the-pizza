package handlers

import (
	"encoding/json"
	"net/http"
	"strings"

	"mario-backend/data"
	"mario-backend/models"
)

// PizzaHandler serves pizza menu data.
type PizzaHandler struct {
	pizzas      []models.Pizza
	categories  []models.Category
	ingredients []models.Ingredient
}

// NewPizzaHandler creates a handler with seeded data.
func NewPizzaHandler() *PizzaHandler {
	return &PizzaHandler{
		pizzas:      data.SeedPizzas(),
		categories:  data.SeedCategories(),
		ingredients: data.SeedIngredients(),
	}
}

// GetPizzas handles GET /api/pizzas
// Supports optional ?category=xxx query parameter.
func (h *PizzaHandler) GetPizzas(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"Method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	category := r.URL.Query().Get("category")

	var result []models.Pizza
	if category == "" || category == "all" {
		result = h.pizzas
	} else {
		for _, p := range h.pizzas {
			if strings.EqualFold(p.Category, category) {
				result = append(result, p)
			}
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}

// GetPizzaByID handles GET /api/pizzas/{id}
func (h *PizzaHandler) GetPizzaByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"Method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	// Extract ID from path: /api/pizzas/{id}
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/api/pizzas/"), "/")
	id := parts[0]

	for _, p := range h.pizzas {
		if p.ID == id {
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(p)
			return
		}
	}

	http.Error(w, `{"error":"Pizza not found"}`, http.StatusNotFound)
}

// GetCategories handles GET /api/pizzas/categories
func (h *PizzaHandler) GetCategories(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"Method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(h.categories)
}

// GetIngredients handles GET /api/pizzas/ingredients
func (h *PizzaHandler) GetIngredients(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"Method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(h.ingredients)
}
