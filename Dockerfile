# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM node:20-alpine AS web
WORKDIR /src
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY index.html vite.config.js tailwind.config.js postcss.config.js ./
COPY src/ ./src/
COPY public/ ./public/
RUN yarn build

FROM --platform=$BUILDPLATFORM golang:1.24-alpine AS backend
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY server/ ./server/
ARG TARGETOS=linux
ARG TARGETARCH=amd64
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -ldflags="-s -w" -o /segscope-viz ./server

FROM scratch
COPY --from=backend /segscope-viz /segscope-viz
COPY --from=web /src/build/ /app/build/
COPY third_party/segscope/LICENSE /licenses/segscope-MIT.txt
COPY LICENSE /licenses/application-Apache-2.0.txt
COPY --chown=65532:65532 packaging/data/ /data/
VOLUME ["/data"]
LABEL org.opencontainers.image.title="SegScope" org.opencontainers.image.version="0.3.0" org.opencontainers.image.source="https://github.com/casosorg/segscope" org.opencontainers.image.licenses="Apache-2.0 AND MIT"
ENV SEGSCOPE_ADDR=:8080 SEGSCOPE_DATA_DIR=/data/jobs SEGSCOPE_ENABLE_JOBS=true
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/segscope-viz"]
