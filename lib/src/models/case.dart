import 'package:nyxx/nyxx.dart';

import '../moderation/case/create_case.dart';

class UpdateCase {
  final String? reason;
  final Snowflake? guildId;
  final int? refId;
  final DateTime? actionExpiration;
  final int? appealRefId;
  final int? caseId;
  final Snowflake? contextMessageId;
  final int? reportRefId;

  const UpdateCase({
    this.reason,
    this.guildId,
    this.refId,
    this.actionExpiration,
    this.appealRefId,
    this.caseId,
    this.contextMessageId,
    this.reportRefId,
  });
}

class CreateCase {
  final Snowflake guildId;
  final CaseAction action;
  final Duration? duration;
  final bool? multi;
  final Snowflake? roleId;
  final String? reason;
  final Snowflake? modId;
  final String? modTag;
  final Snowflake targetId;
  final String targetTag;
  final Snowflake? contextMessageId;
  final int? reportRefId;
  final int? appealRefId;
  final int? refId;

  const CreateCase({
    required this.guildId,
    required this.action,
    required this.targetId,
    required this.targetTag,
    this.roleId,
    this.reason,
    this.modId,
    this.modTag,
    this.contextMessageId,
    this.multi,
    this.reportRefId,
    this.appealRefId,
    this.duration,
    this.refId,
  });

  DateTime? get actionExpiration => duration != null ? DateTime.now().add(duration!) : null;
}

class DeleteCase {
  final Snowflake guildId;
  final Snowflake? targetId;
  final String? targetTag;
  final CaseAction? action;
  final int? caseId;
  final int? reportRefId;
  final int? appealRefId;
  final String? reason;
  final String? modTag;
  final Snowflake? modId;

  const DeleteCase({
    required this.guildId,
    this.caseId,
    this.targetId,
    this.action,
    this.reportRefId,
    this.appealRefId,
    this.reason,
    this.modTag,
    this.modId,
    this.targetTag,
  });
}
