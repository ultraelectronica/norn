// Package config reads runtime configuration from the environment.
// Phase 0: lenient (health works without a DB). Required-field validation
// tightens as repository/auth layers wire in.
package config

import "os"

type Config struct {
	HTTPPort    string
	DatabaseURL string // Postgres
	RedisURL    string // cache + rate-limit counters
	KMSKeyID    string // BYOK key envelope encryption
	JWKSURL     string // Cognito JWKS for JWT validation
}

func Load() *Config {
	return &Config{
		HTTPPort:    env("HTTP_PORT", "8080"),
		DatabaseURL: os.Getenv("DATABASE_URL"),
		RedisURL:    os.Getenv("REDIS_URL"),
		KMSKeyID:    os.Getenv("KMS_KEY_ID"),
		JWKSURL:     os.Getenv("JWKS_URL"),
	}
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
