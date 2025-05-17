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

import 'dart:typed_data';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:diff_match_patch/diff_match_patch.dart';

import '../plugins/localization.dart';
import '../utils/utils.dart';
import '../utils/extensions.dart';
import 'message_create.dart';

Future<void> onMessageDelete(MessageDeleteEvent event) async {
  final client = event.gateway.client;
  final self = await client.user.get();

  if (event.deletedMessage == null || event.guildId == null) {
    return;
  }

  final message = event.deletedMessage!;

  final guild = await event.guild!.get();

  final channel = await message.channel.get() as GuildTextChannel;

  if (message case Message(author: User(isBot: true) || WebhookAuthor())) {
    return;
  }

  final author = message.author as User;

  if (message.content.isEmpty && message.embeds.isEmpty && message.attachments.isEmpty && message.stickers.isEmpty) {
    return;
  }

  final guildSettings = await client.repositories.guilds.getOrNull(event.guildId!);

  final logWebhookId = guildSettings?.guildLogWebhookId;

  if (logWebhookId == null) {
    return;
  }

  if (guildSettings?.logIgnoreChannels case final ignoredChannels?) {
    if (ignoredChannels.contains(channel.id)) {
      return;
    }
  }

  final webhook = await event.gateway.client.webhooks.get(logWebhookId);

  // We dont really want to keep track of deleted messages inside the logs channels.
  if (channel.id == webhook.channel?.id) {
    return;
  }

  final parts = [(guild.t.logs.guildLogs.messageDeleted.channel, '${channel.mention} - ${channel.name} (${channel.id})')];

  final embed = EmbedBuilder(
    author: EmbedAuthorBuilder(name: '${author.tag} (${author.id})', iconUrl: author.avatar.url),
    title: guild.t.logs.guildLogs.messageDeleted.title,
    color: const DiscordColor(0xb75cff),
    description: message.content.isEmpty ? 'No content' : message.content,
    footer: EmbedFooterBuilder(text: message.id.toString()),
    timestamp: event.id.timestamp,
  );

  if (message.content.isEmpty && message.embeds.isNotEmpty) {
    parts.add((guild.t.logs.guildLogs.messageDeleted.embeds, message.embeds.length.toString()));
  }

  List<AttachmentBuilder> attachments = [];

  if (message.attachments.isNotEmpty) {
    final data = message.attachments.indexed.map((e) => (e.$1, e.$2.proxiedUrl, e.$2.fileName, e.$2.description, e.$2.id));

    parts.add((guild.t.logs.guildLogs.messageDeleted.attachments.title, guild.t.logs.guildLogs.messageDeleted.attachments.value(attachments: data.length)));

    final resolvedData = await Future.sync(() async {
      final res = <(int, Uri, String, String?, Uint8List?)>[];
      for (final (i, url, fileName, description, id) in data) {
        final cachedAttachment = await attachmentsCache[id.toString()].get();

        if (cachedAttachment != null) {
          res.add((i, url, fileName, description, cachedAttachment));
        } else {
          final response = await message.manager.client.httpHandler.httpClient.get(url);

          if (response.statusCode == 200) {
            final bytes = response.bodyBytes;
            res.add((i, url, fileName, description, bytes));
          } else {
            res.add((i, url, fileName, description, null));
          }
        }
      }

      return res;
    });

    attachments = [
      for (final (_, _, f, d, data) in resolvedData)
        if (data != null)
          AttachmentBuilder(
            data: data,
            // the filename is treated as the host, and per the RFC3986, the host is case-insensitive, so Uri.parse('attachment://HelloWorld.png') returns attachment://helloworld.png.
            // and since the original filename isn't lowercase, the image is not embedded.
            fileName: f.toLowerCase(),
            description: d,
          ),
    ];
  }

  EmbedBuilder makeEmbed(AttachmentBuilder attachment, bool first) {
    final url = first ? channel.url : channel.url.replace(queryParameters: {'somerandomstring': 'toseparateimages'});

    return EmbedBuilder(color: DiscordColor(0xb75cff), image: EmbedImageBuilder(url: Uri.parse('attachment://${attachment.fileName}')), url: url);
  }

  for (final part in parts) {
    embed.addField(name: part.$1, value: part.$2);
  }

  final attachedImages = attachments.where((a) => isImage(a.data));

  final payload = MessageBuilder(embeds: [embed, ...attachedImages.indexed.map((a) => makeEmbed(a.$2, a.$1 < 4))], attachments: attachments);

  await webhook.execute(payload, token: webhook.token!, username: self.username, avatarUrl: self.avatar.url.toString());
}

