import 'dart:math';

import 'package:nyxx/nyxx.dart';

export 'markov.dart';
export 'snowflake.dart';
export 'io/stderr.dart';
export 'io/stdout.dart';

String? pickByWeights(Map<String, int> entries) {
  final sum = entries.values.reduce((value, element) => value + element);
  final chosen = Random().nextInt(sum);

  int accumulated = 0;
  for (final MapEntry(:key, :value) in entries.entries) {
    accumulated += value;
    if (accumulated > chosen) {
      return key;
    }
  }

  return null;
}

String getAllContent(Message message) {
  var output = <String>[];
  if (message.content.isNotEmpty) {
    output.add(message.content);
  }
  if (message.embeds.isNotEmpty) {
    for (final embed in message.embeds) {
      if (embed.author?.name.isNotEmpty == true) {
        output.add(embed.author!.name);
      }
      if (embed.title?.isNotEmpty == true) {
        output.add(embed.title!);
      }
      if (embed.description?.isNotEmpty == true) {
        output.add(embed.description!);
      }
      if (embed.fields?.isNotEmpty == true) {
        for (final field in embed.fields!) {
          output.add('${field.name}\n${field.value}');
        }
      }
      if (embed.footer?.text.isNotEmpty == true) {
        output.add(embed.footer!.text);
      }
    }
  }

  return output.join('\n');
}

String cutText(String str, int length) {
  if (str.length <= length) {
    return str;
  }

  return '${str.substring(0, length - 3)}...';
}

extension StringExtension on String {
  String get firstLetterUpperCase => '${this[0].toUpperCase()}${substring(1)}';
}

String formatBytes(int bytes, [int decimals = 2]) {
  if (bytes == 0) {
    return '0 Bytes';
  }

  const k = 1024;
  final dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

  final i = (log(bytes) / log(k)).floor();

  return '${(bytes / pow(k, i)).toStringAsFixed(dm)} ${sizes[i]}';
}
