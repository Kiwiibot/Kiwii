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

// import 'package:kiwii/src/checks/checks.dart';
// import 'package:nyxx/nyxx.dart';
// import 'package:nyxx_commands/nyxx_commands.dart';
// import 'package:dart_eval/dart_eval.dart';

// final evalCommand = ChatCommand(
//   'eval',
//   'Evaluates a Dart expression.',
//   checks: [adminCheck],
//   id('eval', (ChatContext ctx, String code) async {
//     // final mappings = {
//     //   'ctx': {
//     //     if (ctx case MessageChatContext context)
//     //       'message': {
//     //         'content': context.message.content,
//     //       },
//     //     'respond()'
//     //   }
//     // };
//   }),
// );

// Map<String, dynamic> userToMap(User user) => {
//       'id': user.id.toString(),
//       'username': user.username,
//       'discriminator': user.discriminator,
//       'avatar': {
//         'url': user.avatar.url.toString(),
//       },
//       if (user.banner != null)
//         'banner': {
//           'url': user.banner?.url.toString(),
//         },
//       'globalName': user.globalName,
//       'isBot': user.isBot,
//       'isSystem': user.isSystem,
//       'hasMfaEnabled': user.hasMfaEnabled,
//       if (user.accentColor != null)
//         'accentColor': {
//           'r': user.accentColor!.r,
//           'g': user.accentColor!.g,
//           'b': user.accentColor!.b,
//           'toHexString()': user.accentColor!.toHexString(),
//           'toString()': user.accentColor!.toString(),
//         }
//     };
