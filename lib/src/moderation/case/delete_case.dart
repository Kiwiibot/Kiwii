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
import '../../../plugins/localization.dart';
import '../../models/case.dart';
import 'create_case.dart';

Future<Case> deleteCase(DeleteCase deleteCase, Guild guild, {bool shouldSkip = false, bool isManual = false}) async {
  final db = GetIt.I.get<AppDatabase>();
  final t = guild.t;
  Case? ccase;
  var localReason = deleteCase.reason;

  if (deleteCase.targetId != null) {
    ccase = await (db.cases.select()
          ..where(
            (tbl) =>
                tbl.targetId.equalsValue(deleteCase.targetId!) &
                tbl.guildId.equalsValue(deleteCase.guildId) &
                tbl.action.equalsValue(deleteCase.action ?? CaseAction.ban),
          )
          ..orderBy(
            [
              (u) => OrderingTerm.desc(u.createdAt),
            ],
          )
          ..limit(1))
        .getSingle();
  }

  if (deleteCase.targetId == null) {
    ccase = await db.getCase(deleteCase.caseId!, deleteCase.guildId);
  }

  if (ccase?.action == CaseAction.role) {
    await (db.cases.update()..where((tbl) => tbl.guildId.equalsValue(deleteCase.guildId) & tbl.caseId.equals(ccase!.caseId))).write(
      CasesCompanion(
        actionProcessed: Value(true),
      ),
    );

    if (isManual == true) {
      localReason = t.moderation.logs.cases.unroleDeleteManual;
    } else {
      localReason = t.moderation.logs.cases.unroleDeleteAuto;
    }
  }

  if (ccase?.action == CaseAction.timeout) {
    await (db.cases.update()..where((tbl) => tbl.guildId.equalsValue(deleteCase.guildId) & tbl.caseId.equals(ccase!.caseId))).write(
      CasesCompanion(
        actionProcessed: Value(true),
      ),
    );

    if (isManual) {
      localReason = t.moderation.logs.cases.timeoutDeleteManual;
    } else {
      localReason = t.moderation.logs.cases.timeoutDeleteAuto;
    }
  }

  final caseAction = ccase?.action ?? CaseAction.ban;

  return createCase(
    guild,
    CreateCase(
      guildId: guild.id,
      action: caseAction == CaseAction.ban
          ? CaseAction.unban
          : caseAction == CaseAction.role
              ? CaseAction.unrole
              : CaseAction.timeoutEnd,
      targetId: ccase?.targetId ?? deleteCase.targetId!,
      targetTag: ccase?.targetTag ?? deleteCase.targetTag!,
      appealRefId: deleteCase.appealRefId,
      reportRefId: deleteCase.reportRefId,
      refId: ccase?.caseId,
      reason: localReason,
      modId: deleteCase.modId,
      modTag: deleteCase.modTag,
    ),
    skip: shouldSkip,
  );
}
