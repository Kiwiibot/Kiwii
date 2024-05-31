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

import 'dart:math';

import 'package:duration/duration.dart' as duration;
import 'package:duration/locale.dart' as duration;
import 'package:nyxx/nyxx.dart';

import '../translations.g.dart';
import 'constants.dart';

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

EmbedBuilder mergeEmbeds(EmbedBuilder embedBuilder1, EmbedBuilder embedBuilder2) {
  final embed = EmbedBuilder(
    title: embedBuilder1.title ?? embedBuilder2.title,
    description: embedBuilder1.description ?? embedBuilder2.description,
    url: embedBuilder1.url ?? embedBuilder2.url,
    timestamp: embedBuilder1.timestamp ?? embedBuilder2.timestamp,
    color: embedBuilder1.color ?? embedBuilder2.color,
    footer: embedBuilder1.footer ?? embedBuilder2.footer,
    image: embedBuilder1.image ?? embedBuilder2.image,
    thumbnail: embedBuilder1.thumbnail ?? embedBuilder2.thumbnail,
    author: embedBuilder1.author ?? embedBuilder2.author,
    fields: [...?embedBuilder1.fields, ...?embedBuilder2.fields],
  );

  return embed;
}

EmbedBuilder cutEmbed(EmbedBuilder embed) => EmbedBuilder(
      author: embed.author != null
          ? EmbedAuthorBuilder(
              name: cutText(embed.author!.name, embedAuthorNameLimit),
              iconUrl: embed.author?.iconUrl,
            )
          : null,
      title: embed.title != null ? cutText(embed.title!, embedTitleLimit) : null,
      description: embed.description != null ? cutText(embed.description!, embedDescriptionLimit) : null,
      url: embed.url,
      timestamp: embed.timestamp,
      color: embed.color,
      footer: embed.footer != null
          ? EmbedFooterBuilder(
              text: cutText(embed.footer!.text, embedFooterLimit),
              iconUrl: embed.footer?.iconUrl,
            )
          : null,
      image: embed.image,
      thumbnail: embed.thumbnail,
      fields: embed.fields
          ?.map((field) => EmbedFieldBuilder(
                name: cutText(field.name, embedFieldNameLimit),
                value: cutText(field.value, embedFieldValueLimit),
                isInline: field.isInline,
              ))
          .toList(),
    );

String messageLink(Snowflake messageId, Snowflake channelId, Snowflake guildId) => 'https://discord.com/channels/$guildId/$channelId/$messageId';
