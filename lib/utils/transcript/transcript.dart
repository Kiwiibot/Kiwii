import 'dart:convert';
import 'dart:typed_data';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:path/path.dart' as path;
import 'package:universal_html/parsing.dart';

final template = path.join(
  'lib',
  'utils',
  'transcript',
  'static',
  'template.html'
);

const sanitizer = HtmlEscape();

final sanitize = sanitizer.convert;

// Future<Uint8List> generateTranscript(Iterable<Message> messages, GuildTextChannel channel) async {
//   final dom = parseHtmlDocument(template.replaceAll('{{TITLE}}', channel.name));
//   final guild = await channel.guild.get();
//   dom.querySelector('preamble__guild-icon').setAttribute('src', guild.icon?.get())
// }
