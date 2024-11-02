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

abstract base class BasePlugin extends NyxxPlugin<NyxxGateway> {
  /// The description of the plugin.
  String helpText(NyxxGateway self);

  /// Whether the plugin is enabled.
  FutureOr<bool> isEnabled(NyxxGateway self, {required Guild guild}) async {
    final guildDb = await self.db.getGuildOrNull(guild.id);

    return guildDb != null && guildDb.enabledModules.contains(name.toLowerCase());
  }

  FutureOr<void> onLoad(NyxxGateway self, {required Guild guild});

  FutureOr<void> onUnload(NyxxGateway self, {required Guild guild});
}
