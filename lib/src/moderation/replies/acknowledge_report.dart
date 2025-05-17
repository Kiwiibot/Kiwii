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

import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart' hide Connection;
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:postgres/postgres.dart';

import '../../../kiwii.dart';
import '../../../plugins/localization.dart';
import '../../../translations.g.dart';
import '../../../utils/ansi.dart';
import '../../../utils/extensions/iterable.dart';
import '../../models/case.dart';
import '../../models/report.dart';
import '../reports/create_report.dart';
import '../utils/generate.dart';

Future<Thread> acknowledgeReport(Guild guild, Report report, [Message? message, List<Message>? messages]) async {
  final client = guild.manager.client as NyxxGateway;

  final guildSettings = await client.repositories.guilds.get(guild.id);

  final reportChannel = await client.channels.get(guildSettings.reportChannelId!) as GuildTextChannel;
  var localMessage = message;

  try {
    if (localMessage == null && report.messageId != null) {
      localMessage = await (await client.channels.get(report.channelId!) as TextChannel).messages.get(report.messageId!);
    }
  } catch (_) {}

  final author = await client.users.get(report.authorId);

  final embeds = [await generateReportEmbed(author, report, guildSettings.modLogChannelId!, localMessage)];

  if ((await localMessage?.channel.get()) case GuildTextChannel()) {
    embeds.add(await formatMessageToEmbed(localMessage!, guild.t));
  }

  if (report.type == ReportType.user) {
    final member = await guild.members[report.targetId].getOrNull();
    final user = member?.user ?? await client.users.get(report.targetId);

    embeds.add(generateUserInfo((member: member, user: user), t));
  }

  final localMessageChannel = await localMessage?.channel.get();

  var reportPost = await client.channels.get(report.logPostId ?? Snowflake.zero).silentCatchAsNull() as Thread?;

  if (reportPost == null) {
    final message = await reportChannel.messages.create(
      MessageBuilder(
        components: [
          if (localMessageChannel is GuildTextChannel)
            ActionRowBuilder(components: [ButtonBuilder.link(url: await localMessage!.url, label: t.general.common.messageReference)]),
        ],
        embeds: embeds,
        attachments: [
          if (messages != null && localMessage != null)
            AttachmentBuilder(
              data: utf8.encode(
                await formatMessagesToString(
                  messages,
                  t,
                  primaryHighlightMessageIds: [localMessage.id],
                  secondaryHighlightMessageIds: messages.where((m) => m.author.id == report.targetId).map((m) => m.id).toList(),
                ),
              ),
              fileName: 'messagecontext.ansi',
            ),
        ],
      ),
    );

    reportPost = await reportChannel.createThreadFromMessage(
      message.id,
      ThreadFromMessageBuilder(name: guild.t.moderation.report.post.name(reportId: report.reportId, user: '${report.targetTag} (${report.targetId})')),
    );

    await client.repositories.connection.execute(
      r'UPDATE reports SET log_post_id = $1 WHERE guild_id = $2 AND report_id = $3',
      parameters: [message.id.value, report.guildId.value, report.reportId],
    );

    return reportPost;
  }

  final start = await (await client.channels.get(guildSettings.reportChannelId!) as GuildTextChannel).messages.fetch(report.logPostId!);
  await start.update(MessageUpdateBuilder(embeds: embeds));

  if (report.status != ReportStatus.pending) {
    await reportPost.update(ThreadUpdateBuilder(isArchived: true));
  }

  return reportPost;
}

int statusToColour(ReportStatus status) => switch (status) {
  ReportStatus.pending => 0x5865f2,
  ReportStatus.approved => 0x57f287,
  ReportStatus.denied => 0xed4245,
  ReportStatus.spam => 0xf0b330,
};

Future<EmbedBuilder> generateReportEmbed(User user, Report report, Snowflake modChannelId, [Message? message]) async {
  final embed = EmbedBuilder(
    author: EmbedAuthorBuilder(name: '${user.tag} (${user.id})', iconUrl: user.avatar.url),
    color: DiscordColor(statusToColour(report.status!)),
    description: await generateReportLog(report, modChannelId, message),
    footer: report.status == ReportStatus.pending ? EmbedFooterBuilder(text: 'Pending') : null,
    timestamp: report.createdAt,
  );

  if (report.attachmentUrl != null) {
    embed.image = EmbedImageBuilder(url: Uri.parse(report.attachmentUrl!));
  }

  return embed;
}

