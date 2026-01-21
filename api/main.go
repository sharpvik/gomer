package main

import (
	"log"
	"net/http"
)

func main() {
	log.Println("Starting server on port 8080")
	handler := NewHandler()
	mux := handler.Mux()
	http.ListenAndServe(":8080", mux)
}
