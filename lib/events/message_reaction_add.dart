import 'package:nyxx/nyxx.dart';
import 'package:option/option.dart';

import '../kiwii.dart';
import '../src/models/report.dart';
import '../src/moderation/replies/acknowledge_report.dart';
import '../src/moderation/reports/create_report.dart';
import '../src/moderation/reports/update_report.dart';

const x = '❌';
const wastebasket = '🗑️';
const greenCircle = '🟢';

Future<void> onMessageReactionAdd(MessageReactionAddEvent event) async {
  final client = event.channel.manager.client;
  final channel = await event.channel.get() as GuildTextChannel;

  final guildSettings = await client.repositories.guilds.getOrNull(event.guildId!);

  if (guildSettings?.reportChannelId == null) {
    return;
  }

  if (channel.id != guildSettings!.reportChannelId) {
    return;
  }

  if (![x, wastebasket, greenCircle].contains(event.emoji.name)) {
    return;
  }

  final op = switch (event.emoji.name) {
    x => ReportStatus.denied,
    wastebasket => ReportStatus.spam,
    greenCircle => ReportStatus.approved,
    _ => null,
  };

  if (op == null) {
    return;
  }

  final rawReport = await client.repositories.connection
      .execute(r'SELECT * FROM reports WHERE log_post_id = $1 AND guild_id = $2;', parameters: [event.messageId.value, event.guildId!.value])
      .then((r) => r.singleOrNull);

  if (rawReport == null) {
    return;
  }

  var report = Report.fromRow(rawReport.toColumnMap());

  report = await updateReport(UpdateReport(reportId: report.reportId, guildId: report.guildId, status: Some(op)));

  await acknowledgeReport(await event.guild!.get(), report);
}
