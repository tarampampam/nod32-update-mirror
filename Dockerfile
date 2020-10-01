# Image page: <https://hub.docker.com/_/golang>
FROM golang:1.15-alpine as builder

# can be passed with any prefix (like `v1.2.3@GITHASH`)
# e.g.: `docker build --build-arg "APP_VERSION=v1.2.3@GITHASH" .`
ARG APP_VERSION="undefined@docker"

WORKDIR /src

COPY ./go.mod ./go.sum ./

# Burn modules cache
RUN set -x \
    && go version \
    && go mod download \
    && go mod verify

COPY . /src

RUN set -x \
    && go version \
    && GOOS=linux GOARCH=amd64 go build \
        -ldflags="-s -w -X nod32-update-mirror/internal/pkg/version.version=${APP_VERSION}" ./cmd/... \
    && ./nod32-mirror --version

# Image page: <https://hub.docker.com/_/alpine>
FROM alpine:latest as runtime

ARG APP_VERSION="undefined@docker"

LABEL \
    # Docs: <https://github.com/opencontainers/image-spec/blob/master/annotations.md>
    org.opencontainers.image.title="nod32-update-mirror" \
    org.opencontainers.image.description="Eset Nod32 updates mirror" \
    org.opencontainers.image.url="https://github.com/tarampampam/nod32-update-mirror" \
    org.opencontainers.image.source="https://github.com/tarampampam/nod32-update-mirror" \
    org.opencontainers.image.vendor="tarampampam" \
    org.opencontainers.version="$APP_VERSION" \
    org.opencontainers.image.licenses="MIT"

RUN set -x \
    # Unprivileged user creation <https://stackoverflow.com/a/55757473/12429735RUN>
    && adduser \
        --disabled-password \
        --gecos "" \
        --home /nonexistent \
        --shell /sbin/nologin \
        --no-create-home \
        --uid 10001 \
        appuser

# Use an unprivileged user
USER appuser:appuser

# Import from builder
COPY --from=builder --chown=appuser /src/nod32-mirror /app/nod32-mirror
COPY --from=builder --chown=appuser /src/configs /app/configs

WORKDIR /app

ENTRYPOINT ["/app/nod32-mirror"]
