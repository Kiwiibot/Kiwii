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

import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:diff_match_patch/diff_match_patch.dart';

import '../database.dart';
import '../plugins/localization.dart';
import '../utils/utils.dart';
import '../utils/extensions.dart';
import 'message_create.dart';

Future<void> onMessageDelete(MessageDeleteEvent event) async {
  final db = GetIt.I.get<AppDatabase>();
  final self = await event.gateway.client.user.get();

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

  final logWebhookId = (await db.getGuildOrNull(event.guildId!))?.guildLogWebhookId ?? const Snowflake(1250365441470103573);

  // if (logWebhookId == null) {
  //   return;
  // }

  // todo: ignore channels

  final webhook = await event.gateway.client.webhooks.get(logWebhookId);

  final parts = [
    guild.t.logs.guildLogs.messageDeleted.channel(channel: '${channel.mention} - ${channel.name} (${channel.id})'),
  ];

  final embed = EmbedBuilder(
    author: EmbedAuthorBuilder(
      name: '${author.tag} (${author.id})',
      iconUrl: author.avatar.url,
    ),
    title: guild.t.logs.guildLogs.messageDeleted.title,
    color: const DiscordColor(0xb75cff),
    description: message.content.isEmpty ? 'No content' : message.content,
    footer: EmbedFooterBuilder(
      text: message.id.toString(),
    ),
    timestamp: event.id.timestamp,
  );

  if (message.content.isEmpty && message.embeds.isNotEmpty) {
    parts.add('Embeds: ${message.embeds.length}');
  }

  List<AttachmentBuilder> attachments = [];

  if (message.attachments.isNotEmpty) {
    final data = message.attachments.indexed.map((e) => (e.$1, e.$2.proxiedUrl, e.$2.fileName, e.$2.description, e.$2.id));

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

    // final oldUrls = message.attachments.map((e) => e.proxiedUrl);
  }

  EmbedBuilder makeEmbed(AttachmentBuilder attachment, bool first) {
    final url = first ? channel.url : channel.url.replace(queryParameters: {'somerandomstring': 'toseparateimages'});

    return EmbedBuilder(
      color: DiscordColor(0xb75cff),
      image: EmbedImageBuilder(url: Uri.parse('attachment://${attachment.fileName}')),
      url: url,
    );
  }

  embed.addField(
    name: '\u200b',
    value: parts.join('\n'),
  );

  final attachedImages = attachments.where((a) => isImage(a.data));

  final shouldAttachImages = 1 == 1;

  final payload = MessageBuilder(
    embeds: [embed, if (shouldAttachImages) ...attachedImages.indexed.map((a) => makeEmbed(a.$2, a.$1 < 4))],
    attachments: attachments,
  );

  final msg = await webhook.execute(
    payload,
    token: webhook.token!,
    username: self.username,
    avatarUrl: self.avatar.url.toString(),
    wait: true,
  ) as Message;

  final newEmbed = msg.embeds.first.toEmbedBuilder();

  if (msg.attachments.isNotEmpty) {
    final urls = msg.attachments.map((a) => a.proxiedUrl);

    newEmbed.fields![1] = EmbedFieldBuilder(
      name: guild.t.logs.guildLogs.messageDeleted.attachments.title,
      value: guild.t.logs.guildLogs.messageDeleted.attachments.value(
        attachments: [
          for (final (i, attachment) in urls.indexed) '[${i + 1}]($attachment)',
        ].join(' '),
      ),
      isInline: false,
    );
  }

  final builder = MessageUpdateBuilder(
    embeds: [
      newEmbed,
      ...msg.embeds.sublist(1).map((e) => e.toEmbedBuilder()),
    ],
    content: msg.content,
    attachments: attachments,
    suppressEmbeds: msg.flags.has(
      MessageFlags.suppressEmbeds,
    ),
  );

  await message.edit(builder);
}

bool isImage(List<int> data) {
  final header = data.sublist(0, 4).map((d) => d.toRadixString(16)).join();

  // Only gifs, pngs, and jpegs are displayed as images in Discord.
  return switch (header) {
    '89504e47' /* image/gif */ => true,
    '47494638' /* image/png */ => true,
    'ffd8ffe0' || 'ffd8ffe1' || 'ffd8ffe2' || 'ffd8ffe3' || 'ffd8ffe8' /* image/jpeg */ => true,
    _ => false,
  };
}

final cbRegex = RegExp(r'```(?:.*?)```', dotAll: true);

Future<void> onMessageUpdate(MessageUpdateEvent event) async {
  final oldMessage = event.oldMessage;
  final newMessage = await event.message.get();

  if (oldMessage == null) {
    return;
  }

  if (newMessage.author case WebhookAuthor() || User(isBot: true)) {
    return;
  }

  if (newMessage.content == oldMessage.content) {
    return;
  }

  final db = GetIt.I.get<AppDatabase>();

  // final guild = await event.guild!.get();

  final logWebhookId = (await db.getGuild(event.guildId!)).guildLogWebhookId ?? const Snowflake(1250365441470103573);

  // if (logWebhookId == null) {
  //   return;
  // }

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

      final prefix = d.operation == DIFF_DELETE
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
      final wrapper = d.operation == DIFF_INSERT
          ? '**'
          : d.operation == DIFF_DELETE
              ? '~~'
              : '';
      sb.write('$wrapper${d.text}$wrapper');
    }
  }

  final embed = EmbedBuilder(
    author: EmbedAuthorBuilder(
      name: '${(newMessage.author as User).tag} (${newMessage.author.id})',
      iconUrl: newMessage.author.avatar!.url,
    ),
    color: DiscordColor(0xcfc),
    footer: EmbedFooterBuilder(
      text: newMessage.id.toString(),
    ),
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
