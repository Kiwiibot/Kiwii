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

import '../../../utils/extensions.dart';
import '../../models/case.dart';
import '../../../utils/sql.dart';

Future<Case> updateCase(UpdateCase case_) async {
  final client = GetIt.I.get<NyxxGateway>();

  final logger = Logger('Kiwii.Repositories.CaseRepository');

  var (index, query, args) = sql(case_.toRow());

  final buffer = StringBuffer('UPDATE cases SET $query');
  buffer.write(' WHERE guild_id = \$${++index} AND case_id = \$${++index}');

  buffer.write(' RETURNING *;');

  final realArgs = [...args, case_.guildId.value, case_.caseId];

  logger.fine('Executing "$buffer" with $realArgs');

  final r = await client.repositories.connection.execute(buffer.toString(), parameters: realArgs).then((r) => r.single);

  return Case.fromRow(r.toColumnMap());
}
