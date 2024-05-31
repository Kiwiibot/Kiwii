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

import '../moderation/appeal/create_appeal.dart';

class CreateAppeal {
  final Snowflake targetId;
  final String targetTag;
  final Snowflake guildId;
  final int refId;

  CreateAppeal({
    required this.targetId,
    required this.targetTag,
    required this.guildId,
    required this.refId,
  });
}

class UpdateAppeal {
  final String? reason;
  final int appealId;
  final Snowflake guildId;
  final Snowflake? modId;
  final String? modTag;
  final AppealStatus? status;
  final Snowflake? logMessageId;
  // final int refId;

  UpdateAppeal({
    required this.appealId,
    required this.guildId,
    this.reason,
    this.modId,
    this.modTag,
    this.status,
    this.logMessageId,
    // required this.refId,
  });
}
