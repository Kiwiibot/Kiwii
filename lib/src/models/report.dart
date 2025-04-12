import 'package:nyxx/nyxx.dart';
import 'package:option/option.dart';

import '../moderation/reports/create_report.dart';

class CreateReport {
  final Snowflake guildId;
  final Snowflake targetId;
  final String targetTag;
  final Snowflake authorId;
  final String authorTag;
  final Snowflake? modId;
  final String? modTag;
  final String? reason;
  final String? attachmentUrl;
  final Snowflake? logPostId;
  final int? refId;
  final List<Snowflake>? contextMessageIds;
  final int? type;
  final int? status;
  final Snowflake? messageId;
  final Snowflake? channelId;

  const CreateReport({
    required this.guildId,
    required this.targetId,
    required this.targetTag,
    required this.authorId,
    required this.authorTag,
    this.modId,
    this.modTag,
    this.reason,
    this.attachmentUrl,
    this.logPostId,
    this.refId,
    this.contextMessageIds,
    this.type,
    this.status,
    this.messageId,
    this.channelId,
  });

  Map<String, Object?> toRow() {
    return {
      'guild_id': guildId.value,
      'target_id': targetId.value,
      'target_tag': targetTag,
      'author_id': authorId.value,
      'author_tag': authorTag,
      'mod_id': modId?.value,
      'mod_tag': modTag,
      'reason': reason,
      'attachment_url': attachmentUrl,
      'log_post_id': logPostId?.value,
      'ref_id': refId,
      'context_messages_ids': contextMessageIds?.map((id) => id.value).toList(),
      'type': type,
      'status': status,
      'message_id': messageId?.value,
      'channel_id': channelId?.value,
    };
  }
}

class UpdateReport {
  final int reportId;
  final Snowflake guildId;
  final Option<String?> reason;
  final Option<Snowflake?> modId;
  final Option<String?> modTag;
  final Option<Snowflake?> logPostId;
  final Option<int?> refId;
  final Option<List<Snowflake>?> contextMessageIds;
  final Option<int?> type;
  final Option<int?> status;
  final Option<Snowflake?> messageId;
  final Option<Snowflake?> channelId;

  UpdateReport({
    required this.reportId,
    required this.guildId,
    this.reason = const None(),
    this.modId = const None(),
    this.modTag = const None(),
    this.logPostId = const None(),
    this.refId = const None(),
    this.contextMessageIds = const None(),
    this.type = const None(),
    this.status = const None(),
    this.messageId = const None(),
    this.channelId = const None(),
  });

  Map<String, Option<Object?>> toRow() => {
    'report_id': Some(reportId),
    'guild_id': Some(guildId.value),
    'reason': reason,
    'mod_id': modId.map((i) => i?.value),
    'mod_tag': modTag,
    'log_post_id': logPostId.map((i) => i?.value),
    'ref_id': refId,
    'context_messages_ids': contextMessageIds.map((ids) => ids?.map((id) => id.value).toList()),
    'type': type,
    'status': status,
    'message_id': messageId.map((id) => id?.value),
    'channel_id': channelId.map((id) => id?.value),
  };
}

class Report {
  final Snowflake guildId;
  final int reportId;
  final ReportType? type;
  final ReportStatus? status;
  final Snowflake? messageId;
  final Snowflake? channelId;
  final Snowflake targetId;
  final String targetTag;
  final Snowflake authorId;
  final String authorTag;
  final Snowflake? modId;
  final String? modTag;
  final String? reason;
  final String? attachmentUrl;
  final Snowflake? logPostId;
  final int? refId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Snowflake>? contextMessageIds;

  const Report({
    required this.guildId,
    required this.reportId,
    this.type,
    this.status,
    this.messageId,
    this.channelId,
    required this.targetId,
    required this.targetTag,
    required this.authorId,
    required this.authorTag,
    this.modId,
    this.modTag,
    this.reason,
    this.attachmentUrl,
    this.logPostId,
    this.refId,
    required this.createdAt,
    this.updatedAt,
    this.contextMessageIds,
  });

  factory Report.fromRow(Map<String, Object?> row) => Report(
    guildId: Snowflake.parse(row['guild_id']!),
    reportId: row['report_id'] as int,
    type: row['type'] != null ? ReportType.values[row['type'] as int] : null,
    status: row['status'] != null ? ReportStatus.values[row['status'] as int] : null,
    messageId: row['message_id'] != null ? Snowflake.parse(row['message_id']!) : null,
    channelId: row['channel_id'] != null ? Snowflake.parse(row['channel_id']!) : null,
    targetId: Snowflake.parse(row['target_id']!),
    targetTag: row['target_tag'] as String,
    authorId: Snowflake.parse(row['author_id']!),
    authorTag: row['author_tag'] as String,
    modId: row['mod_id'] != null ? Snowflake.parse(row['mod_id']!) : null,
    modTag: row['mod_tag'] as String?,
    reason: row['reason'] as String?,
    attachmentUrl: row['attachment_url'] as String?,
    logPostId: row['log_post_id'] != null ? Snowflake.parse(row['log_post_id']!) : null,
    refId: row['ref_id'] as int?,
    createdAt: row['created_at'] as DateTime,
    updatedAt: row['updated_at'] as DateTime?,
    contextMessageIds: row['context_messages_ids'] != null ? (row['context_messages_ids'] as List).map((id) => Snowflake.parse(id)).toList() : null,
  );

  Report copyWith({
    Snowflake? guildId,
    int? reportId,
    ReportType? type,
    ReportStatus? status,
    Snowflake? messageId,
    Snowflake? channelId,
    Snowflake? targetId,
    String? targetTag,
    Snowflake? authorId,
    String? authorTag,
    Option<Snowflake?> modId = const None(),
    Option<String?> modTag = const None(),
    Option<String?> reason = const None(),
    Option<String?> attachmentUrl = const None(),
    Option<Snowflake?> logPostId = const None(),
    Option<int?> refId = const None(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Option<List<Snowflake>?> contextMessageIds = const None(),
  }) => Report(
    guildId: guildId ?? this.guildId,
    reportId: reportId ?? this.reportId,
    type: type ?? this.type,
    status: status ?? this.status,
    messageId: messageId ?? this.messageId,
    channelId: channelId ?? this.channelId,
    targetId: targetId ?? this.targetId,
    targetTag: targetTag ?? this.targetTag,
    authorId: authorId ?? this.authorId,
    authorTag: authorTag ?? this.authorTag,
    modId: modId.unwrapOr(this.modId),
    modTag: modTag.unwrapOr(this.modTag),
    reason: reason.unwrapOr(this.reason),
    attachmentUrl: attachmentUrl.unwrapOr(this.attachmentUrl),
    logPostId: logPostId.unwrapOr(this.logPostId),
    refId: refId.unwrapOr(this.refId),
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    contextMessageIds: contextMessageIds.unwrapOr(this.contextMessageIds),
  );
}

class DeleteReport {
  final Snowflake guildId;
  final int reportId;
  final Snowflake? targetId;
  final String? targetTag;
  final Snowflake? modId;
  final String? modTag;
  final String? reason;

  const DeleteReport({required this.guildId, required this.reportId, this.targetId, this.targetTag, this.modId, this.modTag, this.reason});
}
