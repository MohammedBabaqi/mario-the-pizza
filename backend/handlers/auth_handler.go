package handlers

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"

	"mario-backend/middleware"
	"mario-backend/models"
)

// AuthHandler manages user registration and authentication.
type AuthHandler struct {
	mu    sync.RWMutex
	users map[string]models.User // keyed by email
}

// NewAuthHandler creates a new AuthHandler.
func NewAuthHandler() *AuthHandler {
	h := &AuthHandler{
		users: make(map[string]models.User),
	}
	// Seed demo users for instant login testing
	h.users["mario@pizza.com"] = models.User{
		UID:          "user_demo_mario",
		Email:        "mario@pizza.com",
		DisplayName:  "Mario Rossi",
		CreatedAt:    time.Now(),
		PasswordHash: hashPassword("pizza123"),
	}
	h.users["m@gmail.com"] = models.User{
		UID:          "user_m",
		Email:        "m@gmail.com",
		DisplayName:  "Mohammed Babaqi",
		CreatedAt:    time.Now(),
		PasswordHash: hashPassword("123456"),
	}
	h.users["user@example.com"] = models.User{
		UID:          "user_2",
		Email:        "user@example.com",
		DisplayName:  "Mohammed Babaqi",
		CreatedAt:    time.Now(),
		PasswordHash: hashPassword("123456"),
	}
	h.users["demo@mario.com"] = models.User{
		UID:          "user_1",
		Email:        "demo@mario.com",
		DisplayName:  "Mario Chef",
		CreatedAt:    time.Now(),
		PasswordHash: hashPassword("123456"),
	}
	return h
}

func hashPassword(password string) string {
	h := sha256.Sum256([]byte(password))
	return hex.EncodeToString(h[:])
}

// SignUp handles POST /api/auth/signup
func (h *AuthHandler) SignUp(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, `{"error":"Method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	var req models.SignUpRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error":"Invalid request body"}`, http.StatusBadRequest)
		return
	}

	if req.Email == "" || req.Password == "" || req.Name == "" {
		http.Error(w, `{"error":"Email, password, and name are required"}`, http.StatusBadRequest)
		return
	}

	if len(req.Password) < 6 {
		http.Error(w, `{"error":"Password must be at least 6 characters"}`, http.StatusBadRequest)
		return
	}

	h.mu.Lock()
	defer h.mu.Unlock()

	if _, exists := h.users[req.Email]; exists {
		http.Error(w, `{"error":"Email already registered"}`, http.StatusConflict)
		return
	}

	uid := fmt.Sprintf("user_%d", time.Now().UnixNano())
	user := models.User{
		UID:          uid,
		Email:        req.Email,
		DisplayName:  req.Name,
		CreatedAt:    time.Now(),
		PasswordHash: hashPassword(req.Password),
	}
	h.users[req.Email] = user

	token, err := middleware.GenerateToken(uid)
	if err != nil {
		http.Error(w, `{"error":"Failed to generate token"}`, http.StatusInternalServerError)
		return
	}

	resp := models.AuthResponse{
		Token: token,
		User:  user,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(resp)
}

// SignIn handles POST /api/auth/signin
func (h *AuthHandler) SignIn(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, `{"error":"Method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	var req models.SignInRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error":"Invalid request body"}`, http.StatusBadRequest)
		return
	}

	h.mu.RLock()
	user, exists := h.users[req.Email]
	h.mu.RUnlock()

	if !exists || user.PasswordHash != hashPassword(req.Password) {
		http.Error(w, `{"error":"Invalid email or password"}`, http.StatusUnauthorized)
		return
	}

	token, err := middleware.GenerateToken(user.UID)
	if err != nil {
		http.Error(w, `{"error":"Failed to generate token"}`, http.StatusInternalServerError)
		return
	}

	resp := models.AuthResponse{
		Token: token,
		User:  user,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// Me handles GET /api/auth/me (requires auth middleware)
func (h *AuthHandler) Me(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, `{"error":"Method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	userID := r.Context().Value(middleware.UserIDKey).(string)

	h.mu.RLock()
	defer h.mu.RUnlock()

	for _, user := range h.users {
		if user.UID == userID {
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(user)
			return
		}
	}

	http.Error(w, `{"error":"User not found"}`, http.StatusNotFound)
}
