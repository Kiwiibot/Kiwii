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

import 'dart:async';
import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart' hide Request;
import 'package:shelf/shelf.dart';
// import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_helmet/shelf_helmet.dart';

import '../kiwii.dart';
import 'routes/cases.dart';
import 'routes/users.dart';

part 'api.g.dart';

class Service {
  @Route.mount('/api')
  Router get _api => Api().router;

  Handler get handler => _$ServiceRouter(this).call;
}

class Api {
  final client = GetIt.I.get<NyxxGateway>();
  @Route.mount('/users')
  Router get _users => UserService().router;

  @Route.mount('/cases')
  Router get _cases => CasesService().router;

  @Route.get('/permissions/<gId>/<mId>')
  Future<Response> permissions(Request request, String gId, String mId) async {
    late final Permissions allPermissions;
    try {
      allPermissions = await (await (await client.guilds.get(Snowflake.parse(gId))).members.get(Snowflake.parse(mId))).computedPermissions;
    } on HttpResponseError catch (e) {
      if (e.statusCode == 404) {
        return Response.notFound('{"error": "Guild or Member not found"}', headers: {
          'Content-Type': 'application/json',
        });
      }
    }
    return Response.ok('{"permissions": "${allPermissions.value.toString()}"}', headers: {
      'Content-Type': 'application/json',
    });
  }

  @Route.get('/guilds/<gId>')
  Future<Response> guild(Request request, String gId) async {
    late final Guild guild;
    try {
      guild = await client.guilds.get(Snowflake.parse(gId));
    } on HttpResponseError catch (e) {
      if (e.statusCode == 404) {
        return Response.notFound('{"error": "Guild not found"}', headers: {
          'Content-Type': 'application/json',
        });
      }
    }
    return Response.ok(jsonEncode(guild.toJson()), headers: {
      'Content-Type': 'application/json',
    });
  }

  Router get router => _$ApiRouter(this);
}

Future<FutureOr<Response> Function(Request)> api() async {
  final service = Service();
  var handler = const Pipeline().addMiddleware(helmet()).addHandler(service.handler);

  return handler;
}
