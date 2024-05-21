import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';

import '../../../database.dart' hide Guild;
import '../../models/report.dart';
import '../../../utils/extensions.dart';

Future<Report> updateReport(UpdateReport report, [User? moderator]) async {
  final db = GetIt.I.get<AppDatabase>();

  final currentReport = await db.getReport(report.reportId!, report.guildId!);

  final updates = currentReport.copyWith(
    status: Value(report.status),
    attachmentUrl: Value(report.attachmentUrl),
    reason: Value(report.reason),
    messageId: Value(report.message?.id),
    channelId: Value(report.message?.channel.id),
    refId: Value(report.refId),
    modId: Value(moderator?.id),
    modTag: Value(moderator?.tag),
    contextMessagesIds: Value(report.contextMessagesIds),
  );

  return db.updateReport(updates);
}
