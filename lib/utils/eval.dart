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

import 'dart:isolate';

@pragma('vm:entry-point')
Future<Object?> sandboxEval(String code, {List<Object?>? arguments, String? preCode}) async {
  final uri = Uri.dataFromString(
    '''
    import 'dart:isolate';

    void main(_, List<dynamic> messages) async {
      final [SendPort port] = messages;

      try {

        ${preCode ?? ''}

        final result = $code;
        port.send(result);
      } catch (e) {
        port.send(e);
      }
    }
''',
    mimeType: 'application/dart',
  );

  final port = ReceivePort();

  final isolate = await Isolate.spawnUri(
    uri,
    [],
    List.of(
      [
        port.sendPort,
        ...?arguments?.map((e) => e.toString()),
      ],
      growable: false,
    ),
  );

  final result = await port.first;
  port.close();

  if (result is Exception) {
    throw result;
  }

  isolate.kill();

  return result;
}

Future<Object?> eval(String code) async {
  final uri = Uri.dataFromString('''
    import 'dart:isolate';

    void main(_, List<dynamic> messages) async {
      final [SendPort port] = messages;

      try {
        $code
      } catch (e) {
        port.send(e);
      }
    }
''');

  final port = ReceivePort();

  return Isolate.spawnUri(
    uri,
    [],
    [
      port.sendPort,
    ],
  ).then((isolate) async {
    final result = await port.first;
    port.close();

    if (result is Exception) {
      throw result;
    }

    isolate.kill();

    return result;
  });
}
