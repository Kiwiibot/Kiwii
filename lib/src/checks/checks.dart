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
// ignore: implementation_imports
import 'package:nyxx_commands/src/util/util.dart';
import '../../utils/extensions.dart';
import '../settings.dart';

final adminCheck = Check((ctx) => ctx.user.id == ownerId, name: 'AdminCheck');

class BasePermissionsCheck extends PermissionsCheck {
  BasePermissionsCheck(super.permissions, {super.name})
      : super(
          allowsDm: false,
          allowsOverrides: false,
          requiresAll: true,
        );
}

class SelfPermissionsCheck extends Check {
  /// The bitfield representing the permissions required by this check.
  ///
  /// You might also be interested in:
  /// - [Permissions], for computing the value for this field;
  /// - [AbstractCheck.requiredPermissions], for setting permissions on any check.
  final Flags<Permissions> permissions;

  /// Whether this check should allow server administrators to configure overrides that allow
  /// specific users or channels to execute this command regardless of permissions.
  final bool allowsOverrides;

  /// Whether this check requires the user invoking the command to have all of the permissions in
  /// [permissions] or only a single permission from [permissions].
  ///
  /// If this is true, the member invoking the command must have all the permissions in
  /// [permissions] to execute the command. Otherwise, members need only have one of the
  /// permissions in [permissions] to execute the command.
  final bool requiresAll;

  SelfPermissionsCheck(
    this.permissions, {
    this.allowsOverrides = true,
    this.requiresAll = true,
    String? name,
    super.allowsDm = false,
  }) : super(
          name: name ?? 'Self permission check on $permissions',
          requiredPermissions: permissions,
          (context) async {
            Guild? guild = context.guild;

            if (guild == null) {
              return allowsDm;
            }

            Member member = await guild.me;

            final effectivePermissions = await computePermissions(
              context.guild!,
              context.channel as GuildChannel,
              member,
            );

            if (allowsOverrides) {
              ApplicationCommand command;

              if (context is InteractionCommandContextData) {
                command = context.commands.registeredCommands.singleWhere(
                  (element) => element.id == (context as InteractionCommandContextData).interaction.data.id,
                );
              } else {
                // If the invocation was not from a slash command, try to find a matching slash
                // command and use the overrides from that.
                CommandRegisterable root = context.command;

                while (root.parent is CommandRegisterable) {
                  root = root.parent as CommandRegisterable;
                }

                Iterable<ApplicationCommand> matchingCommands = context.commands.registeredCommands.where(
                  (command) => command.name == root.name && command.type == ApplicationCommandType.chatInput,
                );

                if (matchingCommands.isEmpty) {
                  return false;
                }

                command = matchingCommands.first;
              }

              CommandPermissions overrides = await command.fetchPermissions(context.guild!.id);

              if (overrides.permissions.isEmpty) {
                overrides = (await context.client.guilds[context.guild!.id].commands.listPermissions())
                    .singleWhere((overrides) => overrides.command == null, orElse: () => overrides);
              }

              bool? def;
              bool? channelDef;
              bool? role;
              bool? channel;
              bool? user;

              int highestRoleIndex = -1;

              for (final override in overrides.permissions) {
                if (override.id == context.guild!.id) {
                  def = override.hasPermission;
                } else if (override.id == Snowflake(context.guild!.id.value - 1)) {
                  channelDef = override.hasPermission;
                } else if (override.type == CommandPermissionType.channel && override.id == context.channel.id) {
                  channel = override.hasPermission;
                } else if (override.type == CommandPermissionType.role) {
                  int roleIndex = -1;

                  int i = 0;
                  for (final role in member.roles) {
                    if (role.id == override.id) {
                      roleIndex = i;
                      break;
                    }

                    i++;
                  }

                  if (highestRoleIndex < roleIndex) {
                    role = override.hasPermission;
                    highestRoleIndex = roleIndex;
                  }
                } else if (override.type == CommandPermissionType.user && override.id == context.user.id) {
                  user = override.hasPermission;
                  // No need to continue if we found an override for the specific user
                  break;
                }
              }

              Iterable<bool> prioritized = [def, channelDef, role, channel, user].whereType<bool>();

              if (prioritized.isNotEmpty) {
                return prioritized.last;
              }
            }

            Flags<Permissions> corresponding = effectivePermissions & permissions;

            if (requiresAll) {
              return corresponding == permissions;
            }

            return corresponding != const Permissions(0);
          },
        );
}

class BaseSelfPermissionsCheck extends SelfPermissionsCheck {
  BaseSelfPermissionsCheck(super.permissions, {super.name})
      : super(
          allowsOverrides: false,
          requiresAll: true,
        );
}
