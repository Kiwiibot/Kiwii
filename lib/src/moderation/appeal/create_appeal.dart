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

import 'package:drift_postgres/drift_postgres.dart';
import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';

import '../../../database.dart';
import '../../models/appeal.dart';

enum AppealStatus {
  pending,
  accepted,
  denied,
}

Future<Appeal> createAppeal(CreateAppeal appeal) async {
  final db = GetIt.I.get<AppDatabase>();
  final logger = GetIt.I.get<Logger>();

  final nextAppealId = await nextAppeal(appeal.guildId);

  try {
    final newAppeal = Appeal(
      appealId: nextAppealId,
      targetId: appeal.targetId,
      targetTag: appeal.targetTag,
      guildId: appeal.guildId,
      createdAt: PgDateTime(DateTime.now()),
      status: AppealStatus.pending,
      refId: appeal.refId,
    );

    await db.createAppeal(newAppeal);

    return newAppeal;
  } catch (e) {
    logger.warning('Failed to create appeal: $e');
    rethrow;
  }
}

Future<int> nextAppeal(Snowflake guildId) async {
  final db = GetIt.I.get<AppDatabase>();

  final lastAppeal = await (db.appeals.select()
        ..where((a) => a.guildId.equalsValue(guildId))
        ..orderBy([(u) => OrderingTerm.desc(u.appealId)])
        ..limit(1))
      .getSingleOrNull();

  return (lastAppeal?.appealId ?? 0) + 1;
}
