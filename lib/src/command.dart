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
// ignore: implementation_imports
import 'package:nyxx/src/utils/to_string_helper/to_string_helper.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

typedef Example = ({String command, String description});

class KiwiiCommandOptions extends CommandOptions with ToStringHelper {
  /// An URL representing the image of the command.
  final String? img;

  /// The category of the command.
  final String? category;

  /// An string on how to use the command.
  final String? usage;

  /// A list of examples on how to use the command.
  final List<Example> examples;

  /// Whether the command is hidden from the help command.
  final bool isHidden;

  /// Whether the command is classified as a NSFW command.
  final bool isNsfw;

  /// Set of required permissions (only for the help command, logic is handled by the checks).
  final Flags<Permissions>? permissions;

  /// Set of required permissions for the bot (only for the help command, logic is handled by the checks).
  final Flags<Permissions>? clientPermissions;

  const KiwiiCommandOptions({
    this.img,
    this.category,
    this.usage,
    this.examples = const [],
    this.isHidden = false,
    this.isNsfw = false,
    this.permissions,
    this.clientPermissions,
    super.acceptBotCommands,
    super.type,
    super.acceptSelfCommands,
    super.defaultResponseLevel,
    super.autoAcknowledgeDuration,
    super.caseInsensitiveCommands,
    super.autoAcknowledgeInteractions,
  });
}
