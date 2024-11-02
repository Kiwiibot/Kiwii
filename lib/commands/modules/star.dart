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

// import 'dart:async';

// import 'package:get_it/get_it.dart';
// import 'package:kiwii/generated/prisma_client.dart';
// import 'package:kiwii/src/managers/modules/starboard_manager.dart';
// import 'package:nyxx/nyxx.dart';
// import 'package:nyxx_commands/nyxx_commands.dart';
// import 'package:kiwii/kiwii.dart';

// final _starboards = <Snowflake, StarboardConfig>{};
// final _messageCache = <Snowflake, Message>{};
// final _aboutToBeDeleted = <Snowflake>{};
// final _staleStarGivers = <Snowflake>{};
// // final _locks = WeakReference(<Snowflake, Guild>{});
// final spoilers = RegExp(r'\|\|(.+?)\|\|');
// final prisma = GetIt.I.get<PrismaClient>();

// // Future<void> _updateStarGivers() async {
// //   if (_staleStarGivers.isNotEmpty) {
// //     return;
// //   }

// //   final query = r'''
// //     INSERT INTO "StarGiv
// // }

// final star = ChatCommand(
//   'star',
//   'Star a message, or view the stats of a starred message',
//   id('star', (ChatContext ctx, Snowflake messageId) async {
//     Timer(const Duration(hours: 1), () {
//       _messageCache.clear();
//     });
//     final starboard = _starboards[ctx.guild!.id]!;
//   }),
//   checks: [
//     GuildCheck.all(name: 'star-guild-check'),
//     Check(
//       (ctx) async {
//         final starboard = await ctx.guild!.starboard.getStarboard();
//         if (starboard == null || starboard.channelId == null) {
//           await ctx.respond(MessageBuilder(content: 'Starboard is not configured for this server.'));
//           return false;
//         }
//         _starboards[ctx.guild!.id] = starboard;
//         return true;
//       },
//       name: 'star-check',
//       allowsDm: false,
//       requiredPermissions: Permissions.addReactions,
//     ),
//   ],
// );
