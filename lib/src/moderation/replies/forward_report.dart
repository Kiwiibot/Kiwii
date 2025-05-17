import 'dart:typed_data';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:option/option.dart';

import '../../../plugins/localization.dart';
import '../../../utils/extensions.dart';
import '../../errors/errors.dart';
import '../../models/report.dart';
import '../reports/update_report.dart';
import 'acknowledge_report.dart';

Future<Uri?> forwardReport(({User author, String reason}) data, Guild guild, /* Message|Attachment */ dynamic payload, Report report) async {
  final reportChannelId = (await guild.manager.client.repositories.guilds.get(guild.id)).reportChannelId;

  if (reportChannelId == null) {
    throw NoReportChannelException();
  }

  final thread = await guild.manager.client.channels.get(report.logPostId!) as Thread;

  final embeds = <EmbedBuilder>[];

  Uint8List? fetchedAttachment;

  if (payload is Message) {
    await updateReport(UpdateReport(reportId: report.reportId, guildId: guild.id, contextMessageIds: Some([...?report.contextMessageIds, payload.id])));

    embeds.add(await formatMessageToEmbed(payload, guild.t));
  } else {
    payload as Attachment;
    fetchedAttachment = await payload.fetch();
    embeds.add(EmbedBuilder(image: EmbedImageBuilder(url: Uri.parse('attachment://${payload.fileName}')), color: const DiscordColor(0x2f3136)));
  }

  final s =
      guild.t['logs.guildLogs.reportLog.forward.${payload is Message ? 'message' : 'user'}']
          as String Function({required String author, required String reason});

  final m = await thread.sendMessage(
    MessageBuilder(
      content: s(author: '${userMention(data.author.id)} - ${inlineCode(data.author.tag)} (${data.author.id})', reason: inlineCode(data.reason)),
      embeds: embeds,
      components:
          payload is Message
              ? [
                ActionRowBuilder(components: [ButtonBuilder.link(url: await payload.url, label: guild.t.general.common.messageReference)]),
              ]
              : [],
      allowedMentions: AllowedMentions(parse: []),
      attachments: [
        if (payload is Attachment && fetchedAttachment != null) AttachmentBuilder(data: fetchedAttachment, fileName: payload.fileName.toLowerCase()),
      ],
    ),
  );

  if (payload is Attachment && fetchedAttachment != null) {
    return m.embeds.lastOrNull?.image?.proxiedUrl;
  }

  return null;
}
