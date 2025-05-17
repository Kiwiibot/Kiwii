import 'package:nyxx/nyxx.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:option/option.dart';

import '../../moderation/replies/acknowledge_report.dart';
import '../../moderation/reports/create_report.dart';
import '../../moderation/reports/update_report.dart';
import '../report.dart';
import 'repositories.dart';

class ReportRepository extends Repository {
  ReportRepository({required super.connection});

  Future<Report> create(CreateReport report) => createReport(report);

  Future<Report> update(UpdateReport report) => updateReport(report);

  Future<List<Report>> resolvePendingReports(Guild guild, Snowflake targetId, int caseId, User moderator) async {
    final pendingReports = await connection
        .execute(
          r'SELECT * FROM reports WHERE guild_id = $1 AND status = $2 AND target_id = $3 ORDER BY created_at ASC;',
          parameters: [guild.id.value, ReportStatus.pending.index, targetId.value],
        )
        .then((r) => r.map((e) => Report.fromRow(e.toColumnMap())));

    for (final report in pendingReports) {
      final updatedReport = await updateReport(
        UpdateReport(
          reportId: report.reportId,
          guildId: guild.id,
          refId: Some(caseId),
          status: Some(ReportStatus.approved),
          modId: Some(moderator.id),
          modTag: Some(moderator.tag),
        ),
      );

      await acknowledgeReport(guild, updatedReport);
    }

    return pendingReports.toList();
  }

  Future<Report?> getPendingReportByTarget(Snowflake guildId, Snowflake userId) async {
    final rawReport = await connection
        .execute(
          r'SELECT * FROM reports WHERE guild_id = $1 AND target_id = $2 AND status = $3 ORDER BY created_at DESC LIMIT 1;',
          parameters: [guildId.value, userId.value, ReportStatus.pending.index],
        )
        .then((r) => r.singleOrNull);

    if (rawReport == null) {
      return null;
    }

    return Report.fromRow(rawReport.toColumnMap());
  }

  Future<Report?> get(Snowflake guildId, int reportId) async {
    return connection
        .execute(r'SELECT * FROM reports WHERE guild_id = $1 AND report_id = $2;', parameters: [guildId.value, reportId])
        .then((r) => r.singleOrNull == null ? null : Report.fromRow(r.single.toColumnMap()));
  }
}
