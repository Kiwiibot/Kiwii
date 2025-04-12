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
import 'package:nyxx/nyxx.dart' hide Connection;
import 'package:postgres/postgres.dart';

import '../../models/case.dart';

// import '../../../database.dart';

Future<List<Case>> listCases(String sentence, Snowflake guildId) {
  final connection = GetIt.I.get<Connection>();

  if (sentence.isEmpty) {
    return connection
        .execute(r'SELECT * FROM cases WHERE guild_id = $1 ORDER BY created_at LIMIT 25;', parameters: [guildId.value])
        .then((r) => r.map((c) => Case.fromRow(c.toColumnMap())).toList());
  }
  int? caseId;
  if ((caseId = int.tryParse(sentence)) != null) {
    return connection
        .execute(r'SELECT * FROM cases WHERE guild_id = $1 AND case_id = $2;', parameters: [guildId.value, caseId])
        .then((r) => r.map((c) => Case.fromRow(c.toColumnMap())).toList());
  }

  return connection
      .execute(
        r'''
SELECT *
FROM cases
WHERE guild_id = $1
  AND (
    target_id = $2
    OR target_tag LIKE '%' || $3 || '%'
    OR reason LIKE '%' || $3 || '%'
  )
ORDER BY created_at DESC
LIMIT 25;
''',
        parameters: [guildId.value, int.tryParse(sentence) ?? 0, sentence],
      )
      .then((r) => r.map((c) => Case.fromRow(c.toColumnMap())).toList());
}
