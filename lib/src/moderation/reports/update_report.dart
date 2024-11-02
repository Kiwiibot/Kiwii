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

import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';

import '../../../database.dart' hide Guild;
import '../../models/report.dart';
import '../../../utils/extensions.dart';

Future<Report> updateReport(UpdateReport report, [User? moderator]) async {
  final db = GetIt.I.get<AppDatabase>();

  final currentReport = await db.getReport(report.reportId!, report.guildId!);

  final updates = currentReport.copyWith(
    status: Value(report.status),
    attachmentUrl: Value(report.attachmentUrl),
    reason: Value(report.reason),
    messageId: Value(report.message?.id),
    channelId: Value(report.message?.channel.id),
    refId: Value(report.refId),
    modId: Value(moderator?.id),
    modTag: Value(moderator?.tag),
    contextMessagesIds: Value(report.contextMessagesIds),
  );

  return db.updateReport(updates);
}
