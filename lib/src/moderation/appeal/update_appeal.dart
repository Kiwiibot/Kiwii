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
import '../../models/appeal.dart';

Future<Appeal> updateAppeal(UpdateAppeal appeal) async {
  final db = GetIt.I.get<AppDatabase>();
  final logger = GetIt.I.get<Logger>();

  try {
    final currentAppeal = await db.getAppeal(appeal.appealId, appeal.guildId);

    final updatedAppeal = currentAppeal.copyWith(
      reason: Value(appeal.reason),
      modId: Value(appeal.modId),
      modTag: Value(appeal.modTag),
      status: Value(appeal.status),
    );

    await db.updateAppeal(updatedAppeal);

    return updatedAppeal;
  } catch (e) {
    logger.warning('Failed to update appeal: $e');
    rethrow;
  }
}
