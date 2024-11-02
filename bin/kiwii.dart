/*
 * Kiwii, a stupid Discord bot.
 * Copyright (C) 2019-2024 Lexedia
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

// import 'package:dart_openai/dart_openai.dart';
import 'package:kiwii/events/member_log.dart';
import 'package:kiwii/plugins/base.dart';
import 'package:kiwii/plugins/load_modules.dart';
import 'package:nyxx_utils/nyxx_utils.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:get_it/get_it.dart';
import 'package:kiwii/commands/moderation/ban.dart';
import 'package:kiwii/commands/moderation/case.dart';
import 'package:kiwii/commands/moderation/lookup.dart';
import 'package:kiwii/commands/moderation/reason.dart';
import 'package:kiwii/commands/moderation/timeout.dart';
import 'package:kiwii/commands/moderation/warn.dart';
import 'package:kiwii/commands/ping.dart';
import 'package:kiwii/commands/tag.dart';
import 'package:kiwii/commands/utils/info.dart';
import 'package:kiwii/commands/utils/settings.dart';
import 'package:kiwii/commands/utils/source.dart';
import 'package:kiwii/database.dart';
import 'package:kiwii/events/appeal.dart';
import 'package:kiwii/events/bans.dart';
import 'package:kiwii/events/message_create.dart';
import 'package:kiwii/events/message_log.dart';
import 'package:kiwii/events/ready.dart';
import 'package:kiwii/events/timeouts.dart';
import 'package:kiwii/kiwii.dart';
import 'package:kiwii/plugins/chat.dart';
import 'package:kiwii/plugins/github_expand.dart';
import 'package:kiwii/plugins/localization.dart';
import 'package:kiwii/plugins/tag/tag.dart';
import 'package:kiwii/plugins/trace_exceptions.dart';
import 'package:kiwii/src/settings.dart' as settings;
import 'package:kiwii/utils/io/stderr.dart' as ioutils;
import 'package:kiwii/utils/io/stdout.dart' as ioutils;
import 'package:neat_cache/neat_cache.dart';
import 'package:nyxx/nyxx.dart' hide Cache;
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:sentry/sentry_io.dart';

void main() async {
  if (!settings.isDev) {
    await Sentry.init((options) {
      options.dsn = settings.dsn;
      options.tracesSampleRate = 1.0;
      options.environment = settings.isDev ? 'debug' : 'production';
    });

    try {
      await _main();
    } catch (e, stackTrace) {
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
    }
  } else {
    await _main();
  }
}

Future<void> _main() async {
  // client.

  final db = AppDatabase();
  // OpenAI.showLogs = true;
  final openai = OpenAIClient(apiKey: settings.chatbotToken, baseUrl: settings.chatbotUrl);
  final errFile = io.File('logs/log.err');
  final logFile = io.File('logs/log.log');
  final stderr = settings.isDev ? io.stderr : ioutils.Stderr(errFile, io.stderr);
  final stdout = settings.isDev ? io.stdout : ioutils.Stdout(logFile, io.stdout);
  final logging = Logging(
    stderr: UwUiferStringSink(stderr),
    stdout: UwUiferStringSink(stdout),
    logLevel: Level.FINE,
    censorToken: true,
    truncateLogsAt: 10000,
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
    guild: settings.isDev ? settings.testGuildId : null,
  );

  final logger = Logger('Kiwii');

  final cacheProvider = Cache.inMemoryCacheProvider(1000);
  final cache = Cache(cacheProvider);
  final kiwiiCache = cache.withPrefix('kiwii').withCodec(utf8);

  commands.addCommand(ping);
  commands.addCommand(markov);
  commands.addCommand(uwurandom);
  commands.addCommand(tag);
  commands.addCommand(helpCommand);
  commands.addCommand(sourceCommand);
  // commands.addCommand(overwatchCommand);
  commands.addCommand(settingsCommand);
  commands.addCommand(runAsCommand);
  commands.addCommand(warnCommand);
  commands.addCommand(timeoutCommand);
  commands.addCommand(reasonCommand);
  commands.addCommand(banCommand);
  commands.addCommand(lookupCommand);
  commands.addCommand(userLookupCommand);
  commands.addCommand(caseCommand);
  commands.addCommand(infoCommand);
  // commands.addCommand(evalCommand);

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

  final basePluginConverter = Converter<BasePlugin>((view, ctx) {
    final guild = ctx.guild;

    if (guild == null) {
      return null;
    }

    final mod = guild.modules[view.getQuotedWord()] ?? modules[view.getQuotedWord()];

    if (mod == null) {
      return null;
    }

    return mod;
  });

  commands.addConverter(listConverter);
  commands.addConverter(chatCommandConverter);
  commands.addConverter(basePluginConverter);

  GetIt.I.registerSingleton(commands);
  GetIt.I.registerSingleton(db);
  GetIt.I.registerSingleton(logger);
  GetIt.I.registerSingleton(kiwiiCache);
  GetIt.I.registerSingleton(openai);

  final client = await Nyxx.connectGatewayWithOptions(
    GatewayApiOptions(
      token: settings.token,
      intents: GatewayIntents.all,
      payloadFormat: GatewayPayloadFormat.etf,
      browser: 'Discord Android',
    ),
    GatewayClientOptions(
      plugins: [
        logging,
        TagPlugin(),
        ChatPlugin(),
        GithubExpand(),
        ModulesPlugin(),
        cliIntegration,
        commands,
        pagination,
        localization,
        ignoreExceptions,
        traceExceptions,
        guildJoins,
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

  client.onReady.take(1).listen(readyEvent);

  client.onAutoModerationActionExecution.listen(onAutoModerationActionExecutionTimeout);
  client.onGuildMemberUpdate.listen(onGuildMemberUpdateTimeout);

  client.onMessageCreate.where((e) {
    if (e.guildId != null) {
      return false;
    }

    if (e.message.author case WebhookAuthor() || User(isBot: true)) {
      return false;
    }

    return true;
  }).listen(waitForAppeals);

  client.onMessageCreate.listen(onMessageCreate);

  client.onMessageComponentInteraction.where((e) => e.interaction.data.customId.startsWith('appeal-')).listen(onButtonAppeal);

  client.onGuildBanAdd.listen(onGuildBanAdd);
  client.onGuildBanRemove.listen(onGuildBanRemove);
  client.onMessageDelete.listen(onMessageDelete);
  client.onMessageUpdate.listen(onMessageUpdate);
  client.onGuildMemberAdd.listen(onGuildMemberAdd);
  client.onGuildMemberRemove.listen(onGuildMemberRemove);

  commands.onCommandError.listen(
    (error) async {
      if (error is CommandNotFoundException) {
        return;
      }

      if (error is UnhandledInteractionException) {
        final ctx = error.context;
        switch (error.reason) {
          case ComponentIdStatus.expired:
            await ctx.interaction.message?.edit(
              MessageUpdateBuilder(
                content: 'This interaction has expired',
                components: [],
                embeds: [],
              ),
            );
          case ComponentIdStatus.wrongUser:
            await ctx.respond(
              MessageBuilder(content: 'This interaction is not for you'),
              level: ResponseLevel.private,
            );
          default:
            break;
        }

        return;
      }

      if (error case CheckFailedException(:final context, :final failed)) {
        if (failed is SelfPermissionsCheck) {
          final permissions = await failed.requiredPermissions as Flags<Permissions>;
          await context.respond(
            MessageBuilder(
              content: 'I do not have the required permissions to execute this command\nMissing: ${translatePermissions(permissions, context.guild.t).map(
                (p) => '`$p`',
              )}',
            ),
          );

          return;
        }
      }

      if (error case ConverterFailedException(:final context)) {
        if (context case InteractiveContext context) {
          await context.respond(
            MessageBuilder(content: 'Failed to convert argument\n${error.input.remaining}'),
          );
        }
      }

      commands.logger.shout(
        'Uncaught exception in command\n${error.message}',
        error,
        error.stackTrace,
      );

      if (!settings.isDev) {
        await Sentry.captureException(
          error,
          stackTrace: error.stackTrace,
        );
      }

      if (error case CommandInvocationException(:final context)) {
        await context.respond(MessageBuilder(content: 'An error occurred while executing the command\n${error.message}'));
      }
    },
  );
}
