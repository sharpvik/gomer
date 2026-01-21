package main

import (
	"context"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"sync"

	"github.com/coder/websocket"
	"github.com/coder/websocket/wsjson"
	"golang.org/x/sync/errgroup"
)

type Handler struct {
	sync.RWMutex
	clients map[*websocket.Conn]struct{}
	goCode  string // the current state of the Go code
}

func NewHandler() *Handler {
	return &Handler{
		clients: make(map[*websocket.Conn]struct{}),
		goCode:  InitialGoCode,
	}
}

func (h *Handler) Mux() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("/conn", h.HandleNewWebSocketConnection)
	mux.HandleFunc("/run", h.RunGoCode)
	return mux
}

func (h *Handler) RunGoCode(w http.ResponseWriter, r *http.Request) {
	// fix cors shit
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	goCode, err := io.ReadAll(r.Body)
	if err != nil {
		log.Printf("error reading go code: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	dirName, err := os.MkdirTemp("", "gomer-run-")
	if err != nil {
		log.Printf("error creating temp directory: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer os.RemoveAll(dirName)

	mainGoPath := filepath.Join(dirName, "main.go")
	os.WriteFile(mainGoPath, goCode, 0644)

	cmd := exec.Command("go", "mod", "init", "gomer")
	cmd.Dir = dirName
	if err := cmd.Run(); err != nil {
		log.Printf("error running go mod init: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	cmd = exec.Command("go", "mod", "tidy")
	cmd.Dir = dirName
	if err := cmd.Run(); err != nil {
		log.Printf("error running go mod tidy: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	cmd = exec.Command("go", "run", ".")
	cmd.Dir = dirName
	cmd.Stdout = w
	cmd.Stderr = w
	if err := cmd.Run(); err != nil {
		log.Printf("error running go run: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func (h *Handler) HandleNewWebSocketConnection(w http.ResponseWriter, r *http.Request) {
	conn, err := websocket.Accept(w, r, &websocket.AcceptOptions{
		InsecureSkipVerify: true,
	})
	if err != nil {
		log.Printf("error accepting websocket connection: %v", err)
		http.Error(w, err.Error(), http.StatusNotAcceptable)
		return
	}
	defer conn.CloseNow()

	h.addClientConnection(conn)
	defer h.removeClientConnection(conn)

	if err := h.sendGoCodeTo(conn); err != nil {
		log.Printf("error sending go code to client: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}

	for ctx := r.Context(); ; {
		select {
		case <-ctx.Done():
			return
		default:
			var msg CodeUpdateMessage
			if err := wsjson.Read(ctx, conn, &msg); err != nil {
				return
			}
			h.updateGoCode(msg.GoCode)
			h.broadcastGoCode()
		}
	}
}

func (h *Handler) addClientConnection(conn *websocket.Conn) {
	h.Lock()
	defer h.Unlock()
	h.clients[conn] = struct{}{}
}

func (h *Handler) removeClientConnection(conn *websocket.Conn) {
	h.Lock()
	defer h.Unlock()
	delete(h.clients, conn)
}

func (h *Handler) updateGoCode(newCodeState string) {
	h.Lock()
	defer h.Unlock()
	h.goCode = newCodeState
}

func (h *Handler) sendGoCodeTo(conn *websocket.Conn) error {
	h.RLock()
	defer h.RUnlock()
	return wsjson.Write(context.Background(), conn, CodeUpdateMessage{
		GoCode: h.goCode,
	})
}

func (h *Handler) broadcastGoCode() {
	h.RLock()
	defer h.RUnlock()
	var eg errgroup.Group

	for conn := range h.clients {
		eg.Go(func() error {
			return h.sendGoCodeTo(conn)
		})
	}

	if err := eg.Wait(); err != nil {
		log.Printf("error broadcasting go code: %v", err)
	}
}
