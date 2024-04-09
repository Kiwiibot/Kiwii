FROM dart:3.3.1 AS kiwii

WORKDIR /bot

# Install dependencies
COPY pubspec.* /bot/
RUN dart pub get

# Copy code
COPY . /bot/
RUN dart pub get --offline

# Compile bot into executable
RUN dart run nyxx_commands:compile --compile -o kiwii.g.dart --no-compile bin/kiwii.dart
RUN dart compile exe -o kiwii kiwii.g.dart

CMD [ "./kiwii" ]

FROM node:20-alpine AS kiwii_api

WORKDIR /api

# Install dependencies
COPY package.json /api/
RUN corepack use pnpm@latest
RUN pnpm i

# Copy code
COPY . /api/

RUN pnpm build

CMD [ "node", "dist/index.js" ]