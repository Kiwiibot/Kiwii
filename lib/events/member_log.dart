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

import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';

import '../database.dart';
import '../plugins/localization.dart';
import '../src/moderation/utils/generate.dart';

Future<void> onGuildMemberAdd(GuildMemberAddEvent event) async {
  final db = GetIt.I.get<AppDatabase>();

  final guild = await event.guild.get();
  final member = event.member;
  final client = event.guild.manager.client;

  final logwebhookId = (await db.getGuildOrNull(guild.id))?.guildLogWebhookId ?? const Snowflake(1250365441470103573);

  // if (logwebhookId == null) {
  //   return;
  // }

  final webhook = await client.webhooks.get(logwebhookId);

  final currentUser = await client.user.get();

  await webhook.execute(MessageBuilder(embeds: [generateMemberLog(member, member.user ?? await client.users.get(member.id), guild.t, isJoin: true)]), token: webhook.token!, avatarUrl: currentUser.avatar.url.toString(), username: currentUser.username);
}

Future<void> onGuildMemberRemove(GuildMemberRemoveEvent event) async {
  final db = GetIt.I.get<AppDatabase>();

  final guild = await event.guild.get();
  final member = event.removedMember!;
  final client = event.guild.manager.client;

  final logwebhookId = (await db.getGuildOrNull(guild.id))?.guildLogWebhookId ?? const Snowflake(1250365441470103573);


  final webhook = await client.webhooks.get(logwebhookId);

  final currentUser = await client.user.get();

  await webhook.execute(MessageBuilder(embeds: [generateMemberLog(member, member.user ?? await client.users.get(member.id), guild.t)]), token: webhook.token!, avatarUrl: currentUser.avatar.url.toString(), username: currentUser.username);
}