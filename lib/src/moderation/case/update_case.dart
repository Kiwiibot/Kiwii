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

import '../../../database.dart';
import '../../models/case.dart';

Future<Case> updateCase(UpdateCase case_) async {
  final db = GetIt.I.get<AppDatabase>();

  final currentCase = await db.getCase(case_.caseId!, case_.guildId!);

  final updates = currentCase.copyWith(
    reason: Value(case_.reason),
    refId: Value(case_.refId),
    actionExpiration: Value(case_.actionExpiration),
    appealRefId: Value(case_.appealRefId),
    contextMessageId: Value(case_.contextMessageId),
    reportRefId: Value(case_.reportRefId),
  );

  return db.updateCase(updates);
}

Future<List<Case>> batchUpdateCase(List<UpdateCase> cases) async {
  final db = GetIt.I.get<AppDatabase>();

  final updatedCases = <Case>[];

  for (final case_ in cases) {
    final currentCase = await db.getCase(case_.caseId!, case_.guildId!);

    final updates = currentCase.copyWith(
      reason: Value(case_.reason),
      refId: Value(case_.refId),
      actionExpiration: Value(case_.actionExpiration),
      appealRefId: Value(case_.appealRefId),
      contextMessageId: Value(case_.contextMessageId),
      reportRefId: Value(case_.reportRefId),
    );

    updatedCases.add(updates);
  }

  return db.insertOrUpdateCases(updatedCases);
}
