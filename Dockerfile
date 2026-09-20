# syntax=docker/dockerfile:1

# ---- fetch stage -------------------------------------------------
FROM alpine:3.22 AS fetch

ARG PB_VERSION=0.40.4
ARG TARGETARCH=amd64

RUN apk add --no-cache unzip ca-certificates

ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_${TARGETARCH}.zip /tmp/pb.zip

RUN unzip /tmp/pb.zip -d /pb/ \
    && rm /tmp/pb.zip \
    && chmod +x /pb/pocketbase

# ---- runtime stage -----------------------------------------------
FROM alpine:3.22

# ca-certificates: outbound TLS for S3 backups, SMTP and OAuth providers
# tzdata: lets TZ control the backup cron schedule
RUN apk add --no-cache ca-certificates tzdata

COPY --from=fetch /pb/pocketbase /pb/pocketbase

# pb_data is the volume mount point; the rest are optional extension dirs
RUN mkdir -p /pb/pb_data /pb/pb_public /pb/pb_hooks /pb/pb_migrations

EXPOSE 8080

# Shell form so ${PORT} expands. Railway injects PORT; 8080 is the local default.
# --dir is explicit so the data directory never depends on the binary's location.
# --encryptionEnv is added only when PB_ENCRYPTION_KEY is set, so it stays opt-in.
CMD ["sh", "-c", "/pb/pocketbase serve \
  --http=0.0.0.0:${PORT:-8080} \
  --dir=/pb/pb_data \
  --publicDir=/pb/pb_public \
  --hooksDir=/pb/pb_hooks \
  --migrationsDir=/pb/pb_migrations \
  ${PB_ENCRYPTION_KEY:+--encryptionEnv=PB_ENCRYPTION_KEY}"]
