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
import 'dart:typed_data';

import 'package:nyxx/nyxx.dart' hide Cache;
import 'package:neat_cache/neat_cache.dart';
// ignore: implementation_imports
import 'package:neat_cache/src/providers/inmemory.dart';

final attachmentsCache = Cache(InMemoryCacheProvider<Uint8List>(512)).withTTL(const Duration(minutes: 30));

Future<void> onMessageCreate(MessageCreateEvent event) async {
  final message = event.message;

  if (message.content == 'emit') {
    final member = await event.guild!.get().then(
          (g) => g.members.get(message.author.id),
        );
    final user = await event.message.manager.client.users.get(message.author.id);
    final mockMember = Member(
      id: member.id,
      avatarDecorationData: null,
      avatarDecorationHash: null,
      avatarHash: null,
      bannerHash: null,
      communicationDisabledUntil: null,
      flags: member.flags,
      isDeaf: null,
      isMute: null,
      isPending: false,
      joinedAt: member.joinedAt,
      nick: member.nick,
      manager: member.manager,
      permissions: member.permissions,
      premiumSince: member.premiumSince,
      roleIds: member.roleIds,
      user: User(
        id: Snowflake.fromDateTime(DateTime.now().subtract(Duration(days: 14))),
        accentColor: null,
        avatarDecorationData: null,
        avatarDecorationHash: null,
        avatarHash: user.avatarHash,
        bannerHash: user.bannerHash,
        discriminator: user.discriminator,
        flags: user.flags,
        globalName: user.globalName,
        hasMfaEnabled: false,
        isBot: false,
        isSystem: false,
        locale: user.locale,
        manager: user.manager,
        nitroType: user.nitroType,
        username: user.username,
        publicFlags: user.publicFlags,
      ),
    );

    event.gateway.messagesController.add(
      EventReceived(
        event: GuildMemberRemoveEvent(
          gateway: event.gateway,
          guildId: event.guildId!,
          removedMember: member,
          user: user
        )..isIntentional = true,
      ),
    );
  }

  if (message.attachments.isEmpty) {
    return;
  }

  for (final attachment in message.attachments) {
    final data = await attachment.fetch();
    await attachmentsCache[attachment.id.toString()].set(data);
  }
}
