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

import 'dart:async';
import 'dart:math';

import 'package:dartx/dartx.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import '../../utils/utils.dart';

const codeUnitA = 65;
const codeUnitZ = 90;
const messageHundredsLimit = 10;
const _internalCacheTTL = 60000;
const _internalMessageCacheTTL = 120000;
final markov = ChatCommand(
  'markov',
  'Generate a markov chain from the last 100 messages in the channel.',
  id(
    'markov',
    (ChatContext ctx, [GuildTextChannel? channel]) async {
      final markov = await retrieveMarkov(ctx.user, channel ?? ctx.channel);
      if (markov == null) {
        await ctx.send('No messages found.');
        return;
      }

      final embed = EmbedBuilder(
        description: cutText(markov.process().toString(), 2000),
      );
      await ctx.respond(MessageBuilder(embeds: [embed]));
    },
  ),
);
final _internalCache = Expando<Markov>();
final _internalMessageCache = Expando<Map<Snowflake, Message>>();

final _internalUserCache = <String, Markov>{};

Future<Map<Snowflake, Message>> fetchMessages(TextChannel channel, [User? user]) async {
  Map<Snowflake, Message>? messageCache;

  final cachedMessages = _internalMessageCache[channel];
  if (cachedMessages == null) {
    final messages = await channel.messages.fetchMany(limit: 100);
    messageCache = {
      for (final message in messages) message.id: message,
    };

    for (int i = 1; i < messageHundredsLimit; ++i) {
      final m = await channel.messages.fetchMany(limit: 100, before: messageCache.keys.last);
      messageCache.addEntries(m.map((message) => MapEntry(message.id, message)));
    }

    _internalMessageCache[channel] = messageCache;
    Timer(const Duration(milliseconds: _internalMessageCacheTTL), () {
      _internalMessageCache[channel] = null;
    });
  } else {
    messageCache = cachedMessages;
  }

  return user != null ? messageCache.filterValues((message) => message.author.id != user.id) : messageCache;
}

Future<Markov?> retrieveMarkov(User? user, TextChannel channel) async {
  final entry = user != null ? _internalUserCache['${channel.id.value}.${user.id.value}'] : _internalCache[channel];
  if (entry != null) {
    return entry;
  }

  final messages = await fetchMessages(channel, user);
  if (messages.isEmpty) {
    return null;
  }

  final contents = messages.values.map(getAllContent).join(' ');
  final markov = Markov().parse(contents)
    ..startFn = (words) {
      int code = 0;
      final filtered = <String>[];
      for (final key in words.keys) {
        code = key.codeUnitAt(0);
        if (code >= codeUnitA && code <= codeUnitZ) {
          filtered.add(key);
        }
      }

      return filtered.isNotEmpty ? filtered[Random().nextInt(filtered.lastIndex)] : words.keys.elementAt(Random().nextInt(words.length));
    }
    ..end(60);

  if (user != null) {
    _internalUserCache['${channel.id.value}.${user.id.value}'] = markov;
  } else {
    _internalCache[channel] = markov;
  }

  Timer(const Duration(milliseconds: _internalCacheTTL), () {
    if (user != null) {
      _internalUserCache.remove('${channel.id.value}.${user.id.value}');
    } else {
      _internalCache[channel] = null;
    }
  });

  return markov;
}
