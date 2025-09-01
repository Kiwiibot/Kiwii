FROM dart:3.8.0 AS builder

WORKDIR /bot

# Install dependencies
COPY pubspec.* /bot/
RUN dart pub get

# Copy code
COPY . /bot/
RUN dart pub get --offline

# Generate the files
RUN dart run build_runner build --delete-conflicting-outputs
RUN dart run slang build
RUN dart run bin/emojis.dart
RUN dart compile exe -o run-migrations bin/migrations.dart

# Compile bot into executable
RUN dart run nyxx_commands:compile --no-compile -o kiwii.g.dart bin/kiwii.dart
RUN dart compile exe -o kiwii kiwii.g.dart

FROM debian:buster-slim AS runner

WORKDIR /app

RUN apt-get update && apt-get install -y libssl-dev && rm -rf /var/lib/apt/lists/*

COPY --from=builder /bot/kiwii /app/kiwii
COPY --from=builder /bot/migrations /app/migrations
COPY --from=builder /bot/run-migrations /usr/local/bin
COPY --from=builder /bot/logs /app/logs
COPY --from=builder /bot/lib/utils/metadata.json /app/lib/utils/metadata.json

RUN truncate -s 0 logs/log.log && truncate -s 0 logs/log.err

RUN touch .env 

CMD ["/app/kiwii"]
