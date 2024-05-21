import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../../../database.dart' hide Guild;
import '../../../kiwii.dart';
import '../reports/create_report.dart';

Future<Thread> acknowledgeReport(Guild guild, Report report, [Message? message, List<Message>? messages]) async {
  final db = GetIt.I.get<AppDatabase>();
  final client = guild.manager.client as NyxxGateway;

  final guildSettings = await db.getGuild(guild.id);

  final reportForum = client.channels.cache[report.channelId] as ForumChannel?;
  final reportStatusTags = guildSettings.reportStatusTags;
  final reportTypeTags = guildSettings.reportTypeTags;
  var localMessage = message;

  try {
    if (localMessage == null && report.messageId != null) {
      localMessage = await (await client.channels.get(report.channelId!) as TextChannel).messages.fetch(report.messageId!);
    }
  } catch (_) {}

  final author = await client.users.get(report.authorId!);

  final embeds = [await generateReportEmbed(author, report, guildSettings.modLogChannelId!, localMessage)];

  // if (localMessage.)
  // TODO: Other embeds

  final statusTag = reportStatusTags[report.status!.index];
  final typeTag = reportTypeTags[report.type!.index];

  var reportPost = await client.channels.get(report.logPostId ?? Snowflake.zero).silentCatchAsNull() as Thread?;

  if (reportPost == null) {
    reportPost = await reportForum!.createForumThread(ForumThreadBuilder(
      name: 'Reported aaa',
      message: MessageBuilder(content: 'TODO'),
      appliedTags: [typeTag, statusTag],
    ));

    await db.updateReport(
      report.copyWith(
        logPostId: Value(reportPost.id),
      ),
    );

    return reportPost;
  }

  final shouldUpdateTags = [statusTag, typeTag].any((re) => !reportPost!.appliedTags!.contains(re));

  if (reportPost.isArchived || shouldUpdateTags) {
    await reportPost.update(
      ThreadUpdateBuilder(
        isArchived: false,
        appliedTags: [typeTag, statusTag],
      )
    );
  }

  final start = await reportPost.messages.fetch(reportPost.id);
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
    author: EmbedAuthorBuilder(
      name: '${user.tag} (${user.id})',
      iconUrl: user.avatar.url,
    ),
    color: DiscordColor(statusToColour(report.status!)),
    description: await generateReportLog(report, modChannelId),
    footer: report.status == ReportStatus.pending ? EmbedFooterBuilder(text: 'Pending') : null,
  );

  if (report.attachmentUrl != null) {
    embed.image = EmbedImageBuilder(url: Uri.parse(report.attachmentUrl!));
  }

  return embed;
}

Future<String> generateReportLog(Report report, Snowflake modChannelId, [Message? message]) async {
  final db = GetIt.I.get<AppDatabase>();

  final parts = [
    '**Reported User:** ${userMention(report.targetId!)} - `${report.targetTag}` (${report.targetId})',
    '**Reason:** ${codeBlock(cutText(report.reason!.trim(), 3000))}',
  ];

  if (message != null || report.messageId != null) {
    parts.add(
      '**Message:** ${message != null ? hyperlink('Go to message', (await message.url).toString()) : '[Message Deleted]'} ${channelMention(report.channelId!)}',
    );
  }

  if (report.refId != null) {
    final references = await (db.cases.select()..where((e) => e.guildId.equalsValue(report.guildId) & e.caseId.equals(report.refId!))).getSingle();
    parts.add('**Reference:** [Case #${references.caseId}](https://discord.com/channels/${report.guildId}/$modChannelId/${references.logMessageId})');
  }

  parts.add('**Status**: ${report.status!.name.capitalize}');

  if (report.modId != null && report.modTag != null) {
    parts.add('**Moderator:** ${userMention(report.modId!)} - `${report.modTag}` (${report.modId})');
  }

  return parts.join('\n');
}
