/*
 * Kiwii, a stupid Discord bot.
 * Copyright (C) 2019-2024 Rapougnac
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
