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

import 'package:nyxx/nyxx.dart';

import '../kiwii.dart';
import 'base.dart';
import 'github_expand.dart';
import 'overwatch.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

final modules = <String, BasePlugin>{
  'overwatch': OverwatchPlugin(),
  // 'github_expand': GithubExpand(),
};

class ModulesPlugin extends NyxxPlugin<NyxxGateway> {
  @override
  String get name => 'Modules';

  @override
  Future<void> afterConnect(client) async {
    client.on<ReadyEvent>((event) async {
      for (final g in event.guilds) {
        final guild = await g.get();

        await loadModules(client, guild);
      }
    });

    guildJoins.onGuildJoin.listen((event) async {
      await loadModules(client, await event.guild.get());
    });
  }
}

Future<void> loadModules(NyxxGateway client, Guild guild) async {
  for (final MapEntry(:key, value: module) in modules.entries) {
    final isEnabled = await module.isEnabled(client, guild: guild);

    if (isEnabled) {
      guild.modules[key.toLowerCase()] = module;
      await module.onLoad(client, guild: guild);
    }
  }
}
