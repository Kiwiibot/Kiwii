import 'dart:async';
import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:prometheus_client/prometheus_client.dart';

void registerPeriodicCollectors(NyxxGateway client) {
  final totalUsers = Gauge(name: 'kiwii_total_users_cache', help: 'Total users in cache')..register();
  final totalChannels = Gauge(name: 'kiwii_total_channels_cache', help: 'Total channels in cache')..register();
  final totalGuilds = Gauge(name: 'kiwii_total_guilds_cache', help: 'Total guilds in cache')..register();
  final totalMessages = Gauge(name: 'kiwii_total_messages_cache', help: 'Total messages in cache')..register();
  final shardWsLatency = Gauge(name: 'kiwii_shard_ws_latency', help: 'Shard websocket latency', labelNames: ['shard_id'])..register();

  Timer.periodic(const Duration(seconds: 5), (_) {
    totalUsers.value = client.users.cache.length.toDouble();
    totalChannels.value = client.channels.cache.length.toDouble();
    totalGuilds.value = client.guilds.cache.length.toDouble();
    totalMessages.value = client.channels.cache.values.whereType<TextChannel>().fold(0, (count, channel) => count + channel.messages.cache.length);

    for (final shard in client.gateway.shards) {
      shardWsLatency.labels([shard.id.toString()]).value = shard.latency.inMilliseconds.toDouble();
    }
  });
}

void registerEventCollectors(NyxxGateway client) {
  final commands = client.options.plugins.whereType<CommandsPlugin>().single;
  final totalMessagesSent = Counter(name: 'kiwii_total_messages_sent', help: 'Total messages sent', labelNames: ['guild_id'])..register();
  client.onMessageCreate.listen((event) => totalMessagesSent.labels([event.guild?.id.toString() ?? 'dm']).inc());

  final httpResponses = Counter(name: 'kiwii_http_responses', help: 'Total HTTP responses', labelNames: ['status_code'])..register();
  client.httpHandler.onResponse.listen((event) => httpResponses.labels([event.statusCode.toString()]).inc());
  client.httpHandler.onRateLimit.listen((event) => httpResponses.labels(['429']).inc());

  final totalCommands = Counter(name: 'kiwii_total_commands', help: 'Total commands executed', labelNames: ['name'])..register();
  final totalSlashCommands = Counter(name: 'kiwii_total_slash_commands', help: 'Total slash commands executed', labelNames: ['name'])..register();
  final totalTextCommands = Counter(name: 'kiwii_total_text_commands', help: 'Total text commands executed', labelNames: ['name'])..register();
  final totalUserCommands = Counter(name: 'kiwii_total_user_commands', help: 'Total user commands executed', labelNames: ['name'])..register();
  final totalMessageCommands = Counter(name: 'kiwii_total_message_commands', help: 'Total message commands executed', labelNames: ['name'])..register();

  commands.onPreCall.listen((ctx) {
    final name = ctx.command is ChatCommand ? (ctx.command as ChatCommand).fullName : ctx.command.name;

    totalCommands.labels([name]).inc();

    (switch (ctx) {
      InteractionChatContext() => totalSlashCommands.labels([name]).inc(),
      MessageChatContext() => totalTextCommands.labels([name]).inc(),
      UserContext() => totalUserCommands.labels([name]).inc(),
      MessageContext() => totalMessageCommands.labels([name]).inc(),
      _ => null,
    });

    final totalCommandsFailed = Counter(name: 'kiwii_total_commands_failed', help: 'Total commands failed', labelNames: ['error', 'name'])..register();

    commands.onCommandError.listen((error) {
      if (error case final CommandInvocationException error) {
        final ctx = error.context;
        final name = ctx.command is ChatCommand ? (ctx.command as ChatCommand).fullName : ctx.command.name;

        final errorName = (error is UncaughtException ? error.exception.runtimeType : error.runtimeType).toString();

        totalCommandsFailed.labels([errorName, name]).inc();
      }
    });

    final commandExecutionTime = Histogram.exponential(
      name: 'kiwii_command_execution_time',
      help: 'The time each command took to execute',
      labelNames: ['name'],
      start: 1,
      factor: pow(const Duration(minutes: 15).inMicroseconds, 0.1).toDouble(),
      count: 10,
    )..register();

    final ctxStartTime = Expando<DateTime>();

    commands.onPreCall.listen((ctx) => ctxStartTime[ctx] = DateTime.now().toUtc());

    void handle(CommandContext ctx) {
      final start = ctxStartTime[ctx];

      if (start == null) {
        return;
      }

      final execTime = DateTime.now().toUtc().difference(start);

      final name = ctx.command is ChatCommand ? (ctx.command as ChatCommand).fullName : ctx.command.name;

      commandExecutionTime.labels([name]).observe(execTime.inMilliseconds.toDouble());
    }

    commands.onPostCall.listen(handle);
    commands.onCommandError.where((e) => e is CommandInvocationException).cast<CommandInvocationException>().listen((error) => handle(error.context));
  });
}

class Prometheus extends NyxxPlugin<NyxxGateway> {
  @override
  Future<void> afterConnect(client) async {
    registerEventCollectors(client);
    registerPeriodicCollectors(client);
  }
}


final prometheus = Prometheus();
