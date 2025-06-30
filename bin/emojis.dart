import 'dart:io';

import 'package:kiwii/src/settings.dart' as settings;
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  final client = await Nyxx.connectRest(settings.token, options: RestClientOptions(plugins: [Logging(logLevel: Level.FINE)]));

  client.logger.info("Registered as ${(await client.user.get()).tag}");

  final baseFile = File('lib/utils/emojis.dart');
  final contents = StringBuffer('const emojis = {');

  final emojis = await client.application.emojis.list();
  if (baseFile.existsSync() || emojis.isNotEmpty) {
    for (final emoji in emojis) {
      contents.write("  '${emoji.name}': '<:${emoji.name}:${emoji.id}>',\n");
    }
  } else {
    final emojis = Directory('lib/utils/emojis').listSync(recursive: true).whereType<File>().where((f) => !f.path.endsWith('svg'));
    bool hadError = false;
    for (final file in emojis) {
      final name = path.basenameWithoutExtension(file.path);

      final builder = ApplicationEmojiBuilder(name: name, image: await ImageBuilder.fromFile(file));

      try {
        final emoji = await client.application.emojis.create(builder);

        contents.write("  '${emoji.name}': '<:${emoji.name}:${emoji.id}>',");
      } on HttpResponseError {
        hadError = true;
        return;
      }
    }

    if (hadError) {
      final emojis = await client.application.emojis.list();

      for (final emoji in emojis) {
        contents.write("  '${emoji.name}': '<:${emoji.name}:${emoji.id}>',\n");
      }
    }
  }

  contents.write('};');

  await baseFile.writeAsString(contents.toString());

  await client.close();
}
