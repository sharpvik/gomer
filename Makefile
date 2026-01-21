.PHONY: dev prod api

# Build the Elm project
dev:
	elm make src/Main.elm --output=dist/js/elm.js

# Build optimized production version
prod:
	elm make src/Main.elm --output=dist/js/elm.js --optimize

# Run the API and the file server
api:
	go run ./api
