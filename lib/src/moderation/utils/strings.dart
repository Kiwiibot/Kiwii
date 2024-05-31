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

import '../../../translations.g.dart';
import '../case/create_case.dart';

String formatCaseAction(CaseAction key, Translations t, [bool isCase = false]) => switch (key) {
  CaseAction.role => t['moderation.history.actionLabel.restriction${isCase ? 'Case' : ''}'],
  CaseAction.unrole => t['moderation.history.actionLabel.unrestriction${isCase ? 'Case' : ''}'],
  CaseAction.warn => t.moderation.history.actionLabel.warn,
  CaseAction.kick => t.moderation.history.actionLabel.kick,
  CaseAction.softBan => t.moderation.history.actionLabel.softban,
  CaseAction.ban => t.moderation.history.actionLabel.ban,
  CaseAction.timeout => t.moderation.history.actionLabel.timeout,
  CaseAction.timeoutEnd => t.moderation.history.actionLabel.timeoutEnd,
  CaseAction.unban => t.moderation.history.actionLabel.unban,
};
