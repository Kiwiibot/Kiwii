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

import 'package:nyxx/nyxx.dart';

// import '../../../database.dart' hide Guild;
import '../../../kiwii.dart';
import '../../../plugins/localization.dart';
import '../../models/case.dart';
import 'create_case.dart';

Future<Case> deleteCase(DeleteCase deleteCase, Guild guild, {bool shouldSkip = false, bool isManual = false}) async {
  final t = guild.t;
  final client = guild.manager.client;
  Case? ccase;
  var localReason = deleteCase.reason;

  if (deleteCase.targetId != null) {
    ccase = await client.repositories.connection
        .execute(
          r'''
SELECT * FROM cases
WHERE target_id = $1
  AND guild_id = $2
  AND action = $3
ORDER BY created_at DESC
LIMIT 1;
''',
          parameters: [deleteCase.targetId!.value, deleteCase.guildId.value, deleteCase.action?.index ?? CaseAction.ban.index],
        )
        .then((r) => Case.fromRow(r.single.toColumnMap()));
  }

  if (deleteCase.targetId == null) {
    ccase = await client.repositories.cases.get(deleteCase.caseId!, deleteCase.guildId);
  }

  if (ccase?.action == CaseAction.role) {
    await client.repositories.connection.execute(
      r'UPDATE cases SET action_processed = TRUE WHERE guild_id = $1 AND case_id = $2;',
      parameters: [deleteCase.guildId.value, ccase!.caseId],
    );

    if (isManual == true) {
      localReason = t.moderation.logs.cases.unroleDeleteManual;
    } else {
      localReason = t.moderation.logs.cases.unroleDeleteAuto;
    }
  }

  if (ccase?.action == CaseAction.timeout) {
    await client.repositories.connection.execute(
      r'UPDATE cases SET action_processed = TRUE WHERE guild_id = $1 AND case_id = $2;',
      parameters: [deleteCase.guildId.value, ccase!.caseId],
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
      action:
          caseAction == CaseAction.ban
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
