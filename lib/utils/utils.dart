import 'dart:math';

import 'package:duration/duration.dart' as duration;
import 'package:duration/locale.dart' as duration;
import 'package:nyxx/nyxx.dart';

import '../translations.g.dart';

export 'extensions.dart';
export 'io/stderr.dart';
export 'io/stdout.dart';
export 'markov.dart';

String cutText(String str, int length) {
  if (str.length <= length) {
    return str;
  }

  return '${str.substring(0, length - 3)}...';
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

String prettyDuration(Duration amount, [AppLocale locale = AppLocale.enGb]) {
  final map = {
    AppLocale.enGb: duration.EnglishDurationLocale(),
    AppLocale.frFr: duration.FrenchDurationLocale(),
  };

  return duration.prettyDuration(amount, locale: map[locale]!);
}

// ignore: strict_raw_type
Map reverseMap(Map map) => {for (var e in map.entries) e.value: e.key};

String separateThousands(String number, [String separator = ',']) {
  return number.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}$separator');
}

String snakeToCamel(String input) {
  var words = input.split('_');
  return words[0].toLowerCase() + words.skip(1).map((e) => e[0].toUpperCase() + e.substring(1)).join();
}

// AppLocale discordLocaleToAppLocale(Locale locale) => discord
