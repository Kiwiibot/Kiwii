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

import 'dart:io';
import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../kiwii.dart';
import '../plugins/localization.dart';
import '../plugins/tracking.dart';


final _permissions = Permissions.sendMessages | Permissions.viewChannel;
final _clientPermissions = Permissions.sendMessages | Permissions.viewChannel;

final ping = ChatCommand(
  'ping',
  'Ping the bot',
  id('ping', (ChatContext ctx) async {
    final msg = await ctx.respond(MessageBuilder(content: ctx.guild.t.commands.ping.pinging));

    final createdAt = switch (ctx) {
      MessageChatContext(:final message) => message.createdAt,
      InteractionChatContext(:final interaction) => interaction.id.timestamp,
      _ => (throw 'Nah'),
    };

    final ping = msg.createdAt.difference(createdAt);

    final hb = ctx.client.gateway.latency;

    await msg.edit(
      MessageUpdateBuilder(
        content: ctx.guild.t.commands.ping.pong(
          o: 'o' * min(ping.inMilliseconds ~/ 100, 1500),
          ping: separateThousands(ping.inMilliseconds.toString()),
          hb: separateThousands(hb.inMilliseconds.toString()),
        ),
      ),
    );
  }),
  localizedDescriptions: {Locale.fr: 'Ping le bot'},
  options: KiwiiCommandOptions(
    category: 'utility',
    img: 'https://cdn-icons-png.flaticon.com/512/3883/3883802.png',
    permissions: _permissions,
    clientPermissions: _clientPermissions,
  ),
  checks: [BasePermissionsCheck(_permissions), BaseSelfPermissionsCheck(_clientPermissions)],
);
