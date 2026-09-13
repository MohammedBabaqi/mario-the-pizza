package middleware

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"
)

var (
	jwtSecret   []byte
	secretMutex sync.RWMutex
)

// contextKey is a custom type for context keys to avoid collisions.
type contextKey string

const UserIDKey contextKey = "userId"

type jwtHeader struct {
	Alg string `json:"alg"`
	Typ string `json:"typ"`
}

type jwtClaims struct {
	UID       string `json:"uid"`
	IssuedAt  int64  `json:"iat"`
	ExpiresAt int64  `json:"exp"`
}

// ConfigureJWTSecret sets the signing key loaded by main from the environment.
func ConfigureJWTSecret(secret string) error {
	if len(secret) < 32 {
		return fmt.Errorf("JWT_SECRET must contain at least 32 characters")
	}
	secretMutex.Lock()
	jwtSecret = []byte(secret)
	secretMutex.Unlock()
	return nil
}

func currentSecret() ([]byte, error) {
	secretMutex.RLock()
	defer secretMutex.RUnlock()
	if len(jwtSecret) == 0 {
		return nil, errors.New("JWT secret is not configured")
	}
	return append([]byte(nil), jwtSecret...), nil
}

func base64UrlEncode(data []byte) string {
	return base64.RawURLEncoding.EncodeToString(data)
}

func base64UrlDecode(data string) ([]byte, error) {
	return base64.RawURLEncoding.DecodeString(data)
}

// GenerateToken creates a signed JWT that expires after 24 hours.
func GenerateToken(userID string) (string, error) {
	secret, err := currentSecret()
	if err != nil {
		return "", err
	}
	headerBytes, _ := json.Marshal(jwtHeader{Alg: "HS256", Typ: "JWT"})
	headerEncoded := base64UrlEncode(headerBytes)

	now := time.Now().Unix()
	claimsBytes, err := json.Marshal(jwtClaims{
		UID: userID, IssuedAt: now, ExpiresAt: now + int64((24 * time.Hour).Seconds()),
	})
	if err != nil {
		return "", err
	}
	claimsEncoded := base64UrlEncode(claimsBytes)

	unsignedToken := headerEncoded + "." + claimsEncoded

	h := hmac.New(sha256.New, secret)
	h.Write([]byte(unsignedToken))
	signature := base64UrlEncode(h.Sum(nil))

	return unsignedToken + "." + signature, nil
}

// ParseAndVerifyToken verifies the HMAC signature and returns the user ID.
func ParseAndVerifyToken(tokenStr string) (string, error) {
	secret, err := currentSecret()
	if err != nil {
		return "", err
	}
	parts := strings.Split(tokenStr, ".")
	if len(parts) != 3 {
		return "", errors.New("invalid token format")
	}

	unsignedToken := parts[0] + "." + parts[1]
	h := hmac.New(sha256.New, secret)
	h.Write([]byte(unsignedToken))
	expectedSignature := base64UrlEncode(h.Sum(nil))

	if !hmac.Equal([]byte(parts[2]), []byte(expectedSignature)) {
		return "", errors.New("invalid token signature")
	}

	claimsBytes, err := base64UrlDecode(parts[1])
	if err != nil {
		return "", errors.New("cannot decode claims")
	}

	var claims jwtClaims
	if err := json.Unmarshal(claimsBytes, &claims); err != nil {
		return "", errors.New("cannot parse claims")
	}

	if claims.UID == "" {
		return "", errors.New("missing user id in token")
	}
	if claims.ExpiresAt <= time.Now().Unix() {
		return "", errors.New("token expired")
	}

	return claims.UID, nil
}

// UserIDFromContext safely reads the authenticated user id.
func UserIDFromContext(ctx context.Context) (string, bool) {
	userID, ok := ctx.Value(UserIDKey).(string)
	return userID, ok && userID != ""
}

// AuthMiddleware validates the JWT token in the Authorization header.
func AuthMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, `{"error":"Missing authorization header"}`, http.StatusUnauthorized)
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			http.Error(w, `{"error":"Invalid authorization format"}`, http.StatusUnauthorized)
			return
		}

		userID, err := ParseAndVerifyToken(parts[1])
		if err != nil {
			http.Error(w, `{"error":"Invalid or expired token"}`, http.StatusUnauthorized)
			return
		}

		// Add user ID to request context
		ctx := context.WithValue(r.Context(), UserIDKey, userID)
		next.ServeHTTP(w, r.WithContext(ctx))
	}
}

// OptionalAuthMiddleware permits an anonymous guest, but rejects invalid supplied tokens.
func OptionalAuthMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		userID := "guest"

		if authHeader != "" {
			parts := strings.Split(authHeader, " ")
			if len(parts) != 2 || parts[0] != "Bearer" {
				http.Error(w, `{"error":"Invalid authorization format"}`, http.StatusUnauthorized)
				return
			}
			uid, err := ParseAndVerifyToken(parts[1])
			if err != nil {
				http.Error(w, `{"error":"Invalid or expired token"}`, http.StatusUnauthorized)
				return
			}
			userID = uid
		}

		ctx := context.WithValue(r.Context(), UserIDKey, userID)
		next.ServeHTTP(w, r.WithContext(ctx))
	}
}
