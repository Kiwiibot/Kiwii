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
