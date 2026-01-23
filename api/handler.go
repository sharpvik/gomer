package main

import (
	"bytes"
	"context"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"sync"
	"time"

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
	mux.HandleFunc("/format", h.FormatGoCode)
	mux.Handle("/", http.FileServer(http.Dir("dist")))
	return mux
}

func (h *Handler) RunGoCode(w http.ResponseWriter, r *http.Request) {
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
	if err := os.WriteFile(mainGoPath, goCode, 0644); err != nil {
		log.Printf("error writing main.go: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if err := Command(dirName, "go", "mod", "init", "gomer").Run(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if err := Command(dirName, "go", "mod", "tidy").Run(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var buf bytes.Buffer
	ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
	defer cancel()

	if err := CommandContext(ctx, dirName, "go", "run", ".").Pipe(&buf).Run(); err != nil {
		if ctx.Err() == context.DeadlineExceeded {
			h.broadcastRunResult("Program took more than 10 seconds to run. Time's up.")
			w.WriteHeader(http.StatusNoContent)
			return
		}
	}

	h.broadcastRunResult(buf.String())
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) FormatGoCode(w http.ResponseWriter, r *http.Request) {
	goCode, err := io.ReadAll(r.Body)
	if err != nil {
		log.Printf("error reading go code: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	dirName, err := os.MkdirTemp("", "gomer-format-")
	if err != nil {
		log.Printf("error creating temp directory: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer os.RemoveAll(dirName)

	mainGoPath := filepath.Join(dirName, "main.go")
	if err := os.WriteFile(mainGoPath, goCode, 0644); err != nil {
		log.Printf("error writing main.go: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var buf bytes.Buffer
	if err := Command(dirName, "gofmt", mainGoPath).Pipe(&buf).Run(); err != nil {
		h.broadcastRunResult(buf.String())
		w.WriteHeader(http.StatusNoContent)
		return
	}

	h.updateGoCode(buf.String())
	h.broadcastGoCode(nil)
	h.broadcastRunResult("Code formatted successfully")
	w.WriteHeader(http.StatusNoContent)
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
			h.broadcastGoCode(conn)
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

	msg := Message[CodeUpdateMessage]{
		Type: MessageTypeCodeUpdate,
		Data: CodeUpdateMessage{
			GoCode: h.goCode,
		},
	}

	return wsjson.Write(context.Background(), conn, msg)
}

func (h *Handler) broadcastGoCode(except *websocket.Conn) {
	h.RLock()
	defer h.RUnlock()
	var eg errgroup.Group

	for conn := range h.clients {
		if conn == except {
			continue
		}
		eg.Go(func() error {
			return h.sendGoCodeTo(conn)
		})
	}

	if err := eg.Wait(); err != nil {
		log.Printf("error broadcasting go code: %v", err)
	}
}

func (h *Handler) sendRunResultTo(conn *websocket.Conn, output string) error {
	h.RLock()
	defer h.RUnlock()

	msg := Message[RunResultMessage]{
		Type: MessageTypeRunResult,
		Data: RunResultMessage{
			Output: output,
		},
	}

	return wsjson.Write(context.Background(), conn, msg)
}

func (h *Handler) broadcastRunResult(output string) {
	h.RLock()
	defer h.RUnlock()
	var eg errgroup.Group

	for conn := range h.clients {
		eg.Go(func() error {
			return h.sendRunResultTo(conn, output)
		})
	}

	if err := eg.Wait(); err != nil {
		log.Printf("error broadcasting run result: %v", err)
	}
}
