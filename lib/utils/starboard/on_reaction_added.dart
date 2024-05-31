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

// import 'package:get_it/get_it.dart';
// import 'package:kiwii/generated/prisma_client.dart';
// import 'package:kiwii/kiwii.dart';
// import 'package:kiwii/utils/starboard/constants.dart';
// import 'package:nyxx/nyxx.dart';

// Future<void> onReactionAdded(MessageReactionAddEvent event) async {
//   final prisma = GetIt.I.get<PrismaClient>();
//   final guild = await event.guild?.get();
//   // We don't want to do anything if the message comes from a DM
//   if (guild == null) return;

//   final starboard = await guild.starboard.getStarboard();

//   if (starboard == null || starboard.channelId == null) return;

//   if (!(emojis.contains(event.emoji.name) || (event.emoji.id != Snowflake.zero && starboard.customEmojis.contains(event.emoji.id)))) {
//     return;
//   }

//   final channel = await event.channel.get();
//   if (channel is! TextChannel || channel is! Thread) {
//     return;
//   }

//   final starboardChannel = await event.channel.manager.get(starboard.channelId!) as GuildChannel;

//   if (starboard.isLocked) {
//     return;
//   }

//   if (channel.isNsfw && !starboardChannel.isNsfw) {
//     return;
//   }

//   // Maybe if a star is added to the starboard, we can count as a star?
//   // Im too lazy to do that right now
//   if (channel.id == starboardChannel.id) {
//     return;
//   }

//   final me = await guild.members.get(event.channel.manager.client.application.id);

//   if (starboardChannel.permissionOverwrites
//       .any((element) => element.id == me.id && element.deny.contains(Permissions.addReactions | Permissions.sendMessages))) {
//     return;
//   }
// }
