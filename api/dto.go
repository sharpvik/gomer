package main

type Message[T any] struct {
	Type MessageType `json:"type"`
	Data T           `json:"data"`
}

type MessageType string

const (
	MessageTypeCodeUpdate MessageType = "codeUpdate"
	MessageTypeRunResult  MessageType = "runResult"
)

type CodeUpdateMessage struct {
	GoCode string `json:"goCode"`
}

type RunResultMessage struct {
	Output string `json:"output"`
}
