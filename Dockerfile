FROM dart:3.7.2 AS kiwii

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

# Compile bot into executable
RUN dart run nyxx_commands:compile --no-compile -o kiwii.g.dart bin/kiwii.dart
RUN dart compile exe -o kiwii kiwii.g.dart

CMD [ "./kiwii" ]
