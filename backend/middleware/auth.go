package middleware

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
)

// JWTSecret is the signing key for JWT tokens.
var JWTSecret = []byte("mario-pizza-secret-key-2024")

// contextKey is a custom type for context keys to avoid collisions.
type contextKey string

const UserIDKey contextKey = "userId"

type jwtHeader struct {
	Alg string `json:"alg"`
	Typ string `json:"typ"`
}

type jwtClaims struct {
	UID string `json:"uid"`
}

func base64UrlEncode(data []byte) string {
	return base64.RawURLEncoding.EncodeToString(data)
}

func base64UrlDecode(data string) ([]byte, error) {
	return base64.RawURLEncoding.DecodeString(data)
}

// GenerateToken creates a signed JWT using standard library crypto/hmac and crypto/sha256.
// Pure standard library — requires no external github dependencies!
func GenerateToken(userID string) (string, error) {
	headerBytes, _ := json.Marshal(jwtHeader{Alg: "HS256", Typ: "JWT"})
	headerEncoded := base64UrlEncode(headerBytes)

	claimsBytes, err := json.Marshal(jwtClaims{UID: userID})
	if err != nil {
		return "", err
	}
	claimsEncoded := base64UrlEncode(claimsBytes)

	unsignedToken := headerEncoded + "." + claimsEncoded

	h := hmac.New(sha256.New, JWTSecret)
	h.Write([]byte(unsignedToken))
	signature := base64UrlEncode(h.Sum(nil))

	return unsignedToken + "." + signature, nil
}

// ParseAndVerifyToken verifies the HMAC signature and returns the user ID.
func ParseAndVerifyToken(tokenStr string) (string, error) {
	parts := strings.Split(tokenStr, ".")
	if len(parts) != 3 {
		return "", errors.New("invalid token format")
	}

	unsignedToken := parts[0] + "." + parts[1]
	h := hmac.New(sha256.New, JWTSecret)
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

	return claims.UID, nil
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

// OptionalAuthMiddleware validates JWT token if present, but falls back to demo user if absent or invalid.
func OptionalAuthMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		userID := "user_demo_mario"

		if authHeader != "" {
			parts := strings.Split(authHeader, " ")
			if len(parts) == 2 && parts[0] == "Bearer" {
				if uid, err := ParseAndVerifyToken(parts[1]); err == nil && uid != "" {
					userID = uid
				}
			}
		}

		ctx := context.WithValue(r.Context(), UserIDKey, userID)
		next.ServeHTTP(w, r.WithContext(ctx))
	}
}

