import 'dart:async';
import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:postgres/postgres.dart';

import '../commands/utils/settings.dart';
import '../utils/extensions.dart';
import 'base.dart';

// taken from _commands
final RegExp _snowflakePattern = RegExp(r'^(?:<(?:@(?:!|&)?|#)([0-9]{15,20})>|([0-9]{15,20}))$');

final class StarboardPlugin extends BasePlugin {
  @override
  final String name = 'Starboard';

  late final Set<Snowflake> _loadedGuilds = {};

  late final Set<Snowflake> _staleStarGivers = {};
  late final Set<Snowflake> _aboutToBeDeleted = {};

  @override
  String helpText(self) => '';

  @override
  Future<void> onLoad(self, {required guild}) async {
    final commands = self.options.plugins.whereType<CommandsPlugin>().single;

    self.onMessageReactionAdd.listen(_onReactionAdd);
    self.onMessageReactionRemove.listen(_onReactionRemove);

    final guildCheck = starboardSettingsCommand.checks.whereType<GuildCheck>().singleOrNull;

    if (guildCheck == null) {
      starboardSettingsCommand.check(GuildCheck.anyId([guild.id]));
    } else {
      (guildCheck.guildIds as List<Snowflake?>).add(guild.id);
    }

    _loadedGuilds.add(guild.id);

    commands.addCommandOnTheFly(starboardSettingsCommand, guildId: guild.id);
  }

  @override
  Future<void> onUnload(self, {required guild}) async {
    final commands = self.options.plugins.whereType<CommandsPlugin>().single;

    commands.removeCommandOnTheFly(starboardSettingsCommand, guildId: guild.id);
    _loadedGuilds.remove(guild.id);
  }

  Future<void> _unstarMessage(GuildChannel channel, Message message, User user) async {
    Snowflake guildId = channel.guildId;

    final r = await client.repositories.connection.execute(
      r'SELECT channel_id, threshold, emojis FROM starboard WHERE id = $1;',
      parameters: [channel.guildId.value],
    );

    if (r.isEmpty) {
      return;
    }

    final (starboardChannelId, threshold, rawEmojis) = (
      r.single.first == null ? null : Snowflake.parse(r.single.first!),
      r.single[1] as int,
      r.single[2] as String,
    );

    if (starboardChannelId == null) {
      return;
    }

    final starboardChannel = await client.channels.get(starboardChannelId) as GuildTextChannel;

    if (channel.id == starboardChannel.id) {
      final [channelId, messageId!] = await client.repositories.connection
          .execute(r'SELECT channel_id, message_id FROM starboard_entries WHERE self_message_id = $1;', parameters: [message.id.value])
          .then((r) => r.single.map((s) => s == null ? null : Snowflake.parse(s)).toList());

      if (channelId == null) {
        return;
      }

      final subChannel = await client.channels.get(channelId) as GuildTextChannel;

      final subMessage = await subChannel.messages.get(messageId);

      return _unstarMessage(subChannel, subMessage, user);
    }

    final record = await client.repositories.connection.execute(
      r'''
DELETE FROM starrers USING starboard_entries entry
WHERE entry.message_id = $1
AND entry.id = starrers.entry_id
AND starrers.author_id = $2
RETURNING starrers.entry_id, entry.self_message_id;
''',
      parameters: [message.id.value, user.id.value],
    );

    if (record.isEmpty) {
      // TODO:
      return;
    }

    final entryId = record.single.first as int;
    final selfMessageId = record.single[1] == null ? null : Snowflake.parse(record.single[1]!);

    final result = await client.repositories.connection.execute(r'SELECT COUNT(*) FROM starrers WHERE entry_id = $1;', parameters: [entryId]);
    _staleStarGivers.add(guildId);
    int count = result.single.first as int;

    if (count == 0) {
      await client.repositories.connection.execute(r'DELETE FROM starboard_entries WHERE id = $1', parameters: [entryId]);
    }

    if (selfMessageId == null) {
      return;
    }

    Message selfMessage;

    try {
      selfMessage = await starboardChannel.messages.get(selfMessageId);
    } on HttpResponseError {
      return;
    }

    if (count < threshold) {
      _aboutToBeDeleted.add(selfMessageId);

      if (count != 0) {
        await client.repositories.connection.execute(
          r'UPDATE starboard_entries SET self_message_id = NULL, total = $1 WHERE id = $2;',
          parameters: [count, entryId],
        );
      }

      await selfMessage.delete();
    } else {
      await client.repositories.connection.execute(r'UPDATE starboard_entries SET total = $1 WHERE id = $2;', parameters: [count, entryId]);

      final parsedEmojis = rawEmojis.split(',');

      final emojis = await Future.wait(
        parsedEmojis.map((e) => _snowflakePattern.hasMatch(e) ? channel.guild.emojis.get(Snowflake.parse(e)) : Future.value(client.getTextEmoji(e))),
      );

      final emoji = emojis[Random().nextInt(emojis.length)];

      final (content, embed) = await _getStarboardEmbed(message, count, emoji);

      await selfMessage.edit(MessageUpdateBuilder(content: content, embeds: [embed]));
    }
  }

