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

import '../moderation/appeal/create_appeal.dart';

class CreateAppeal {
  final Snowflake targetId;
  final String targetTag;
  final Snowflake guildId;
  final int refId;

  CreateAppeal({required this.targetId, required this.targetTag, required this.guildId, required this.refId});
}

class UpdateAppeal {
  final Option<String?> reason;
  final int appealId;
  final Snowflake guildId;
  final Option<Snowflake?> modId;
  final Option<String?> modTag;
  final Option<AppealStatus?> status;
  final Option<Snowflake?> logPostId;
  final Option<int?> refId;

  UpdateAppeal({
    required this.appealId,
    required this.guildId,
    this.reason = const None(),
    this.modId = const None(),
    this.modTag = const None(),
    this.status = const None(),
    this.logPostId = const None(),
    this.refId = const None(),
  });
}

final class Appeal {
  final Snowflake guildId;
  final int appealId;
  final AppealStatus? status;
  final Snowflake? targetId;
  final String? targetTag;
  final Snowflake? modId;
  final String? modTag;
  final String? reason;
  final int? refId;
  final DateTime? updatedAt;
  final DateTime createdAt;
  final Snowflake? logPostId;

  const Appeal({
    required this.appealId,
    required this.guildId,
    required this.createdAt,
    this.logPostId,
    this.modId,
    this.modTag,
    this.reason,
    this.refId,
    this.status,
    this.targetId,
    this.targetTag,
    this.updatedAt,
  });

  factory Appeal.fromRow(Map<String, Object?> row) => Appeal(
    appealId: row['appeal_id'] as int,
    guildId: Snowflake.parse(row['guild_id']!),
    createdAt: row['created_at'] as DateTime,
    logPostId: row['log_post_id'] != null ? Snowflake.parse(row['log_post_id']!) : null,
    modId: row['mod_id'] != null ? Snowflake.parse(row['mod_id']!) : null,
    modTag: row['mod_tag'] as String?,
    reason: row['reason'] as String?,
    refId: row['ref_id'] as int?,
    status: row['status'] != null ? AppealStatus.values[row['status'] as int] : null,
    targetId: row['target_id'] != null ? Snowflake.parse(row['target_id']!) : null,
    targetTag: row['target_tag'] as String?,
    updatedAt: row['updated_at'] != null ? row['updated_at'] as DateTime : null,
  );

  Appeal copyWith({
    Snowflake? guildId,
    int? appealId,
    Option<AppealStatus?> status = const None(),
    Option<Snowflake?> targetId = const None(),
    Option<String?> targetTag = const None(),
    Option<Snowflake?> modId = const None(),
    Option<String?> modTag = const None(),
    Option<String?> reason = const None(),
    Option<int?> refId = const None(),
    Option<DateTime?> updatedAt = const None(),
    DateTime? createdAt,
    Option<Snowflake?> logPostId = const None(),
  }) => Appeal(
    appealId: appealId ?? this.appealId,
    guildId: guildId ?? this.guildId,
    createdAt: createdAt ?? this.createdAt,
    logPostId: logPostId.unwrapOr(this.logPostId),
    modId: modId.unwrapOr(this.modId),
    modTag: modTag.unwrapOr(this.modTag),
    reason: reason.unwrapOr(this.reason),
    refId: refId.unwrapOr(this.refId),
    status: status.unwrapOr(this.status),
    targetId: targetId.unwrapOr(this.targetId),
    targetTag: targetTag.unwrapOr(this.targetTag),
    updatedAt: updatedAt.unwrapOr(this.updatedAt),
  );

  UpdateAppeal toUpdate({
    Snowflake? guildId,
    int? appealId,
    Option<AppealStatus?> status = const None(),
    Option<Snowflake?> modId = const None(),
    Option<String?> modTag = const None(),
    Option<String?> reason = const None(),
    Option<int?> refId = const None(),
    Option<Snowflake?> logPostId = const None(),
  }) => UpdateAppeal(
    appealId: appealId ?? this.appealId,
    guildId: guildId ?? this.guildId,
    logPostId: logPostId | Some(this.logPostId),
    modId: modId | Some(this.modId),
    modTag: modTag | Some(this.modTag),
    reason: reason | Some(this.reason),
    refId: refId | Some(this.refId),
    status: status | Some(this.status),
  );
}
