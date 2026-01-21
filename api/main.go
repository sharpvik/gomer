package main

import (
	"log"
	"net/http"
)

const addr = "0.0.0.0:8080"

func main() {
	log.Println("Starting server at http://" + addr)
	handler := NewHandler()
	mux := handler.Mux()
	http.ListenAndServe(addr, mux)
}
