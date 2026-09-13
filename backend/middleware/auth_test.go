package middleware

import "testing"

func TestTokenRoundTripAndTamperDetection(t *testing.T) {
	if err := ConfigureJWTSecret("test-secret-that-is-at-least-32-characters-long"); err != nil {
		t.Fatal(err)
	}
	token, err := GenerateToken("user_123")
	if err != nil {
		t.Fatal(err)
	}
	userID, err := ParseAndVerifyToken(token)
	if err != nil || userID != "user_123" {
		t.Fatalf("unexpected token result: user=%q error=%v", userID, err)
	}
	if _, err := ParseAndVerifyToken(token + "changed"); err == nil {
		t.Fatal("tampered token was accepted")
	}
}

func TestConfigureJWTSecretRejectsShortSecret(t *testing.T) {
	if err := ConfigureJWTSecret("too-short"); err == nil {
		t.Fatal("short JWT secret was accepted")
	}
}
