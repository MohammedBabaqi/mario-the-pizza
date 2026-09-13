package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"net/http"
	"net/mail"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"

	"mario-backend/middleware"
	"mario-backend/models"
)

type AuthHandler struct {
	db *pgxpool.Pool
}

func NewAuthHandler(db *pgxpool.Pool) *AuthHandler {
	return &AuthHandler{db: db}
}

func (h *AuthHandler) SignUp(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req models.SignUpRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	req.Email = strings.ToLower(strings.TrimSpace(req.Email))
	req.Name = strings.TrimSpace(req.Name)
	address, err := mail.ParseAddress(req.Email)
	if err != nil || !strings.EqualFold(address.Address, req.Email) {
		writeError(w, http.StatusBadRequest, "A valid email is required")
		return
	}
	if req.Name == "" || len(req.Name) > 100 {
		writeError(w, http.StatusBadRequest, "Name is required and must be at most 100 characters")
		return
	}
	if len(req.Password) < 6 || len(req.Password) > 72 {
		writeError(w, http.StatusBadRequest, "Password must be between 6 and 72 characters")
		return
	}

	passwordHash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to secure password")
		return
	}
	uid, err := randomID("user_")
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to create user")
		return
	}

	user := models.User{UID: uid, Email: req.Email, DisplayName: req.Name}
	err = h.db.QueryRow(r.Context(), `
		INSERT INTO users (uid, email, display_name, password_hash)
		VALUES ($1, $2, $3, $4)
		RETURNING created_at`, uid, req.Email, req.Name, string(passwordHash)).Scan(&user.CreatedAt)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == "23505" {
			writeError(w, http.StatusConflict, "Email already registered")
			return
		}
		writeError(w, http.StatusInternalServerError, "Failed to create user")
		return
	}

	token, err := middleware.GenerateToken(uid)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to generate token")
		return
	}
	writeJSON(w, http.StatusCreated, models.AuthResponse{Token: token, User: user})
}

func (h *AuthHandler) SignIn(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req models.SignInRequest
	if err := decodeJSON(w, r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	email := strings.ToLower(strings.TrimSpace(req.Email))
	var user models.User
	err := h.db.QueryRow(r.Context(), `
		SELECT uid, email, display_name, photo_url, created_at, phone_number,
		       default_address, password_hash
		FROM users WHERE LOWER(email) = $1`, email).Scan(
		&user.UID, &user.Email, &user.DisplayName, &user.PhotoURL, &user.CreatedAt,
		&user.PhoneNumber, &user.Address, &user.PasswordHash,
	)
	if err != nil || bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)) != nil {
		writeError(w, http.StatusUnauthorized, "Invalid email or password")
		return
	}

	token, err := middleware.GenerateToken(user.UID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to generate token")
		return
	}
	writeJSON(w, http.StatusOK, models.AuthResponse{Token: token, User: user})
}

func (h *AuthHandler) Me(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var user models.User
	err := h.db.QueryRow(r.Context(), `
		SELECT uid, email, display_name, photo_url, created_at, phone_number,
		       default_address, password_hash
		FROM users WHERE uid = $1`, userID).Scan(
		&user.UID, &user.Email, &user.DisplayName, &user.PhotoURL, &user.CreatedAt,
		&user.PhoneNumber, &user.Address, &user.PasswordHash,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		writeError(w, http.StatusNotFound, "User not found")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to load user")
		return
	}
	writeJSON(w, http.StatusOK, user)
}

func randomID(prefix string) (string, error) {
	bytes := make([]byte, 12)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return prefix + hex.EncodeToString(bytes), nil
}
