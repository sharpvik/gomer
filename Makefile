.PHONY: dev prod api image up down

# Build the Elm project
dev:
	elm make src/Main.elm --output=dist/js/elm.js

# Build optimized production version
prod:
	elm make src/Main.elm --output=dist/js/elm.js --optimize

# Run the API and the file server
api:
	go run ./api

image:
	docker compose build

up:
	docker compose up -d --build

down:
	docker compose down
