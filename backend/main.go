package main

import (
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

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
	// Initialize handlers
	authHandler := handlers.NewAuthHandler()
	pizzaHandler := handlers.NewPizzaHandler()
	orderHandler := handlers.NewOrderHandler()

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
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status":"ok","service":"mario-pizza-api"}`)
	}))

	// ──────────────────────────────────────────────────────────
	// START SERVER
	// ──────────────────────────────────────────────────────────

	port := ":8080"
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

	loggedMux := requestLoggingMiddleware(mux)
	if err := http.ListenAndServe(port, loggedMux); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
