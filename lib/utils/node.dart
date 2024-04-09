// A wrapper for nodejs to eval javascript code.
// Yeah, bootiful.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

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

  final process = await Process.run('/home/mleresche/.nvm/versions/node/v20.9.0/bin/node', ['-e', preamble]);

  if (process.exitCode != 0) {
    throw Exception(process.stderr.toString().replaceAll('mleresche', 'kiwii'));
  }

  return process.stdout.toString();
}

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
      'language': 'nodejs',
      'files': [
        {'content': preamble},
      ],
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