bool isImage(List<int> data) {
  final header = data.sublist(0, 4).map((d) => d.toRadixString(16)).join();
  final webpIdentifierBytes = data.sublist(8, 12).map((d) => d.toRadixString(16)).join();

  // Only gifs, webps, pngs, and jpegs are displayed as images in Discord.
  return switch (header) {
    '89504e47' /* image/gif */ => true,
    '47494638' /* image/png */ => true,
    'ffd8ffe0' || 'ffd8ffe1' || 'ffd8ffe2' || 'ffd8ffe3' || 'ffd8ffe8' /* image/jpeg */ => true,
    '52494646' when webpIdentifierBytes == '57454250' /* image/webp */ => true,
    _ => false,
  };
}

final cbRegex = RegExp(r'```(?:.*?)```', dotAll: true);

Future<void> onMessageUpdate(MessageUpdateEvent event) async {
  final oldMessage = event.oldMessage;

  final client = event.gateway.client;

  if (oldMessage == null) {
    return;
  }

  Message newMessage;

  try {
    newMessage = await event.message.get();
  } on HttpResponseError {
    return;
  }

  if (newMessage.author case WebhookAuthor() || User(isBot: true)) {
    return;
  }

  if (newMessage.content == oldMessage.content) {
    return;
  }

  // final guild = await event.guild!.get();

  final logWebhookId = (await client.repositories.guilds.getOrNull(event.guildId!))?.guildLogWebhookId;

  if (logWebhookId == null) {
    return;
  }

  final webhook = await event.gateway.client.webhooks.get(logWebhookId);

  // TODO: ignore channels

  final sb = StringBuffer();

  if (cbRegex.hasMatch(oldMessage.content) && cbRegex.hasMatch(newMessage.content)) {
    final stripRegex = RegExp(r'```(?:(\S+)\n)?\s*([^]+?)\s*```');

    final oldMatch = stripRegex.firstMatch(oldMessage.content);

    if (oldMatch == null || oldMatch.group(2) == null) {
      return;
    }

    final newMatch = stripRegex.firstMatch(newMessage.content);

    if (newMatch == null || newMatch.group(2) == null) {
      return;
    }

    if (oldMatch.group(2) == newMatch.group(2)) {
      return;
    }

    final diffMessages = diff(oldMatch.group(2)!, newMatch.group(2)!);

    sb.writeln('```diff');

    for (final d in diffMessages) {
      if (d.text == '\n') {
        continue;
      }

      final prefix =
          d.operation == DIFF_DELETE
              ? '- '
              : d.operation == DIFF_INSERT
              ? '+ '
              : '';

      sb.writeln('$prefix${d.text.replaceAll('\n', '')}');
    }

    sb.writeln('```');
  } else {
    final diffMessages = diff(oldMessage.content, newMessage.content, checklines: false);

    for (final d in diffMessages) {
      final wrapper =
          d.operation == DIFF_INSERT
              ? '**'
              : d.operation == DIFF_DELETE
              ? '~~'
              : '';
      sb.write('$wrapper${d.text}$wrapper');
    }
  }

  final embed = EmbedBuilder(
    author: EmbedAuthorBuilder(name: '${(newMessage.author as User).tag} (${newMessage.author.id})', iconUrl: newMessage.author.avatar!.url),
    color: DiscordColor(0xcfc),
    footer: EmbedFooterBuilder(text: newMessage.id.toString()),
    description: sb.toString(),
    // fields: [
    // EmbedFieldBuilder(name: '\u200b', value: , isInline: isInline)
    // ]
  );

  final clientUser = await event.gateway.client.user.get();

  await webhook.execute(
    MessageBuilder(embeds: [embed]),
    token: webhook.token!,
    username: clientUser.username,
    avatarUrl: clientUser.avatar.url.toString(),
    wait: true,
  );
}
