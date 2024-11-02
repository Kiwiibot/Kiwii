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
