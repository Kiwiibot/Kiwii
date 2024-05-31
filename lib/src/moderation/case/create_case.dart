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

import 'package:drift_postgres/drift_postgres.dart';
import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';

import '../../../database.dart' hide Guild;
import '../../../kiwii.dart';
import '../../models/appeal.dart';
import '../../models/case.dart';
import '../appeal/create_appeal.dart';
import '../reports/resolve_report.dart';
import 'update_case.dart';

enum CaseAction {
  role,
  unrole,
  warn,
  kick,
  softBan,
  ban,
  unban,
  timeout,
  timeoutEnd,
}

const reportAutoResolveIgnoreActions = [CaseAction.unban, CaseAction.timeoutEnd];

Future<Case> createCase(Guild guild, CreateCase ccase, {bool skip = false, Member? target, int? deleteMessageDays = 1}) async {
  final db = GetIt.I.get<AppDatabase>();
  final logger = GetIt.I.get<Logger>();
  final guildSettings = await db.getGuild(guild.id);

  final reason = ccase.modTag != null ? 'Mod: ${ccase.modTag}${ccase.reason != null ? ' | ${ccase.reason!.replaceAll('`', '')}' : ''}' : ccase.reason;

  final nextCaseId = await nextCase(guild.id);

  try {
    if (!skip) {
      switch (ccase.action) {
        case CaseAction.role:
          await target!.addRole(ccase.roleId!, auditLogReason: reason);
        case CaseAction.unrole:
          await target!.removeRole(ccase.roleId!, auditLogReason: reason);
        case CaseAction.timeoutEnd || CaseAction.warn:
          break;
        case CaseAction.kick:
          await target!.delete(auditLogReason: reason);
        case CaseAction.softBan:
          await guild.createBan(
            ccase.targetId,
            deleteMessages: Duration(days: deleteMessageDays ?? 1),
            auditLogReason: reason,
          );
          await guild.deleteBan(
            ccase.targetId,
            auditLogReason: reason,
          );
        case CaseAction.ban:
          await guild.createBan(
            ccase.targetId,
            deleteMessages: Duration(days: deleteMessageDays ?? 0),
            auditLogReason: reason,
          );

          if (guildSettings.appealChannelId != null) {
            // Create a pending appeal.
            await createAppeal(CreateAppeal(
              guildId: guild.id,
              targetId: ccase.targetId,
              targetTag: ccase.targetTag,
              refId: nextCaseId,
            ));
          }
        case CaseAction.unban:
          await guild.deleteBan(
            ccase.targetId,
            auditLogReason: reason,
          );
        case CaseAction.timeout:
          await target!.update(
            MemberUpdateBuilder(communicationDisabledUntil: ccase.actionExpiration?.toUtc()),
            auditLogReason: reason,
          );
      }
    }
  } catch (e, st) {
    logger.warning('Failed to execute action for case $nextCaseId in guild ${guild.id}', e, st);
  }

  final caseData = Case(
    guildId: guild.id,
    caseId: nextCaseId,
    targetId: ccase.targetId,
    targetTag: ccase.targetTag,
    action: ccase.action,
    createdAt: PgDateTime(DateTime.now()),
    actionExpiration: ccase.actionExpiration,
    appealRefId: ccase.appealRefId,
    contextMessageId: ccase.contextMessageId,
    modId: ccase.modId,
    modTag: ccase.modTag,
    multi: ccase.multi,
    reason: ccase.reason,
    reportRefId: ccase.reportRefId,
    refId: ccase.refId,
    actionProcessed: ccase.actionExpiration == null,
  );

  final newCase = await db.createCase(caseData);

  if (!reportAutoResolveIgnoreActions.contains(ccase.action)) {
    try {
      final resolvedReports = await resolvePendingReports(
        guild,
        ccase.targetId,
        newCase.caseId,
        await guild.manager.client.users.get(newCase.modId!),
      );

      if (resolvedReports.isNotEmpty && ccase.reportRefId != null) {
        return updateCase(UpdateCase(
          caseId: newCase.caseId,
          guildId: newCase.guildId,
          reportRefId: resolvedReports.last.reportId,
        ));
      }
    } catch (e, st) {
      logger.warning('Failed to resolve reports for case $nextCaseId in guild ${guild.id}', e, st);
    }
  }

  return newCase;
}

Future<int> nextCase(Snowflake guildId) async {
  final db = GetIt.I.get<AppDatabase>();

  final lastCaseId = await db.customSelect(
    'SELECT MAX(case_id) FROM cases WHERE guild_id = \$1',
    variables: [
      Variable.withBigInt(guildId.toBigInt()),
    ],
    readsFrom: {db.cases},
  ).getSingle();

  return (lastCaseId.data['max'] as int? ?? 0) + 1;
}
