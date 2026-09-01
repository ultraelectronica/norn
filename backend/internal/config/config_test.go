package config

import "testing"

func TestEnvFallback(t *testing.T) {
	t.Setenv("HTTP_PORT", "")
	if got := env("HTTP_PORT", "8080"); got != "8080" {
		t.Fatalf("expected fallback 8080, got %s", got)
	}
	t.Setenv("HTTP_PORT", "9090")
	if got := env("HTTP_PORT", "8080"); got != "9090" {
		t.Fatalf("expected override 9090, got %s", got)
	}
}

func TestLoadDefaults(t *testing.T) {
	t.Setenv("HTTP_PORT", "")
	if cfg := Load(); cfg.HTTPPort != "8080" {
		t.Fatalf("expected default port 8080, got %s", cfg.HTTPPort)
	}
}
