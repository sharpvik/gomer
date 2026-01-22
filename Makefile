.PHONY: dev prod serve image up down

# Build the Elm project
dev:
	elm make src/Main.elm --output=dist/js/elm.js

# Build optimized production version
prod:
	elm make src/Main.elm --output=dist/js/elm.js --optimize

# Run the API and the file server
serve: dev
	go run ./api

# Build the Docker image
image:
	docker compose build

# Run the Docker container
up:
	docker compose up -d --build

# Stop the Docker container
down:
	docker compose down
