.PHONY: build build-prod help

# Build the Elm project
dev:
	elm make src/Main.elm --output=dist/js/elm.js

# Build optimized production version
prod:
	elm make src/Main.elm --output=dist/js/elm.js --optimize

serve: dev
	serve -d dist

# Show help message
help:
	@echo "Available targets:"
	@echo "  build      - Compile Elm project to elm.js"
	@echo "  build-prod - Build optimized production version"
	@echo "  help       - Show this help message"
