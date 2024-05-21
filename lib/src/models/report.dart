import 'package:nyxx/nyxx.dart';

import '../moderation/reports/create_report.dart';

class UpdateReport {
  final String? reason;
  final Message? message;
  final Snowflake? guildId;
  final int? refId;
  final ReportStatus? status;
  final String? attachmentUrl;
  final List<Snowflake>? contextMessagesIds;
  final int? reportId;

  const UpdateReport({
    this.reason,
    this.message,
    this.guildId,
    this.refId,
    this.status,
    this.attachmentUrl,
    this.contextMessagesIds,
    this.reportId,
  });
}
