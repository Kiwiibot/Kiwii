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

# FROM node:20-alpine AS kiwii_api

# # Copy code
# COPY ./api /api/
# WORKDIR /api

# COPY ./api/package.json /api/

# RUN npm i -g npm@latest

# # Install python
# RUN apk add --no-cache build-base cairo-dev pango-dev jpeg-dev giflib-dev librsvg-dev

# # Install dependencies
# RUN npm i

# RUN npm run build

# CMD [ "node", "dist/index.js" ]