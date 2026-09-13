package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/joho/godotenv"

	"mario-backend/database"
	"mario-backend/handlers"
	"mario-backend/middleware"
)

// responseLogger wraps http.ResponseWriter to capture status code for logging.
type responseLogger struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseLogger) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// requestLoggingMiddleware logs all incoming HTTP requests with method, path, status, and duration.
func requestLoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		wrapped := &responseLogger{ResponseWriter: w, statusCode: http.StatusOK}
		next.ServeHTTP(wrapped, r)
		duration := time.Since(start)

		emoji := "🟢"
		if wrapped.statusCode >= 400 && wrapped.statusCode < 500 {
			emoji = "🟡"
		} else if wrapped.statusCode >= 500 {
			emoji = "🔴"
		}

		log.Printf("%s [%d] %-6s %s (%v)", emoji, wrapped.statusCode, r.Method, r.URL.Path, duration)
	})
}

// corsMiddleware adds CORS headers for Flutter app access.
func corsMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next(w, r)
	}
}

func main() {
	// Load backend/.env for local development. Existing system variables win.
	_ = godotenv.Load()

	if err := middleware.ConfigureJWTSecret(os.Getenv("JWT_SECRET")); err != nil {
		log.Fatal(err)
	}

	startupContext, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	db, err := database.Open(startupContext)
	if err != nil {
		log.Fatalf("Database connection failed: %v", err)
	}
	defer db.Close()
	if err := database.Migrate(startupContext, db); err != nil {
		log.Fatalf("Database migration failed: %v", err)
	}
	if err := database.Seed(startupContext, db); err != nil {
		log.Fatalf("Database seed failed: %v", err)
	}

	authHandler := handlers.NewAuthHandler(db)
	pizzaHandler := handlers.NewPizzaHandler(db)
	orderHandler := handlers.NewOrderHandler(db)

	// ──────────────────────────────────────────────────────────
	// ROUTES
	// ──────────────────────────────────────────────────────────

	mux := http.NewServeMux()

	// Auth routes (public)
	mux.HandleFunc("/api/auth/signup", corsMiddleware(authHandler.SignUp))
	mux.HandleFunc("/api/auth/signin", corsMiddleware(authHandler.SignIn))
	mux.HandleFunc("/api/auth/me", corsMiddleware(middleware.AuthMiddleware(authHandler.Me)))

	// Pizza routes (public — no auth required for browsing)
	mux.HandleFunc("/api/pizzas/categories", corsMiddleware(pizzaHandler.GetCategories))
	mux.HandleFunc("/api/pizzas/ingredients", corsMiddleware(pizzaHandler.GetIngredients))

	// Pizza routes — use a custom handler for path-based routing
	mux.HandleFunc("/api/pizzas/", corsMiddleware(func(w http.ResponseWriter, r *http.Request) {
		path := strings.TrimPrefix(r.URL.Path, "/api/pizzas/")
		if path == "" || path == "/" {
			pizzaHandler.GetPizzas(w, r)
			return
		}
		// /api/pizzas/{id}
		pizzaHandler.GetPizzaByID(w, r)
	}))
	mux.HandleFunc("/api/pizzas", corsMiddleware(pizzaHandler.GetPizzas))

	// Order routes (supports authenticated users + guest/demo fallback)
	mux.HandleFunc("/api/orders/", corsMiddleware(middleware.OptionalAuthMiddleware(func(w http.ResponseWriter, r *http.Request) {
		path := strings.TrimPrefix(r.URL.Path, "/api/orders/")
		if path == "" || path == "/" {
			if r.Method == http.MethodPost {
				orderHandler.PlaceOrder(w, r)
			} else {
				orderHandler.GetOrders(w, r)
			}
			return
		}
		orderHandler.GetOrderByID(w, r)
	})))
	mux.HandleFunc("/api/orders", corsMiddleware(middleware.OptionalAuthMiddleware(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost {
			orderHandler.PlaceOrder(w, r)
		} else {
			orderHandler.GetOrders(w, r)
		}
	})))

	// Health check
	mux.HandleFunc("/api/health", corsMiddleware(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, `{"error":"Method not allowed"}`, http.StatusMethodNotAllowed)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		pingContext, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()
		if err := db.Ping(pingContext); err != nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			fmt.Fprint(w, `{"status":"error","service":"mario-pizza-api","database":"unavailable"}`)
			return
		}
		fmt.Fprint(w, `{"status":"ok","service":"mario-pizza-api","database":"postgresql"}`)
	}))

	// ──────────────────────────────────────────────────────────
	// START SERVER
	// ──────────────────────────────────────────────────────────

	portNumber := strings.TrimSpace(os.Getenv("PORT"))
	if portNumber == "" {
		portNumber = "8080"
	}
	port := ":" + portNumber
	log.Printf("🍕 MARIO Pizza API running on http://localhost%s", port)
	log.Printf("📋 Endpoints:")
	log.Printf("   POST /api/auth/signup")
	log.Printf("   POST /api/auth/signin")
	log.Printf("   GET  /api/auth/me (auth required)")
	log.Printf("   GET  /api/pizzas")
	log.Printf("   GET  /api/pizzas/:id")
	log.Printf("   GET  /api/pizzas/categories")
	log.Printf("   GET  /api/pizzas/ingredients")
	log.Printf("   POST /api/orders (auth required)")
	log.Printf("   GET  /api/orders (auth required)")
	log.Printf("   GET  /api/orders/:id (auth required)")
	log.Printf("   GET  /api/health")

	log.Printf("🚀 Server ready! Listening for incoming requests...")

	server := &http.Server{
		Addr:              port,
		Handler:           requestLoggingMiddleware(mux),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
