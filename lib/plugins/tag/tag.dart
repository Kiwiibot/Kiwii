import 'dart:async';

import 'package:get_it/get_it.dart';
import '../../database.dart';
import '../../kiwii.dart';
import '../../utils/parser.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
// ignore: implementation_imports
import 'package:nyxx_commands/src/context/base.dart';
// import 'package:kiwii/utils/parser.dart';
import '../../src/settings.dart' as settings;

class ContextBaseWithMessage extends ContextBase {
  final Message message;

  final Map<String, Object?> rawMessage;

  ContextBaseWithMessage({
    required this.message,
    required this.rawMessage,
    required super.channel,
    required super.client,
    required super.commands,
    required super.guild,
    required super.member,
    required super.user,
  });
}

class TagPlugin extends NyxxPlugin<NyxxGateway> {
  @override
  String get name => 'Tag';
  final StreamController<Map<String, Object?>?> _onRawMessageCreateController = StreamController.broadcast();
  Stream<Map<String, Object?>?> get onRawMessageCreate => _onRawMessageCreateController.stream;
  late final NyxxGateway client;
  final db = GetIt.I.get<AppDatabase>();
  @override
  Future<void> afterConnect(NyxxGateway client) async {
    this.client = client;

    onRawMessageCreate.listen(processTag);
  }

  @override
  Stream<ShardMessage> interceptShardMessages(Shard shard, Stream<ShardMessage> messages) {
    final stream = super.interceptShardMessages(shard, messages);
    return stream.map((message) {
      if (message is EventReceived) {
        final event = message.event;

        if (event is RawDispatchEvent && event.name == 'MESSAGE_CREATE') {
          _onRawMessageCreateController.add(event.payload);
        }
      }

      return message;
    });
  }

  Future<void> processTag(Map<String, Object?>? rawMessage) async {
    final commands = client.options.plugins.whereType<CommandsPlugin>().single;
    final allCommands = commands.walkCommands().whereType<ChatCommand>();
    final event = client.gateway.parseMessageCreate(rawMessage!);
    if (!event.message.content.startsWith(settings.prefix)) {
      return;
    }
    // Ignore bots and webhooks.
    if (event.message.author case User(isBot: true) || WebhookAuthor()) {
      return;
    }
    final message = event.message;

    final [rawTag, ...args] = message.content.substring(settings.prefix.length).split(RegExp(r'\s+'));
    if (allCommands.any((cmd) => cmd.root.name == rawTag)) {
      return;
    }
    final user = event.message.author as User;
    final member = await event.member?.get();
    final guild = await event.guild?.fetch(withCounts: true);
    if (guild == null) {
      return;
    }
    final channel = await event.message.channel.get() as TextChannel;
    final ctx = ContextBaseWithMessage(
      user: user,
      member: member,
      guild: guild,
      channel: channel,
      commands: commands,
      client: client,
      message: message,
      rawMessage: rawMessage,
    );

    final parser = Parser(client, ctx);

    final tags = await (db.select(db.tags)
          ..where((tags) => tags.name.equals(rawTag) & tags.locationId.equals(guild.id.value))
          ..limit(1))
        .get();

    if (tags.isEmpty) {
      return;
    }

    final tag = tags.first;
    // Render tag.
    final renderedTag = await parser.parse(tag.content, tag, args);
    // Increment usage count.
    await db.into(db.tags).insert(tag.copyWith(timesCalled: tag.timesCalled + 1), mode: InsertMode.replace);
    await message.channel.sendMessage(
      MessageBuilder(
        content: renderedTag.result,
        allowedMentions: AllowedMentions.roles() & AllowedMentions.users(),
        replyId: message.id,
      ),
    );
  }
}
