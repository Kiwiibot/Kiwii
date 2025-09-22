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

import 'package:get_it/get_it.dart';
import 'package:kiwii/events/appeal.dart';
import 'package:kiwii/events/bans.dart';
import 'package:kiwii/events/member_log.dart';
import 'package:kiwii/events/message_create.dart';
import 'package:kiwii/events/message_log.dart';
import 'package:kiwii/events/message_reaction_add.dart';
import 'package:kiwii/events/ready.dart';
import 'package:kiwii/events/timeouts.dart';
import 'package:kiwii/kiwii.dart';
import 'package:kiwii/plugins/localization.dart';
import 'package:kiwii/plugins/prometheus.dart';
import 'package:kiwii/services/api.dart';
import 'package:kiwii/src/settings.dart' as settings;
import 'package:kiwii/src/structs/kiwii.dart';

import 'package:neat_cache/neat_cache.dart';
import 'package:nyxx/nyxx.dart' hide Cache, Connection;
import 'package:nyxx_commands/nyxx_commands.dart' hide userConverter, memberConverter;
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:sentry/sentry_io.dart';
import 'package:sentry_logging/sentry_logging.dart';
import 'package:postgres/postgres.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/date_symbol_data_local.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:prometheus_client/runtime_metrics.dart' as runtime_metrics;

void main() async {
  runZonedGuarded(() async {
    await Sentry.init((options) {
      options.dsn = settings.dsn;
      options.tracesSampleRate = 1.0;
      options.environment = settings.isDev ? 'debug' : 'production';
      options.enableLogs = true;
      options.addIntegration(LoggingIntegration());
    });

    await _main();
  }, (error, stackTrace) async {
    await Sentry.captureException(error, stackTrace: stackTrace);
  });
}

