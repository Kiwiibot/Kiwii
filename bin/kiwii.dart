import 'dart:io' as io;

import 'package:dart_openai/dart_openai.dart';
import 'package:kiwii/commands/core/help.dart';
import 'package:kiwii/commands/fun/markov.dart';
import 'package:kiwii/commands/fun/uwurandom.dart';
import 'package:kiwii/commands/tag.dart';
import 'package:kiwii/commands/utils/source.dart';
import 'package:kiwii/database.dart';
// import 'package:kiwii/plugins/chat.dart';
import 'package:kiwii/plugins/github_expand.dart';
import 'package:kiwii/plugins/tag/tag.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:kiwii/commands/ping.dart';
import 'package:get_it/get_it.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
// import 'package:perspective_api/perspective_api.dart';
import 'package:kiwii/src/settings.dart' as settings;
import 'package:kiwii/utils/io/stdout.dart' as ioutils;
import 'package:kiwii/utils/io/stderr.dart' as ioutils;
// import 'package:nyxx_utils/nyxx_analytics/nyxx_analytics.dart';
// import 'package:logging/logging.dart';
// import 'package:sentry/sentry.dart';

void main() async {
  // await Sentry.init((options) {
  //   options.dsn = settings.dsn;
  //   options.tracesSampleRate = 1.0;
  // });

  // try {
  //   await _main();
  // } catch (e, stackTrace) {
  //   await Sentry.captureException(
  //     e,
  //     stackTrace: stackTrace,
  //   );
  // }
  await _main();
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
  );

  final commands = CommandsPlugin(
    prefix: mentionOr(dmOr((_) => settings.prefix)),
    options: CommandsOptions(
      logErrors: false,
      defaultResponseLevel: ResponseLevel.public,
    ),
  );

  commands.addCommand(ping);
  commands.addCommand(markov);
  commands.addCommand(uwurandom);
  commands.addCommand(tag);
  commands.addCommand(helpCommand);
  commands.addCommand(sourceCommand);

  final listConverter = Converter<List<String>>((view, ctx) {
    final args = <String>[];
    while (!view.eof) {
      final word = view.getWord();
      args.add(word);
    }
    return args;
  });

  final chatCommandConverter = Converter<ChatCommand>((view, ctx) {
    return ctx.commands.getCommand(view);
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
      initialPresence: PresenceBuilder(
        status: CurrentUserStatus.idle,
        isAfk: false,
        since: DateTime.now(),
      ),
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
        // Analytics(port: 8888),
      ],
    ),
  );

  GetIt.I.registerSingleton(client);

  // final perspective = PerspectiveApi(
  //   apiKey: settings.perspectiveApiKey,
  // );

  // client.on<MessageCreateEvent>((event) async {
  //   final message = event.message;

  //   if (message.type != MessageType.normal || message.type != MessageType.reply) {
  //     return;
  //   }

  //   if (message.author case User(isBot: true)) {
  //     return;
  //   }

  //   final analyzed = await perspective.analyzeComment(
  //     message.content,
  //     requestedAttributes: {
  //       RequestedAttribute.toxicity,
  //       RequestedAttribute.threat,
  //     },
  //     languages: {Language.english, Language.french},
  //   );

  //   final attributes = analyzed.attributeScores;

  //   final highestScore = attributes.fold<double>(
  //     0,
  //     (previousValue, element) => element.summaryScore > previousValue ? element.summaryScore : previousValue,
  //   );

  //   if (highestScore > 0.8) {
  //     await message.delete();
  //     return;
  //   }
  // });

  commands.onCommandError.listen(
    (error) {
      if (error is CommandNotFoundException) {
        return;
      }

      commands.logger.shout('Uncaught exception in command', error, error.stackTrace);
    },
  );
}
