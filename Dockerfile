# Stage 1: Build Elm application
FROM node:20-alpine AS elm-builder

# Install Elm 0.19.1 directly from GitHub releases
RUN apk add --no-cache curl && \
    curl -L -o elm.gz https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz && \
    gunzip elm.gz && \
    chmod +x elm && \
    mv elm /usr/local/bin/elm

WORKDIR /build

# Copy Elm project files
COPY elm.json ./
COPY src ./src

# Copy existing dist files (HTML, CSS, favicon, init.js) to preserve them
COPY dist ./dist

# Build optimized Elm application (this will create/overwrite dist/js/elm.js)
RUN elm make src/Main.elm --output=dist/js/elm.js --optimize

# Stage 2: Build Go binary
FROM golang:1.24-alpine AS go-builder

WORKDIR /build

# Copy Go module files
COPY go.mod go.sum ./

# Copy the dist directory from Elm builder
COPY --from=elm-builder /build/dist ./dist

# Download dependencies
RUN go mod download

# Copy API source code
COPY api ./api

# Build the Go binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gomer ./api

# Start the binary
CMD ["./gomer"]
