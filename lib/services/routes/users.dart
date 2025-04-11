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

import '../../kiwii.dart';
import '../../src/moderation/case/create_case.dart';

part 'users.g.dart';

class UserService {
  final NyxxRest client = GetIt.I.get<NyxxGateway>();
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

      final ccase = await (client.repositories.connection.execute(
        r'SELECT * FROM cases WHERE guild_id = $1 AND target_id = $2 AND action = $3 ORDER BY created_at DESC limit 1;',
        parameters: [gId.value, uId.value, CaseAction.ban.index],
      )).then((r) => r.single.toColumnMap());

      final mod = await client.users.fetch(Snowflake.parse(ccase['mod_id']));

      final payload = {
        'user': user.toJson(),
        'moderator': mod.toJson(),
        'banned': isBanned,
        'case': ccase,
      };

      return Response.ok(jsonEncode(payload), headers: {'Content-Type': 'application/json'});
    }

    return Response.ok(jsonEncode({'banned': isBanned}), headers: {'Content-Type': 'application/json'});
  }

  Router get router => _$UserServiceRouter(this);
}
