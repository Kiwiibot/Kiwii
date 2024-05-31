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

import '../../../database.dart';

Future<List<Case>> listCases(String sentence, Snowflake guildId) {
  final db = GetIt.I.get<AppDatabase>();

  if (sentence.isEmpty) {
    return (db.select(db.cases)
          ..where(
            (tbl) => tbl.guildId.equalsValue(guildId),
          )
          ..orderBy([
            (u) => OrderingTerm(expression: u.createdAt),
          ])
          ..limit(25))
        .get();
  }
  int? caseId;
  if ((caseId = int.tryParse(sentence)) != null) {
    return (db.select(db.cases)
          ..where(
            (tbl) => tbl.guildId.equalsValue(guildId) & tbl.caseId.equals(caseId!),
          ))
        .get();
  }

  return (db.select(db.cases)
        ..where((tbl) =>
            tbl.guildId.equalsValue(guildId) &
            (tbl.targetId.equals(int.tryParse(sentence) ?? 0) | tbl.targetTag.like('%$sentence%') | tbl.reason.like('%$sentence%')))
        ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)])
        ..limit(25))
      .get();
}
