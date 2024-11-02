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

import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import '../database.dart' hide Guild;
import '../kiwii.dart';
import 'base.dart';

final class OverwatchPlugin extends BasePlugin {
  @override
  final String name = 'overwatch';

  final AppDatabase db = GetIt.I.get<AppDatabase>();

  @override
  String helpText(NyxxGateway self) => '''
  **Overwatch**
  A plugin that allows you to get information about Overwatch players, heroes, maps and more.
''';

  @override
  FutureOr<void> onLoad(NyxxGateway self, {required Guild guild}) async {
    final commands = self.options.plugins.whereType<CommandsPlugin>().single;

    final guildCheck = overwatchCommand.checks.whereType<GuildCheck>().singleOrNull;

    if (guildCheck == null) {
      (overwatchCommand.checks as List<AbstractCheck>).add(GuildCheck.anyId([guild.id]));
    } else {
      (guildCheck.guildIds as List<Snowflake>).add(guild.id);
    }

    commands.addCommandOnTheFly(overwatchCommand);

    // Add the module to the guild's enabled modules
    final guildDb = await db.getGuild(guild.id);
    guildDb.enabledModules.add(name);
    await db.update(db.guildTable).replace(guildDb);
    guild.modules[name] = this;
  }

  @override
  FutureOr<void> onUnload(NyxxGateway self, {required Guild guild}) async {
    final commands = self.options.plugins.whereType<CommandsPlugin>().single;

    commands.removeCommandOnTheFly(overwatchCommand);

    final guildDb = await db.getGuild(guild.id);
    guildDb.enabledModules.remove(name);
    await db.update(db.guildTable).replace(guildDb);
    guild.modules.remove(name);
  }
}
