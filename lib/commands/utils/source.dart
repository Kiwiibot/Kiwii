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

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import '../../utils/extensions.dart';

final sourceCommand = ChatCommand(
  'source',
  'Get the source of the specified command',
  id(
    'source',
    (ChatContext ctx, [@Autocomplete(autocompleteCallback) ChatCommand? command]) {
      final sourceUrl = 'https://github.com/Rapougnac/Kiwii', branch = 'mistress';
      if (command == null) {
        return ctx.send(sourceUrl);
      }

      final (start, end) = command.lines;
      final location = "lib${command.filePath.split('package:kiwii').last}";

      final url = '<$sourceUrl/blob/$branch/$location#L$start-L$end>';

      return ctx.send(url);
    },
  ),
);

Iterable<CommandOptionChoiceBuilder<dynamic>> autocompleteCallback(AutocompleteContext ctx) {
  final current = ctx.currentValue;
  final filtered = ctx.commands.walkCommands().where((element) => element.name.contains(current)).toList();
  return filtered.map((e) => CommandOptionChoiceBuilder(name: e is ChatCommand ? e.fullName : e.name, value: e is ChatCommand ? e.fullName : e.name));
}
