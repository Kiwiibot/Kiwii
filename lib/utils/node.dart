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

// A wrapper for nodejs to eval javascript code.
// Yeah, bootiful.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Run js code on the piston API
Future<String> runPistonJS(String code, [Map<String, Object?>? context]) async {
  final preamble = '''
  const vm = require('node:vm');
  const dartCtx = ${context != null ? json.encode(context) : '{}'};
  const context = vm.createContext({...dartCtx});
  const script = new vm.Script(decodeURIComponent(`${Uri.encodeComponent(code)}`));
  script.runInContext(context);
  console.log(JSON.stringify(context));
''';

  final response = await http.post(
    Uri.parse('https://emkc.org/api/v2/piston/execute'),
    body: json.encode({
      'language': 'javascript',
      'files': [
        {'content': preamble},
      ],
      'version': '18.15.0',
    }),
    headers: {
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to run piston code: ${response.body}');
  }

  final result = json.decode(response.body);
  return result['run']['stdout'] as String;
}

Future<String> runSandboxedJS(String code, [Map<String, Object?>? context]) async {
  final preamble = '''

  const vm = require('node:vm');
  const dartCtx = ${context != null ? json.encode(context) : '{}'};
  const context = vm.createContext({...dartCtx});
  const script = new vm.Script(decodeURIComponent(`${Uri.encodeComponent(code)}`));
  script.runInContext(context);
  console.log(JSON.stringify(context));

''';

// await File('preamble.js').writeAsString(preamble);

  final process = await Process.run('node', ['-e', preamble]);

  if (process.exitCode != 0) {
    throw Exception(process.stderr.toString());
  }

  return process.stdout.toString();
}
