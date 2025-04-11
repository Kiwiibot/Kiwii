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

import 'package:nyxx/nyxx.dart';
import 'package:option/option.dart';

import '../moderation/case/create_case.dart';

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
  // final DateTime? actionExpiration;

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

  DateTime? get actionExpiration => duration != null ? DateTime.now().toUtc().add(duration!) : null;

  CreateCase copyWith({
    Snowflake? guildId,
    CaseAction? action,
    Duration? duration,
    Option<bool?> multi = const None(),
    Option<Snowflake?> roleId = const None(),
    Option<String?> reason = const None(),
    Option<Snowflake?> modId = const None(),
    Option<String?> modTag = const None(),
    Snowflake? targetId,
    String? targetTag,
    Option<Snowflake?> contextMessageId = const None(),
    Option<int?> reportRefId = const None(),
    Option<int?> appealRefId = const None(),
    Option<int?> refId = const None(),
  }) => CreateCase(
    guildId: guildId ?? this.guildId,
    action: action ?? this.action,
    targetId: targetId ?? this.targetId,
    targetTag: targetTag ?? this.targetTag,
    appealRefId: appealRefId.unwrapOr(this.appealRefId),
    contextMessageId: contextMessageId.unwrapOr(this.contextMessageId),
    duration: duration ?? this.duration,
    modId: modId.unwrapOr(this.modId),
    modTag: modTag.unwrapOr(this.modTag),
    multi: multi.unwrapOr(this.multi),
    reason: reason.unwrapOr(this.reason),
    refId: refId.unwrapOr(this.refId),
    reportRefId: reportRefId.unwrapOr(this.reportRefId),
    roleId: roleId.unwrapOr(this.roleId),
  );

  Map<String, Object?> toRow() {
    return {
      'guild_id': guildId.value,
      'action': action.index,
      'action_expiration': actionExpiration,
      'action_processed': actionExpiration == null,
      'multi': multi,
      'role_id': roleId,
      'reason': reason,
      'mod_id': modId?.value,
      'mod_tag': modTag,
      'target_id': targetId.value,
      'target_tag': targetTag,
      'context_message_id': contextMessageId,
      'report_ref_id': reportRefId,
      'appeal_ref_id': appealRefId,
      'ref_id': refId,
    };
  }
}

class UpdateCase {
  final int caseId;
  final Snowflake guildId;
  final Option<String?> reason;
  final Option<Snowflake?> modId;
  final Option<String?> modTag;
  final Option<int?> refId;
  final Option<bool> actionProcessed;
  final Option<DateTime?> actionExpiration;
  final Option<int?> appealRefId;
  final Option<Snowflake?> contextMessageId;
  final Option<int?> reportRefId;
  final Option<Snowflake?> logMessageId;
  final Option<Snowflake?> logDmMessageId;

  UpdateCase({
    required this.caseId,
    required this.guildId,
    this.reason = const None(),
    this.modId = const None(),
    this.modTag = const None(),
    this.refId = const None(),
    this.actionProcessed = const None(),
    this.actionExpiration = const None(),
    this.appealRefId = const None(),
    this.contextMessageId = const None(),
    this.reportRefId = const None(),
    this.logMessageId = const None(),
    this.logDmMessageId = const None(),
  });

  Map<String, Option<Object?>> toRow() => {
    'case_id': Some(caseId),
    'guild_id': Some(guildId.value),
    'reason': reason,
    'mod_id': modId.map((i) => i?.value),
    'mod_tag': modTag,
    'ref_id': refId,
    'action_processed': actionProcessed,
    'action_expiration': actionExpiration,
    'appeal_ref_id': appealRefId,
    'report_ref_id': reportRefId,
    'context_message_id': contextMessageId,
    'log_message_id': logMessageId,
    'log_dm_message_id': logDmMessageId
  };
}

final class Case {
  final Snowflake guildId;
  final int caseId;
  final Snowflake targetId;
  final String targetTag;
  final Snowflake? modId;
  final String? modTag;
  final String? reason;
  final int? refId;
  final CaseAction action;
  final bool actionProcessed;
  final DateTime? actionExpiration;
  final DateTime createdAt;
  final Snowflake? logMessageId;
  final Snowflake? contextMessageId;
  final Snowflake? roleId;
  final bool multi;
  final int? reportRefId;
  final int? appealRefId;
  final Snowflake? logDmMessageId;

  const Case({
    required this.guildId,
    required this.caseId,
    required this.targetId,
    required this.targetTag,
    required this.action,
    required this.actionProcessed,
    required this.createdAt,
    this.logMessageId,
    this.modId,
    this.modTag,
    this.reason,
    this.refId,
    this.contextMessageId,
    this.roleId,
    this.multi = false,
    this.reportRefId,
    this.appealRefId,
    this.logDmMessageId,
    this.actionExpiration,
  });

