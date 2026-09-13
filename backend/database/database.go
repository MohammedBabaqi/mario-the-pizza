package database

import (
	"context"
	_ "embed"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"

	"mario-backend/data"
)

//go:embed schema.sql
var schema string

// Open creates and verifies the PostgreSQL connection pool.
func Open(ctx context.Context) (*pgxpool.Pool, error) {
	databaseURL := strings.TrimSpace(os.Getenv("DATABASE_URL"))
	if databaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL is not set")
	}

	config, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		return nil, fmt.Errorf("parse DATABASE_URL: %w", err)
	}
	config.MaxConns = 10
	config.MinConns = 1
	config.MaxConnLifetime = time.Hour

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, fmt.Errorf("create PostgreSQL pool: %w", err)
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("connect to PostgreSQL: %w", err)
	}
	return pool, nil
}

// Migrate creates the tables and indexes required by the API.
func Migrate(ctx context.Context, pool *pgxpool.Pool) error {
	if _, err := pool.Exec(ctx, schema); err != nil {
		return fmt.Errorf("apply database schema: %w", err)
	}
	return nil
}

// Seed inserts the initial menu and demo accounts without overwriting later edits.
func Seed(ctx context.Context, pool *pgxpool.Pool) error {
	demoUsers := []struct {
		uid, email, name, password string
	}{
		{"guest", "guest@mario.local", "Guest", "disabled-login"},
		{"user_demo_mario", "mario@pizza.com", "Mario Rossi", "pizza123"},
		{"user_m", "m@gmail.com", "Mohammed Babaqi", "123456"},
		{"user_2", "user@example.com", "Mohammed Babaqi", "123456"},
		{"user_1", "demo@mario.com", "Mario Chef", "123456"},
	}

	for _, user := range demoUsers {
		hash, err := bcrypt.GenerateFromPassword([]byte(user.password), bcrypt.DefaultCost)
		if err != nil {
			return fmt.Errorf("hash demo password: %w", err)
		}
		_, err = pool.Exec(ctx, `
			INSERT INTO users (uid, email, display_name, password_hash)
			VALUES ($1, $2, $3, $4)
			ON CONFLICT DO NOTHING`, user.uid, user.email, user.name, string(hash))
		if err != nil {
			return fmt.Errorf("seed user %s: %w", user.email, err)
		}
	}

	for _, pizza := range data.SeedPizzas() {
		ingredients, err := json.Marshal(pizza.Ingredients)
		if err != nil {
			return fmt.Errorf("encode ingredients for %s: %w", pizza.ID, err)
		}
		_, err = pool.Exec(ctx, `
			INSERT INTO pizzas (
				id, name, description, price, rating, calories, protein, fat, carbs,
				ingredients, category, image_url, is_popular, is_recommended
			) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
			ON CONFLICT (id) DO NOTHING`,
			pizza.ID, pizza.Name, pizza.Description, pizza.Price, pizza.Rating,
			pizza.Calories, pizza.Protein, pizza.Fat, pizza.Carbs, ingredients,
			pizza.Category, pizza.ImageURL, pizza.IsPopular, pizza.IsRecommended,
		)
		if err != nil {
			return fmt.Errorf("seed pizza %s: %w", pizza.ID, err)
		}
	}
	return nil
}