Future<void> _main() async {
  runtime_metrics.register();
  await initializeDateFormatting();

  final connection = await Connection.open(
    Endpoint(
      database: settings.postgresDb,
      host: settings.postgresHost,
      username: settings.postgresUser,
      password: settings.postgresPassword,
      port: settings.postgresPort,
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );
  GetIt.I.registerSingleton(connection);

  final cacheProvider = Cache.inMemoryCacheProvider(1000);
  final cache = Cache(cacheProvider);
  final kiwiiCache = cache.withPrefix('kiwii').withCodec(utf8);

  final client = await Kiwii.connect();

  final commands = client.options.plugins.whereType<CommandsPlugin>().single;

  GetIt.I.registerSingleton(client);
  GetIt.I.registerSingleton(commands);
  GetIt.I.registerSingleton(kiwiiCache);

  registerEventCollectors(client);
  registerPeriodicCollectors(client);

  pagination.onDisallowedUse.listen((event) async {
    await event.interaction.respond(MessageBuilder(content: 'This is not for you!'), isEphemeral: true);
  });

  client.onReady.take(1).listen(readyEvent);

  client.onAutoModerationActionExecution.listen(onAutoModerationActionExecutionTimeout);
  client.onGuildMemberUpdate.listen(onGuildMemberUpdateTimeout);
  client.onMessageReactionAdd.where((e) => e.guildId != null).listen(onMessageReactionAdd);

  client.onMessageCreate
      .where((e) {
        if (e.guildId != null) {
          return false;
        }

        if (e.message.author case WebhookAuthor() || User(isBot: true)) {
          return false;
        }

        return true;
      })
      .listen(waitForAppeals);

  client.onMessageCreate.listen(onMessageCreate);

  client.onMessageComponentInteraction.where((e) => e.interaction.data.customId.startsWith('appeal-')).listen(onButtonAppeal);

  client.onGuildBanAdd.listen(onGuildBanAdd);
  client.onGuildBanRemove.listen(onGuildBanRemove);
  client.onMessageDelete.listen(onMessageDelete);
  client.onMessageUpdate.listen(onMessageUpdate);
  client.onGuildMemberAdd.listen(onGuildMemberAdd);
  client.onGuildMemberRemove.listen(onGuildMemberRemove);

  commands.onCommandError.listen((error) async {
    if (error is CommandNotFoundException) {
      return;
    }

    if (error is UnhandledInteractionException) {
      final ctx = error.context;
      switch (error.reason) {
        case ComponentIdStatus.expired:
          await ctx.interaction.message?.edit(MessageUpdateBuilder(content: 'This interaction has expired', components: [], embeds: []));
        case ComponentIdStatus.wrongUser:
          await ctx.respond(MessageBuilder(content: 'This interaction is not for you'), level: ResponseLevel.private);
        default:
          break;
      }

      return;
    }

    if (error case CheckFailedException(:final context, :final failed)) {
      if (failed is SelfPermissionsCheck) {
        if (context.guild == null) {
          return;
        }

        final permissions = failed.permissions;
        final memberPermissions = await (await context.guild!.me).computePermissionsIn(context.channel as GuildTextChannel);

        final remaining = permissions & ~memberPermissions;

        await context.respond(
          MessageBuilder(
            content:
                'I do not have the required permissions to execute this command\nMissing: ${translatePermissions(remaining, context.guild.t).map((p) => '`$p`')}',
          ),
        );

        return;
      }

      if (failed is BasePermissionsCheck) {
        if (context.guild == null) {
          return;
        }

        final permissions = failed.permissions;

        final memberPermissions = await context.member!.computePermissionsIn(context.channel as GuildTextChannel);
        final remaining = permissions & ~memberPermissions;

        await context.respond(
          MessageBuilder(
            content:
                'Missing permissions!\n You are missing the following permissions to run this command: ${translatePermissions(remaining, context.guild.t).map((p) => '`$p`').join(', ')}',
          ),
        );
        return;
      }

      if (failed is HasModChannelCheck) {
        await context.respond(MessageBuilder(content: context.guild.t.general.errors.noModChannel));
        return;
      }
    }

    if (error case ConverterFailedException(:final context, :final failed)) {
      if (context case InteractiveContext context) {
        await context.respond(
          MessageBuilder(content: 'Failed to convert ${inlineCode(error.input.remaining)} to ${inlineCode(failed.output.internalType.toString())}'),
        );
        return;
      }
    }

    if (error case AutocompleteFailedException(exception: final Error exception)) {
      commands.logger.shout('Autocomplete failed', exception, exception.stackTrace);
      return;
    }

    if (error case CheckFailedException(:final context, :final failed)) {
      if (failed is OwnerCheck) {
        await context.respond(MessageBuilder(content: 'This command can only be executed by the bot owner!'));
        return;
      }

      if (failed is GuildCheck) {
        // we silently drop.
        return;
      }
    }

    if (error case final NotEnoughArgumentsException exception) {
      final args = (exception.context as MessageChatContext).command.arguments;
      final rawArguments = StringView((exception.context as MessageChatContext).rawArguments);
      final providedArgs =
          (await args
                  .map((param) {
                    if (rawArguments.eof) {
                      return null;
                    }
                    return parse(commands, exception.context, rawArguments, param.type, converterOverride: param.converterOverride).catchError((_) => null);
                  })
                  .nonNulls
                  .wait)
              .toList();
      final difference = args.indexed.where((e) => providedArgs.asMap()[e.$1] == null).map((e) => e.$2).toList();
      await exception.context.respond(
        MessageBuilder(content: 'Not enough arguments, missing: ${difference.where((e) => !e.isOptional).map((e) => '`${e.name}`').join(', ')}'),
      );
      return;
    }

    commands.logger.shout('Uncaught exception in command\n${error.message}', error, error.stackTrace);

    if (!settings.isDev) {
      await Sentry.captureException(error, stackTrace: error.stackTrace);
    }

    if (error case CommandInvocationException(:final context)) {
      await context.respond(MessageBuilder(content: 'An error occurred while executing the command\n${error.message}'), level: ResponseLevel.hint);
    }
  });

  final apiServer = await api();

  await io.serve(apiServer, '0.0.0.0', 8080);
}
