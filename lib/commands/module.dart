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

// import 'package:kiwii/src/managers/module_manager.dart';
// import 'package:kiwii/utils/utils.dart';
// import 'package:nyxx/nyxx.dart';
// import 'package:nyxx_commands/nyxx_commands.dart';

// final module = ChatGroup(
//   'module',
//   'Enable or disable a module for the server',
//   children: [
//     ChatCommand(
//       'enable',
//       'Enable a module for the serveer',
//       id('module-enable', (ChatContext ctx, GuildModule module) async {
//         var modules = ctx.guild!.modules.enableModules ?? await ctx.guild!.modules.fetchModules();

//         final respondBuilder = MessageBuilder(content: 'Enabled module `${module.name.firstLetterUpperCase}`');

//         if (modules == null) {
//           await ctx.guild!.modules.alterModules([module]);
//           await ctx.respond(respondBuilder);
//         } else if (modules.contains(module)) {
//           await ctx.respond(MessageBuilder(content: 'Module `${module.name.firstLetterUpperCase}` is already enabled.'));
//         } else {
//           await ctx.guild!.modules.alterModules([module]);
//           await ctx.respond(respondBuilder);
//         }
//       }),
//     ),
//     ChatCommand(
//       'disable',
//       'Disable a module for the server',
//       id('module-disable', (ChatContext ctx, GuildModule module) async {
//         var modules = ctx.guild!.modules.enableModules ?? await ctx.guild!.modules.fetchModules();

//         final respondBuilder = MessageBuilder(content: 'Disabled module `$module`');

//         if (modules == null || !modules.contains(module)) {
//           await ctx.respond(MessageBuilder(content: 'Module `$module` is already disabled.'));
//         } else {
//           await ctx.guild!.modules.alterModules([module]);
//           await ctx.respond(respondBuilder);
//         }
//       }),
//     ),
//   ],
//   checks: [
//     GuildCheck.all(name: 'module-guild'),
//   ],
// );
