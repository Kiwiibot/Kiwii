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

import 'dart:io';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:kiwii/src/checks/checks.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:dart_eval/dart_eval.dart' hide eval;
import 'package:nyxx_commands/dart_eval_bindings.dart';

final evalCommand = ChatCommand(
  'eval',
  'Evaluates a Dart expression.',
  checks: [adminCheck],
  id('eval', (MessageChatContext ctx, String code) async {
    // ctx.
    final result = await eval('dynamic main(ctx) async {  return $code; }', args: [
      $MessageChatContext.wrap(ctx),
    ]);

    await ctx.respond(MessageBuilder(content: result.toString()));
  }),
  options: CommandOptions(
    type: CommandType.textOnly,
  ),
);

/// Evaluate the Dart [source] code. If the source is a raw expression such as
/// "2 + 2" it will be evaluated directly and the result will be returned;
/// otherwise, the function [function] will be called with arguments specified
/// by [args]. You can use [plugins] to configure bridge classes and
/// [permissions] to grant permissions to the runtime.
/// You can also specify [outputFile] to write the generated EVC bytecode to a
/// file.
///
/// The eval() function automatically unboxes return values for convenience.
// eval without the weird regex check that works half the time
dynamic eval(String source,
    {String function = 'main', List args = const [], List<EvalPlugin> plugins = const [], List<Permission> permissions = const [], String? outputFile}) {
  final compiler = Compiler();
  for (final plugin in plugins) {
    plugin.configureForCompile(compiler);
  }

  final program = compiler.compile({
    'default': {'main.dart': source}
  });

  if (outputFile != null) {
    File(outputFile).writeAsBytesSync(program.write());
  }

  final runtime = Runtime.ofProgram(program);
  for (final plugin in plugins) {
    plugin.configureForRuntime(runtime);
  }

  for (final permission in permissions) {
    runtime.grant(permission);
  }

  runtime.args = args;
  final result = runtime.executeLib('package:default/main.dart', function);

  if (result is $Value) {
    return result.$reified;
  }
  return result;
}


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
