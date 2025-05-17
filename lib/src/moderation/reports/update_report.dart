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
import 'package:postgres/postgres.dart' as pg;

import '../../../utils/sql.dart';
import '../../models/report.dart';

Future<Report> updateReport(UpdateReport report) async {
  final connection = GetIt.I.get<pg.Connection>();

  var (index, query, args) = sql(report.toRow());

  final logger = Logger('Kiwii.Repositories.CaseRepository');

  final buffer = StringBuffer('UPDATE reports SET $query');
  buffer.write(' WHERE guild_id = \$${++index} AND report_id = \$${++index}');

  buffer.write(' RETURNING *;');

  final realArgs = [...args, report.guildId.value, report.reportId];

  logger.fine('Executing "$buffer" with $realArgs');

  final row = (await connection.execute(buffer.toString(), parameters: realArgs)).single;

  return Report.fromRow(row.toColumnMap());
}
