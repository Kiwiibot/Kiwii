import 'dart:async';
import 'dart:io' as io;
import 'dart:math';

import 'package:dart_openai/dart_openai.dart';
import 'package:get_it/get_it.dart';
import 'package:kiwii/commands/core/help.dart';
import 'package:kiwii/commands/fun/markov.dart';
import 'package:kiwii/commands/fun/overwatch.dart';
import 'package:kiwii/commands/fun/uwurandom.dart';
import 'package:kiwii/commands/ping.dart';
import 'package:kiwii/commands/tag.dart';
import 'package:kiwii/commands/utils/settings.dart';
import 'package:kiwii/commands/utils/source.dart';
import 'package:kiwii/database.dart';
import 'package:kiwii/plugins/github_expand.dart';
import 'package:kiwii/plugins/localization.dart';
import 'package:kiwii/plugins/tag/tag.dart';
import 'package:kiwii/plugins/trace_exceptions.dart';
import 'package:kiwii/src/settings.dart' as settings;
import 'package:kiwii/utils/io/stderr.dart' as ioutils;
import 'package:kiwii/utils/io/stdout.dart' as ioutils;
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:sentry/sentry_io.dart';

void main() async {
  await Sentry.init((options) {
    options.dsn = settings.dsn;
    options.tracesSampleRate = 1.0;
  });

  try {
    await _main();
  } catch (e, stackTrace) {
    await Sentry.captureException(
      e,
      stackTrace: stackTrace,
    );
  }
}

Future<void> _main() async {
  final db = AppDatabase();
  OpenAI.showLogs = false;
  final errFile = io.File('logs/log.err');
  final logFile = io.File('logs/log.log');
  final stderr = settings.isDev ? io.stderr : ioutils.Stderr(errFile, io.stderr);
  final stdout = settings.isDev ? io.stdout : ioutils.Stdout(logFile, io.stdout);
  final logging = Logging(
    stderr: stderr,
    stdout: stdout,
    logLevel: Level.ALL,
  );

  final commands = CommandsPlugin(
    prefix: mentionOr(dmOr((_) => settings.prefix)),
    options: CommandsOptions(
      logErrors: false,
      defaultResponseLevel: ResponseLevel(
        hideInteraction: false,
        isDm: false,
        mention: false,
        preserveComponentMessages: true,
      ),
    ),
  );

  commands.addCommand(ping);
  commands.addCommand(markov);
  commands.addCommand(uwurandom);
  commands.addCommand(tag);
  commands.addCommand(helpCommand);
  commands.addCommand(sourceCommand);
  commands.addCommand(overwatchCommand);
  commands.addCommand(settingsCommand);

  final listConverter = Converter<List<String>>((view, ctx) {
    final args = <String>[];
    while (!view.eof) {
      final word = view.getWord();
      args.add(word);
    }
    return args;
  });

  final chatCommandConverter = Converter<ChatCommand>((view, ctx) {
    return ctx.commands.getCommand(StringView(view.getQuotedWord()));
  });

  commands.addConverter(listConverter);
  commands.addConverter(chatCommandConverter);

  GetIt.I.registerSingleton(commands);
  GetIt.I.registerSingleton(db);

  final client = await Nyxx.connectGatewayWithOptions(
    GatewayApiOptions(
      token: settings.token,
      intents: GatewayIntents.all,
      payloadFormat: GatewayPayloadFormat.etf,
    ),
    GatewayClientOptions(
      plugins: [
        logging,
        TagPlugin(),
        // ChatPlugin(),
        GithubExpand(),
        cliIntegration,
        commands,
        pagination,
        localization,
        ignoreExceptions,
        traceExceptions,
      ],
    ),
  );

  GetIt.I.registerSingleton(client);

  pagination.onDisallowedUse.listen((event) async {
    await event.interaction.respond(
      MessageBuilder(content: 'This is not for you!'),
      isEphemeral: true,
    );
  });

  client.onReady.listen((event) async {
    Timer.periodic(const Duration(seconds: 10), (timer) {
      final status = '${settings.prefix}help ─ ${settings.statuses[Random().nextInt(settings.statuses.length)]}';
      client.updatePresence(
        PresenceBuilder(
          isAfk: false,
          status: CurrentUserStatus.idle,
          activities: [
            ActivityBuilder(
              type: ActivityType.custom,
              name: status,
              state: status,
            ),
          ],
        ),
      );
    });
  });

  commands.onCommandError.listen(
    (error) async {
      if (error is CommandNotFoundException) {
        return;
      }

      commands.logger.shout(
        'Uncaught exception in command',
        error,
        error.stackTrace,
      );

      await Sentry.captureException(
        error,
        stackTrace: error.stackTrace,
      );

      if (error case CommandInvocationException(:final context)) {
        await context.respond(MessageBuilder(content: 'An error occurred while executing the command\n${error.message}'));
      }
    },
  );
}
