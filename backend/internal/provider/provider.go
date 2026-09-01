// Package provider abstracts model backends. OpenRouter is the default; one
// OpenAI-compatible adapter covers both BYOK providers and offline servers
// (Ollama, vLLM). New providers are new implementations (Open-Closed).
package provider

import "context"

type Role string

const (
	RoleSystem    Role = "system"
	RoleUser      Role = "user"
	RoleAssistant Role = "assistant"
)

type Message struct {
	Role    Role   `json:"role"`
	Content string `json:"content"`
}

type ChatRequest struct {
	Model    string    `json:"model"`
	Messages []Message `json:"messages"`
}

// Chunk is one streamed token delta. Done=true marks stream completion.
type Chunk struct {
	Delta string `json:"delta"`
	Done  bool   `json:"done"`
}

type Model struct {
	ID            string `json:"id"`
	Name          string `json:"name"`
	ContextWindow int    `json:"context_window"`
	IsFree        bool   `json:"is_free"`
}

type ChatProvider interface {
	Models(ctx context.Context) ([]Model, error)
	Stream(ctx context.Context, req ChatRequest) (<-chan Chunk, error)
}
