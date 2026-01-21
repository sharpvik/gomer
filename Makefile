.PHONY: dev prod serve

# Build the Elm project
dev:
	elm make src/Main.elm --output=dist/js/elm.js

# Build optimized production version
prod:
	elm make src/Main.elm --output=dist/js/elm.js --optimize

# Serve the development version for local development and testing
serve: dev
	serve -d dist
