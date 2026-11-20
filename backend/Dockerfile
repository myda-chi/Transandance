# ---- Stage 1: build (has the Go compiler) ----
FROM golang:1.27-alpine AS build
WORKDIR /src

# Download dependencies first, so Docker can reuse this step when only code changes
COPY backend/go.mod backend/go.sum ./
RUN go mod download

# Copy the code and compile the chosen service into one program file
COPY backend/ ./
ARG SERVICE
RUN CGO_ENABLED=0 go build -o /out/service ./cmd/${SERVICE}

# ---- Stage 2: run (tiny image, no compiler, no source code) ----
FROM alpine:3.24
RUN adduser -D -u 10001 app
COPY --from=build /out/service /usr/local/bin/service
USER app
ENTRYPOINT ["/usr/local/bin/service"]
