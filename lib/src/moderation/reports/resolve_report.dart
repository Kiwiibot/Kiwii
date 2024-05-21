import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';

import '../../../database.dart' hide Guild;
import '../../models/report.dart';
import '../replies/acknowledge_report.dart';
import 'create_report.dart';
import 'update_report.dart';

Future<List<Report>> resolvePendingReports(Guild guild, Snowflake targetId, int caseId, User moderator) async {
  final db = GetIt.I.get<AppDatabase>();

  final pendingReports = await (db.reports.select()
        ..where((e) => e.guildId.equalsValue(guild.id) & e.status.equalsValue(ReportStatus.pending) & e.targetId.equalsValue(targetId))
        ..orderBy(
          [
            (u) => OrderingTerm(
                  expression: u.createdAt,
                )
          ],
        ))
      .get();

  for (final report in pendingReports) {
    try {
      final updatedReport = await updateReport(
        UpdateReport(
          guildId: guild.id,
          reportId: report.reportId,
          refId: caseId,
          status: ReportStatus.approved,
        ),
        moderator,
      );

      await acknowledgeReport(guild, updatedReport);
    } catch (e) {
      // TODO: Handle error
    }
  }

  return pendingReports;
}