Future<String> generateReportLog(Report report, Snowflake modChannelId, [Message? message]) async {
  final connection = GetIt.I.get<Connection>();

  final parts = [
    '**Reported User:** ${userMention(report.targetId)} - `${report.targetTag}` (${report.targetId})',
    '**Reason:** ${codeBlock(cutText(report.reason!.trim(), 3000))}',
  ];

  if (message != null || report.messageId != null) {
    parts.add(
      '**Message:** ${message != null ? hyperlink('Go to message', (await message.url).toString()) : '[Message Deleted]'} ${channelMention(report.channelId!)}',
    );
  }

  if (report.refId != null) {
    final references = await connection
        .execute(r'SELECT * FROM cases WHERE guild_id = $1 AND case_id = $2', parameters: [report.guildId.value, report.refId!])
        .then((r) => Case.fromRow(r.single.toColumnMap()));
    parts.add('**Reference:** [Case #${references.caseId}](https://discord.com/channels/${report.guildId}/$modChannelId/${references.logMessageId})');
  }

  parts.add('**Status**: ${report.status!.name.capitalize}');

  if (report.modId != null && report.modTag != null) {
    parts.add('**Moderator:** ${userMention(report.modId!)} - `${report.modTag}` (${report.modId})');
  }

  return parts.join('\n');
}

Future<EmbedBuilder> formatMessageToEmbed(Message message, Translations t) async {
  final embed = EmbedBuilder(
    author: EmbedAuthorBuilder(
      name: '${message.author is User ? (message.author as User).tag : message.author.username} (${message.author.id})',
      iconUrl: message.author.avatar?.url,
    ),
    description: message.content.isEmpty ? t.general.common.noContent : message.content,
    color: const DiscordColor(0x2f3136),
    timestamp: message.createdAt,
    footer: EmbedFooterBuilder(text: '#${(await message.channel.get() as GuildTextChannel).name}'),
  );

  final attachment = message.attachments.firstOrNull;
  final attachmentIsImage = ['image/jpeg', 'image/gif', 'image/png', 'image/webp'].contains(attachment?.contentType ?? '');
  final attachmentIsImageNaive = ['.jpg', '.jpeg', '.webp', '.gif'].any((e) => attachment?.fileName.endsWith(e) ?? false);

  if (attachment != null && (attachmentIsImage || attachmentIsImageNaive)) {
    embed.image = EmbedImageBuilder(url: attachment.url);
  }

  return embed;
}

Future<String> formatMessagesToString(
  List<Message> messages,
  Translations t, {
  List<Snowflake> primaryHighlightMessageIds = const [],
  List<Snowflake> secondaryHighlightMessageIds = const [],
}) => messages
    .mapAsync((message) async {
      final isPrimaryHighlight = primaryHighlightMessageIds.contains(message.id);
      final isSecondaryHighlight = secondaryHighlightMessageIds.contains(message.id);

      final outParts = [
        t.logs.guildLogs.messageBulkDeleted.logPreamble(
          createdAt: message.createdAt,
          authorTag: message.author.tag,
          authorId: message.author.id,
          content: message.content.replaceAll('\n', ' '),
        ),
      ];

      if (message.attachments.isNotEmpty) {
        outParts.add(message.attachments.map((attachment) => t.logs.guildLogs.messageBulkDeleted.attachment(url: attachment.proxiedUrl)).join('\n'));
      }

      if (message.stickers.isNotEmpty) {
        outParts.add(message.stickers.map((sticker) => t.logs.guildLogs.messageBulkDeleted.sticker(name: sticker.name)).join('\n'));
      }

      if (message.type == MessageType.reply && message.reference != null) {
        const mentionsKey = 'Mentions';

        final doesMentions = message.mentions.contains(message.referencedMessage?.author);

        outParts.add(
          t['logs.guildLogs.messageBulkDeleted.replyTo${doesMentions ? mentionsKey : ''}'](
            messageId: message.id,
            messageUrl: 'https://discord.com/channels/${message.channelId}/${message.id}',
            userTag: message.referencedMessage?.author.tag ?? 'Unkown Author',
            userId: message.referencedMessage?.author.id ?? 'Unknown Author',
          ),
        );
      }

      final outSection = outParts.join('\n');
      return isPrimaryHighlight
          ? ansi.red(outSection)
          : isSecondaryHighlight
          ? ansi.yellow(outSection)
          : outSection;
    })
    .then((s) => s.join('\n'));
