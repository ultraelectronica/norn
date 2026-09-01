package main

import (
	"net"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealthz(t *testing.T) {
	rec := httptest.NewRecorder()
	healthz(rec, httptest.NewRequest(http.MethodGet, "/healthz", nil))

	if rec.Code != http.StatusOK {
		t.Fatalf("healthz = %d, want %d", rec.Code, http.StatusOK)
	}
	if rec.Body.String() != "ok" {
		t.Fatalf("healthz body = %q, want %q", rec.Body.String(), "ok")
	}
}

func TestReadyzNoDatabaseConfigured(t *testing.T) {
	rec := httptest.NewRecorder()
	readyz("")(rec, httptest.NewRequest(http.MethodGet, "/readyz", nil))

	if rec.Code != http.StatusOK {
		t.Fatalf("readyz (no db) = %d, want %d", rec.Code, http.StatusOK)
	}
}

func TestReadyzDatabaseReachable(t *testing.T) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer ln.Close()
	go func() {
		for {
			c, err := ln.Accept()
			if err != nil {
				return
			}
			c.Close()
		}
	}()

	rec := httptest.NewRecorder()
	readyz("postgres://norn:norn@"+ln.Addr().String()+"/norn?sslmode=disable")(
		rec, httptest.NewRequest(http.MethodGet, "/readyz", nil))

	if rec.Code != http.StatusOK {
		t.Fatalf("readyz (db up) = %d, want %d", rec.Code, http.StatusOK)
	}
}

func TestReadyzDatabaseUnreachable(t *testing.T) {
	// Bind then close to guarantee a dead port.
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	deadAddr := ln.Addr().String()
	ln.Close()

	rec := httptest.NewRecorder()
	readyz("postgres://norn:norn@"+deadAddr+"/norn?sslmode=disable")(
		rec, httptest.NewRequest(http.MethodGet, "/readyz", nil))

	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("readyz (db down) = %d, want %d", rec.Code, http.StatusServiceUnavailable)
	}
}
