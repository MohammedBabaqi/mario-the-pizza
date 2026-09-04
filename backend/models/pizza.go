package models

// Pizza represents a pizza menu item.
type Pizza struct {
	ID            string   `json:"id"`
	Name          string   `json:"name"`
	Description   string   `json:"description"`
	Price         float64  `json:"price"`
	Rating        float64  `json:"rating"`
	Calories      int      `json:"calories"`
	Protein       int      `json:"protein"`
	Fat           int      `json:"fat"`
	Carbs         int      `json:"carbs"`
	Ingredients   []string `json:"ingredients"`
	Category      string   `json:"category"`
	ImageURL      string   `json:"imageUrl"`
	IsPopular     bool     `json:"isPopular"`
	IsRecommended bool     `json:"isRecommended"`
}

// Category represents a pizza category.
type Category struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	Emoji     string `json:"emoji"`
	SortOrder int    `json:"sortOrder"`
}

// Ingredient represents a customization ingredient.
type Ingredient struct {
	ID               string  `json:"id"`
	Name             string  `json:"name"`
	Type             string  `json:"type"`
	PriceModifier    float64 `json:"priceModifier"`
	CalorieModifier  int     `json:"calorieModifier"`
	Emoji            string  `json:"emoji"`
}
