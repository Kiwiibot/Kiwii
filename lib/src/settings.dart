import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:nyxx/nyxx.dart';

final dotenv = DotEnv()..load();

String? getEnv(String key) => Platform.environment[key] ?? dotenv[key] ?? (String.fromEnvironment(key) == '' ? null : String.fromEnvironment(key));

const version = '0.1.0';

String fromEnvironment(String key, [String? defaultValue]) => getEnv(key) ?? defaultValue ?? (throw Exception('Missing `$key` environment variable'));

bool fromEnvironmentBool(String key, [bool? defaultValue]) =>
    switch (fromEnvironment(key, defaultValue?.toString()).toLowerCase()) { 'true' || '1' => true, _ => false };

/// The token of the bot
final prodToken = fromEnvironment('TOKEN');

/// The test token of the bot
final testToken = fromEnvironment('TOKEN_TEST');

/// Whether this is the development environment
final isDev = fromEnvironmentBool('DEV', false);

/// The perspective api key
final perspectiveApiKey = fromEnvironment('PERSPECTIVE_API_KEY');

/// The prefix of the bot
final prodPrefix = fromEnvironment('PREFIX', 'm?');

/// The test prefix of the bot
final testPrefix = fromEnvironment('TEST_PREFIX', 'n?');

/// The starboard emojis
final starboardEmojis = fromEnvironment('STARBOARD_EMOJIS', '🌟,⭐,🌠').split(',').toList();

/// The token to use, depending on the environment
final token = isDev ? testToken : prodToken;

/// The prefix to use, depending on the environment
final prefix = isDev ? testPrefix : prodPrefix;

/// The channels where the chatbot is enabled
final chatbotChannels = fromEnvironment('CHATBOT_CHANNELS', '912636659504414731').split(',').map(Snowflake.parse).toList();

final dsn = fromEnvironment('SENTRY_DSN');

final ownerId = Snowflake.parse(fromEnvironment('OWNER_ID', '253554702858452992'));