  factory Case.fromRow(Map<String, Object?> row) => Case(
    guildId: Snowflake.parse(row['guild_id']!),
    caseId: row['case_id'] as int,
    targetId: Snowflake.parse(row['target_id']!),
    targetTag: row['target_tag'] as String,
    action: CaseAction.values[row['action'] as int],
    actionProcessed: row['action_processed'] as bool? ?? true,
    createdAt: row['created_at'] as DateTime,
    logMessageId: row['log_message_id'] != null ? Snowflake.parse(row['log_message_id']!) : null,
    modId: row['mod_id'] != null ? Snowflake.parse(row['mod_id']!) : null,
    modTag: row['mod_tag'] as String?,
    reason: row['reason'] as String?,
    refId: row['ref_id'] as int?,
    contextMessageId: row['context_message_id'] != null ? Snowflake.parse(row['context_message_id']!) : null,
    roleId: row['role_id'] != null ? Snowflake.parse(row['role_id']!) : null,
    multi: row['multi'] as bool? ?? false,
    reportRefId: row['report_ref_id'] as int?,
    appealRefId: row['appeal_ref_id'] as int?,
    logDmMessageId: row['log_dm_message_id'] != null ? Snowflake.parse(row['log_dm_message_id']!) : null,
    actionExpiration: row['action_expiration'] as DateTime?,
  );

  Case copyWith({
    Snowflake? guildId,
    int? caseId,
    Snowflake? targetId,
    String? targetTag,
    Option<Snowflake?> modId = const None(),
    Option<String?> modTag = const None(),
    Option<String?> reason = const None(),
    Option<int?> refId = const None(),
    Option<CaseAction> action = const None(),
    Option<bool> actionProcessed = const None(),
    DateTime? createdAt,
    Option<Snowflake?> logMessageId = const None(),
    Option<Snowflake?> contextMessageId = const None(),
    Option<Snowflake?> roleId = const None(),
    Option<bool> multi = const None(),
    Option<int?> reportRefId = const None(),
    Option<int?> appealRefId = const None(),
    Option<Snowflake?> logDmMessageId = const None(),
    Option<DateTime?> actionExpiration = const None(),
  }) => Case(
    guildId: guildId ?? this.guildId,
    caseId: caseId ?? this.caseId,
    targetId: targetId ?? this.targetId,
    targetTag: targetTag ?? this.targetTag,
    modId: modId.unwrapOr(this.modId),
    modTag: modTag.unwrapOr(this.modTag),
    reason: reason.unwrapOr(this.reason),
    refId: refId.unwrapOr(this.refId),
    action: action.unwrapOr(this.action),
    actionProcessed: actionProcessed.unwrapOr(this.actionProcessed),
    createdAt: createdAt ?? this.createdAt,
    logMessageId: logMessageId.unwrapOr(this.logMessageId),
    contextMessageId: contextMessageId.unwrapOr(this.contextMessageId),
    roleId: roleId.unwrapOr(this.roleId),
    multi: multi.unwrapOr(this.multi),
    reportRefId: reportRefId.unwrapOr(this.reportRefId),
    appealRefId: appealRefId.unwrapOr(this.appealRefId),
    logDmMessageId: logDmMessageId.unwrapOr(this.logDmMessageId),
    actionExpiration: actionExpiration.unwrapOr(this.actionExpiration),
  );

  UpdateCase toUpdate({
    Snowflake? guildId,
    int? caseId,
    Option<String?> reason = const None(),
    Option<Snowflake?> modId = const None(),
    Option<String?> modTag = const None(),
    Option<int?> refId = const None(),
    Option<bool> actionProcessed = const None(),
    Option<DateTime?> actionExpiration = const None(),
    Option<int?> appealRefId = const None(),
    Option<Snowflake?> contextMessageId = const None(),
    Option<int?> reportRefId = const None(),
    Option<Snowflake?> logMessageId = const None(),
    Option<Snowflake?> logDmMessageId = const None(),
  }) => UpdateCase(
    caseId: caseId ?? this.caseId,
    guildId: guildId ?? this.guildId,
    reason: reason | Some(this.reason),
    modId: modId | Some(this.modId),
    modTag: modTag | Some(this.modTag),
    refId: refId | Some(this.refId),
    actionProcessed: actionProcessed | Some(this.actionProcessed),
    actionExpiration: actionExpiration | Some(this.actionExpiration),
    appealRefId: appealRefId | Some(this.appealRefId),
    contextMessageId: contextMessageId | Some(this.contextMessageId),
    reportRefId: reportRefId | Some(this.reportRefId),
    logMessageId: logMessageId | Some(this.logMessageId),
    
  );
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
