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

import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';

import '../../../database.dart' hide Guild;
import '../../models/report.dart';
import '../replies/acknowledge_report.dart';
import 'create_report.dart';
import 'update_report.dart';

Future<List<Report>> resolvePendingReports(Guild guild, Snowflake targetId, int caseId, User moderator) async {
  final db = GetIt.I.get<AppDatabase>();

  final pendingReports = await (db.reports.select()
        ..where((e) => e.guildId.equalsValue(guild.id) & e.status.equalsValue(ReportStatus.pending) & e.targetId.equalsValue(targetId))
        ..orderBy(
          [
            (u) => OrderingTerm(
                  expression: u.createdAt,
                )
          ],
        ))
      .get();

  for (final report in pendingReports) {
    try {
      final updatedReport = await updateReport(
        UpdateReport(
          guildId: guild.id,
          reportId: report.reportId,
          refId: caseId,
          status: ReportStatus.approved,
        ),
        moderator,
      );

      await acknowledgeReport(guild, updatedReport);
    } catch (e) {
      // TODO: Handle error
    }
  }

  return pendingReports;
}
