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
import 'package:uwurandom/uwurandom.dart';

final uwurandom = ChatCommand(
  'uwurandom',
  'cat /dev/uwurandom',
  id(
    'uwurandom',
    (
      ChatContext ctx, [
      @Choices({'Catgirlnonsense': 'catgirlnonsense', 'Keysmash': 'keysmash', 'Scrunkly': 'scrunkly', 'All': 'all'})
      @Description('The type of nonsense to generate')
      String? type = 'all',
      @UseConverter(IntConverter(min: 1, max: 512)) @Description('The length of the nonsense to generate') int length = 128,
    ]) async {
      final result = switch (type) {
        'catgirlnonsense' => catGirlNonSense.generate(length),
        'keysmash' => keySmash.generate(length),
        'scrunkly' => scrunkly.generate(length),
        'all' => nonSense.generate(length),
        _ => nonSense.generate(length),
      };

      await ctx.respond(
        MessageBuilder(
          content: result,
          allowedMentions: AllowedMentions(
            repliedUser: false,
          ),
        ),
      );
    },
  ),
);
