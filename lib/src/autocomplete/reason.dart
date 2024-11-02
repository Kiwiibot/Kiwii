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

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:string_similarity/string_similarity.dart';

import '../../plugins/localization.dart';

Iterable<CommandOptionChoiceBuilder<String>> reasonAutoComplete(AutocompleteContext ctx) {
  final input = ctx.currentValue.trim();

  final reasons = input.bestMatch(ctx.guild.t.moderation.common.reasons);

  return input.isEmpty
      ? ctx.guild.t.moderation.common.reasons.map(
          (r) => CommandOptionChoiceBuilder(
            name: r,
            value: r,
          ),
        )
      : reasons.ratings.where((value) => (value.rating ?? 0) >= 0.1).map(
            (e) => CommandOptionChoiceBuilder<String>(
              name: e.target ?? '',
              value: e.target ?? '',
            ),
          );
}
