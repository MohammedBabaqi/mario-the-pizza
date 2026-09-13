package handlers

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"mario-backend/data"
	"mario-backend/models"
)

type PizzaHandler struct {
	db          *pgxpool.Pool
	categories  []models.Category
	ingredients []models.Ingredient
}

func NewPizzaHandler(db *pgxpool.Pool) *PizzaHandler {
	return &PizzaHandler{
		db:          db,
		categories:  data.SeedCategories(),
		ingredients: data.SeedIngredients(),
	}
}

// GetPizzas handles GET /api/pizzas
// Supports optional ?category=xxx query parameter.
func (h *PizzaHandler) GetPizzas(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	category := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("category")))
	query := `SELECT id, name, description, price, rating, calories, protein, fat,
	                 carbs, ingredients, category, image_url, is_popular, is_recommended
	          FROM pizzas`
	args := []any{}
	if category != "" && category != "all" {
		query += " WHERE LOWER(category) = $1"
		args = append(args, category)
	}
	query += " ORDER BY name"

	rows, err := h.db.Query(r.Context(), query, args...)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to load pizzas")
		return
	}
	defer rows.Close()

	result := make([]models.Pizza, 0)
	for rows.Next() {
		pizza, err := scanPizza(rows)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "Failed to read pizza data")
			return
		}
		result = append(result, pizza)
	}
	if rows.Err() != nil {
		writeError(w, http.StatusInternalServerError, "Failed to load pizzas")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

// GetPizzaByID handles GET /api/pizzas/{id}
func (h *PizzaHandler) GetPizzaByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	// Extract ID from path: /api/pizzas/{id}
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/api/pizzas/"), "/")
	id := parts[0]

	if id == "" {
		writeError(w, http.StatusBadRequest, "Pizza id is required")
		return
	}

	row := h.db.QueryRow(r.Context(), `
		SELECT id, name, description, price, rating, calories, protein, fat,
		       carbs, ingredients, category, image_url, is_popular, is_recommended
		FROM pizzas WHERE id = $1`, id)
	pizza, err := scanPizza(row)
	if errors.Is(err, pgx.ErrNoRows) {
		writeError(w, http.StatusNotFound, "Pizza not found")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to load pizza")
		return
	}
	writeJSON(w, http.StatusOK, pizza)
}

// GetCategories handles GET /api/pizzas/categories
func (h *PizzaHandler) GetCategories(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	writeJSON(w, http.StatusOK, h.categories)
}

// GetIngredients handles GET /api/pizzas/ingredients
func (h *PizzaHandler) GetIngredients(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	writeJSON(w, http.StatusOK, h.ingredients)
}

type pizzaScanner interface {
	Scan(dest ...any) error
}

func scanPizza(scanner pizzaScanner) (models.Pizza, error) {
	var pizza models.Pizza
	var ingredientsJSON []byte
	err := scanner.Scan(
		&pizza.ID, &pizza.Name, &pizza.Description, &pizza.Price, &pizza.Rating,
		&pizza.Calories, &pizza.Protein, &pizza.Fat, &pizza.Carbs, &ingredientsJSON,
		&pizza.Category, &pizza.ImageURL, &pizza.IsPopular, &pizza.IsRecommended,
	)
	if err != nil {
		return pizza, err
	}
	if err := json.Unmarshal(ingredientsJSON, &pizza.Ingredients); err != nil {
		return pizza, err
	}
	return pizza, nil
}
