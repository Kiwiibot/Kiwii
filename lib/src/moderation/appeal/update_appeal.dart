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
import 'package:postgres/postgres.dart';

import '../../models/appeal.dart';
import '../../../utils/sql.dart';

Future<Appeal> updateAppeal(UpdateAppeal appeal) async {
  final connection = GetIt.I.get<Connection>();

  try {
    final entries = {
      'status': appeal.status.map((s) => s?.index),
      'reason': appeal.reason,
      'ref_id': appeal.refId,
      'mod_id': appeal.modId.map((id) => id?.value),
      'mod_tag': appeal.modTag,
    };

    final buffer = StringBuffer('UPDATE appeals SET ');

    var (latestIndex, sets, args) = sql(entries);

    buffer.write(sets);
    buffer.write(' ');

    buffer.write('WHERE guild_id = \$${++latestIndex} AND appeal_id = \$${++latestIndex}');

    buffer.write('RETURNING *;');

    final updatedAppeal = connection
        .execute(buffer.toString(), parameters: [...args, appeal.guildId.value, appeal.appealId])
        .then((r) => Appeal.fromRow(r.single.toColumnMap()));

    return updatedAppeal;
  } catch (e) {
    print('Failed to update appeal: $e');
    rethrow;
  }
}
