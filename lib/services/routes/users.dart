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

import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart' hide Request;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../database.dart';
import '../../kiwii.dart';
import '../../src/moderation/case/create_case.dart';

part 'users.g.dart';

class UserService {
  final NyxxRest client = GetIt.I.get<NyxxGateway>();
  final db = GetIt.I.get<AppDatabase>();

  @Route.get('/<guildId>/<userId>')
  Future<Response> getUser(Request request, String guildId, String userId) async {
    final uId = Snowflake.parse(userId);
    final gId = Snowflake.parse(guildId);

    bool isBanned = false;

    try {
      await (await client.guilds.get(gId)).manager.fetchBan(gId, uId);
      isBanned = true;
    } catch (_) {
      isBanned = false;
    }

    if (isBanned) {
      final user = await client.users.fetch(uId);

      final ccase = await (db.select(db.cases)
            ..where((tbl) => tbl.guildId.equalsValue(gId) & tbl.targetId.equalsValue(uId) & tbl.action.equalsValue(CaseAction.ban))
            ..orderBy(
              [
                (u) => OrderingTerm.desc(u.createdAt),
              ],
            ))
          .getSingle();

      final mod = await client.users.fetch(ccase.modId!);

      final payload = {
        'user': user.toJson(),
        'moderator': mod.toJson(),
        'banned': isBanned,
        'case': ccase.toJson(serializer: JsonSerializerDb(serializeDateTimeValuesAsString: true)),
      };

      return Response.ok(
        jsonEncode(payload),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({
        'banned': isBanned,
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  Router get router => _$UserServiceRouter(this);
}