  Future<void> _starMessage(GuildChannel channel, Message message, User user, [Emoji? reactedEmoji]) async {
    final isNsfw = switch (channel) {
      Thread(:final parent?) => (await parent.get() as GuildChannel).isNsfw,
      GuildChannel(:final isNsfw) => isNsfw,
    };

    final r = await client.repositories.connection.execute(
      r'SELECT channel_id, threshold, emojis FROM starboard WHERE id = $1;',
      parameters: [channel.guildId.value],
    );

    if (r.isEmpty) {
      return;
    }

    final (starboardChannelId, threshold, rawEmojis) = (
      r.single.first == null ? null : Snowflake.parse(r.single.first!),
      r.single[1] as int,
      r.single[2] as String,
    );

    if (starboardChannelId == null) {
      return;
    }

    final starboardChannel = await client.channels.get(starboardChannelId) as GuildTextChannel;

    if (isNsfw && !starboardChannel.isNsfw) {
      return;
    }

    if (channel.id == starboardChannelId) {
      final re = await client.repositories.connection.execute(
        r'SELECT channel_id, message_id FROM starboard_entries WHERE self_message_id=$1;',
        parameters: [message.id.value],
      );

      if (re.isEmpty) {
        return;
      }

      final channelId = Snowflake.parse(re.single.first!);
      final messageId = Snowflake.parse(re.single[1]!);

      final chan = await client.channels.get(channelId) as GuildTextChannel;
      final msg = await chan.messages.get(messageId);

      await _starMessage(chan, msg, user, reactedEmoji);
      return;
    }

    final parsedEmojis = rawEmojis.split(',');

    final emojis = await Future.wait(
      parsedEmojis.map((e) => _snowflakePattern.hasMatch(e) ? channel.guild.emojis.get(Snowflake.parse(e)) : Future.value(client.getTextEmoji(e))),
    );

    if (reactedEmoji != null && !emojis.contains(reactedEmoji)) {
      return;
    }

    int entryId;

    try {
      final r = await client.repositories.connection.execute(
        r'''
WITH to_insert AS (
  INSERT INTO starboard_entries AS entries (message_id, channel_id, guild_id, author_id)
  VALUES ($1, $2, $3, $4)
  ON CONFLICT (message_id) DO NOTHING
  RETURNING entries.id
) INSERT INTO starrers (author_id, entry_id)
  SELECT $5, entry.id
  FROM (SELECT id FROM to_insert UNION ALL
    SELECT id FROM starboard_entries WHERE message_id=$1
    LIMIT 1
  ) AS entry
RETURNING entry_id;
''',
        parameters: [message.id.value, channel.id.value, channel.guild.id.value, message.author.id.value, user.id.value],
      );

      entryId = r.single.single as int;
    } on ServerException catch (e) {
      if (e.code == '23505') {
        return;
      }

      rethrow;
    }

    final countResult = await client.repositories.connection.execute(r'SELECT COUNT(*) FROM starrers WHERE entry_id = $1', parameters: [entryId]);

    final count = countResult.single.single as int;

    _staleStarGivers.add(channel.guild.id);

    if (count < threshold) {
      await client.repositories.connection.execute(r'UPDATE starboard_entries SET total= $1 WHERE id= $2;', parameters: [count, entryId]);
    }

    // Pick a random emoji each time a message is starred
    final emoji = emojis[Random().nextInt(emojis.length)];

    final (content, embed) = await _getStarboardEmbed(message, count, emoji);

    final entry = await client.repositories.connection.execute(r'SELECT self_message_id FROM starboard_entries WHERE id = $1', parameters: [entryId]);
    final selfMessageId = entry.single.single == null ? null : Snowflake.parse(entry.single.single!);

    if (selfMessageId == null) {
      final msg = await starboardChannel.sendMessage(MessageBuilder(content: content, embeds: [embed]));
      await client.repositories.connection.execute(
        r'UPDATE starboard_entries SET self_message_id = $1, total = $2 WHERE id = $3;',
        parameters: [msg.id.value, count, entryId],
      );
    } else {
      try {
        final msg = await starboardChannel.messages.get(selfMessageId);

        await client.repositories.connection.execute(r'UPDATE starboard_entries SET total= $1 WHERE id= $2;', parameters: [count, entryId]);
        await msg.edit(MessageUpdateBuilder(content: content, embeds: [embed]));
      } on HttpResponseError catch (e) {
        if (e.statusCode case final code when code >= 400 && code < 500) {
          await client.repositories.connection.execute(r'DELETE FROM starboard_entries WHERE id= $1;', parameters: [entryId]);
        }
      }
    }
  }

