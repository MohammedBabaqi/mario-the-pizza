package models

import "time"

// User represents an authenticated user.
type User struct {
	UID          string    `json:"uid"`
	Email        string    `json:"email"`
	DisplayName  string    `json:"displayName"`
	PhotoURL     string    `json:"photoUrl,omitempty"`
	CreatedAt    time.Time `json:"createdAt"`
	PhoneNumber  string    `json:"phoneNumber,omitempty"`
	Address      string    `json:"defaultAddress,omitempty"`
	PasswordHash string    `json:"-"` // never sent to client
}

// SignUpRequest is the payload for user registration.
type SignUpRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
	Name     string `json:"name"`
}

// SignInRequest is the payload for user login.
type SignInRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// AuthResponse is returned after successful auth.
type AuthResponse struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}
