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

enum AppealStatus { pending, accepted, denied }

Future<Appeal> createAppeal(CreateAppeal appeal) async {
  final connection = GetIt.I.get<Connection>();

  try {
    final row = await connection
        .execute(
          r'INSERT INTO appeals (appeal_id, guild_id, status, target_id, target_tag, ref_id)'
          r'VALUES (next_appeal($1), $1, $2, $3, $4, $5)'
          'RETURNING *;',
          parameters: [appeal.guildId.value, AppealStatus.pending.index, appeal.targetId.value, appeal.targetTag, appeal.refId],
        )
        .then((r) => r.single.toColumnMap());

    return Appeal.fromRow(row);
  } catch (e) {
    print('Failed to create appeal: $e');
    rethrow;
  }
}