  Future<void> _onReactionRemove(MessageReactionRemoveEvent event) async {
    if (event.guild == null) {
      return;
    }

    if (!_loadedGuilds.contains(event.guild!.id)) {
      return;
    }

    final user = await event.user.get();

    if (user.isBot) {
      return;
    }

    final channel = await event.channel.get();
    final message = await event.message.get();

    if (channel case Thread() || GuildTextChannel()) {
      await _unstarMessage(channel as GuildTextChannel, message, user);
    }
  }

  Future<void> _onReactionAdd(MessageReactionAddEvent event) async {
    if (event.guild == null) {
      return;
    }

    if (!_loadedGuilds.contains(event.guild!.id)) {
      return;
    }

    final user = await event.user.get();

    if (user.isBot) {
      return;
    }

    final channel = await event.channel.get();
    final message = await event.message.get();

    if (channel case Thread() || GuildTextChannel()) {
      await _starMessage(channel as GuildChannel, message, user, event.emoji);
    }
  }

  int _gradientColor(int stars) {
    double percentage = (stars / 13).clamp(0, 1).toDouble();

    int r = 255, g = ((194 * percentage) + (253 * (1 - percentage))).toInt(), b = ((12 * percentage) + 247 * (1 - percentage)).toInt();

    return (r << 16) + (g << 8) + b;
  }

  Future<(String, EmbedBuilder)> _getStarboardEmbed(Message message, int stars, Emoji emoji) async {
    final content = '${emoji.string} **$stars** ${message.channel.mention} ID: ${message.id}';

    final embed = EmbedBuilder(description: message.content, color: DiscordColor(_gradientColor(stars)));

    if (message.embeds.isNotEmpty) {
      final em = message.embeds.first;
      if (em.url case Uri url when em.type == EmbedType.image) {
        embed.image = EmbedImageBuilder(url: url);
      }
    }

    if (message.attachments.isNotEmpty) {
      final attachment = message.attachments.first;
      if (['.png', '.jpg', '.jpeg', '.gif', '.webp'].any((e) => attachment.fileName.toLowerCase().endsWith(e))) {
        embed.image = EmbedImageBuilder(url: attachment.url);
      }
    }

    final ref = message.reference;

    if (ref != null && ref.messageId != null) {
      final msg = await ref.message!.get();
      embed.addField(name: 'Replying to...', value: '[${msg.author.username}](${await msg.url})');
    }

    embed.author = EmbedAuthorBuilder(name: message.author.username, iconUrl: message.author.avatar?.url);
    embed.timestamp = message.timestamp;

    return (content, embed);
  }
}
