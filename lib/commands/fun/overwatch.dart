import 'dart:convert';

import 'package:dartx/dartx.dart' hide StringCapitalizeExtension;
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:overfast_api/overfast_api.dart';
import 'package:overfast_api/players/player.dart';
import 'package:overfast_api/utils/types.dart' as types;

import '../../kiwii.dart';
import '../../plugins/localization.dart';
import '../../translations.g.dart';
import '../../utils/constants.dart';

final client = Overfast();

final linkedAccounts = <Snowflake, String>{Snowflake(253554702858452992): 'Rapougnac-2980', Snowflake(444074251079778314): 'RaskieL#2546'};

final overwatchCommand = ChatGroup(
  'overwatch',
  'View the overwatch-related informations about a user',
  children: [
    ChatGroup(
      'profile',
      'Yeah',
      children: [
        ChatCommand(
          'summary',
          'Provides summarized stats for a profile',
          id(
            'overwatch-profile-summary',
            (ChatContext ctx, [Member? member]) async {
              final t = ctx.guild.t;
              member ??= ctx.member;
              final profileId = linkedAccounts[member?.id ?? ctx.user.id];
              final summary = await client.players.player(profileId!).summary();

              final embed = EmbedBuilder(
                color: DiscordColor(0xffa500),
                author: EmbedAuthorBuilder(
                  name: summary.username,
                  iconUrl: Uri.https('cdn.kiwii.rapougnac.moe', '/ow-endorsement-lvl-${summary.endorsement.level}.png'),
                ),
                thumbnail: EmbedThumbnailBuilder(
                  url: Uri.parse(summary.avatar ?? ''),
                ),
                description: t.overwatch.profileSummary,
              );

              if (summary.namecard != null) {
                embed.image = EmbedImageBuilder(url: Uri.parse(summary.namecard!));
              }

              // ignore: strict_raw_type
              void formatMap(Map source) {
                for (var MapEntry(:key, :value) in source.entries) {
                  if (key == 'time_played') {
                    value = prettyDuration(Duration(seconds: value), t.$meta.locale);
                  }

                  if (value is Map) {
                    value = [for (final MapEntry(key: k, value: v) in value.entries) '${formatKey(k, t)}: **$v**'].join('\n');
                  }

                  embed.addField(
                      name: formatKey(key, t, onlyCapital: true), value: separateThousands(value.toString(), t.general.thousandsSeparator), isInline: true);
                }
              }

              void getMostPlayedHero(Map<String, StatsRecap> source) {
                String name = t.general.nonAvailable;
                Duration timePlayed = Duration.zero;
                for (final MapEntry(:key, :value) in source.entries) {
                  if (value.timePlayed > timePlayed) {
                    name = key;
                    timePlayed = value.timePlayed;
                  }
                }

                embed.addField(
                  name: t.overwatch.mostPlayedHero,
                  value: '**${name.capitalize}** \u2014 (${prettyDuration(timePlayed, ctx.guild?.t.$meta.locale ?? AppLocale.enGb)})',
                );
              }

              final stats = await client.players.player(profileId).statsSummary();
              final general = stats.general;
              final heroes = stats.heroes;

              formatMap(general.toJson());
              getMostPlayedHero(heroes);

              await ctx.respond(MessageBuilder(embeds: [embed]));
            },
          ),
        ),
        ChatCommand(
          'link',
          'Link your Discord and Battle.net account',
          id(
            'overwatch-profile-link',
            (ChatContext ctx) {},
          ),
        )
      ],
    ),
    ChatGroup(
      'info',
      'Shows informations about a hero, map or idk',
      children: [
        ChatCommand(
          'hero',
          'Shows infos about a hero',
          id(
            'overwatch-info-hero',
            (
              ChatContext ctx,
              @Name('hero') @Description('The hero to show infos about') @Autocomplete(heroesAutocomplete) String heroName,
            ) async {
              final t = ctx.guild.t;
              final heroes = await client.heroes.heroes(locale: appLocaleToBlizz(t.$meta.locale));

              final selectedHero = heroes.firstOrNullWhere((element) => element.name.toLowerCase() == heroName.toLowerCase());
              if (selectedHero == null) {
                return ctx.send(t.overwatch.notFount);
              }

              final hero = await client.heroes.hero(selectedHero.key, locale: appLocaleToBlizz(t.$meta.locale));
              final embed = EmbedBuilder(
                color: DiscordColor(0xffa500),
                thumbnail: EmbedThumbnailBuilder(
                  url: Uri.parse(hero.portrait!),
                ),
                title: hero.name,
                description: utf8.decode(utf8.encode(hero.description)),
              );

              if (hero.hitpoints != null) {
                embed.addField(
                  name: t.overwatch.hitpoints,
                  value: [
                    for (final MapEntry(:key, :value) in hero.hitpoints!.entries) '${formatKey(key, t)}: **$value**',
                  ].join('\n'),
                  isInline: true,
                );
              }

              embed.addField(name: t.overwatch.role, value: hero.role.name.capitalize, isInline: true);
              embed.addField(name: t.overwatch.location, value: hero.location, isInline: true);
              // embed.addField(name: 'Age', value: hero.age.toString(), isInline: true);
              // embed.addField(name: 'Birthday', value: hero.birthday ?? 'Unknown', isInline: true);
              embed.addBlankField(isInline: true);

              final abilities = <String>[];

              for (final ability in hero.abilities) {
                final staticName = ability.video.thumbnail.split('/').last.split('.').first;
                final split = staticName.split('_');
                final emoji = overwatchEmojisMappings[split.first]![split.skip(1).join('_')]!;
                abilities.add('$emoji \u2014 ${ability.name} - ${ability.description}');
              }

              List<String>? abilities2;

              if (abilities.join('\n\n').length > 1024) {
                abilities2 = abilities.sublist(abilities.length ~/ 2);
                abilities.removeRange(abilities.length ~/ 2, abilities.length);
              }

              final abilitiesId = ComponentId.generate(allowedUser: ctx.user.id);
              final storyId = ComponentId.generate(allowedUser: ctx.user.id);

              final row = ActionRowBuilder(
                components: [
                  ButtonBuilder.primary(
                    customId: abilitiesId.toString(),
                    label: t.overwatch.abilities,
                  ),
                  if (hero.story.chapters.isNotEmpty)
                    ButtonBuilder.danger(
                      customId: storyId.toString(),
                      label: t.overwatch.story,
                    ),
                ],
              );

              embed.addField(name: t.overwatch.abilities, value: abilities.join('\n\n'));
              if (abilities2 != null) {
                embed.addField(name: '\u200b', value: abilities2.join('\n\n'));
              }

              final msg = await ctx.respond(MessageBuilder(embeds: [embed], components: [row]));
              final buttonCtx = await ctx.getButtonPress(msg);
              if (buttonCtx.parsedComponentId == abilitiesId) {
                final paginated = await pagination.generate(
                  (index) {
                    final ability = hero.abilities[index];
                    return MessageBuilder(
                      embeds: [
                        EmbedBuilder(
                          thumbnail: EmbedThumbnailBuilder(
                            url: Uri.parse(ability.icon),
                          ),
                          description: ability.description,
                          title: ability.name,
                          url: Uri.parse(ability.video.link.webm),
                          author: EmbedAuthorBuilder(
                            name: hero.name,
                            iconUrl: Uri.parse(hero.portrait!),
                          ),
                          color: DiscordColor(0xffa500),
                          image: EmbedImageBuilder(
                            url: Uri.parse(ability.video.thumbnail),
                          ),
                        ),
                      ],
                    );
                  },
                  pages: hero.abilities.length,
                  userId: ctx.user.id,
                  options: PaginationOptions(
                    timeout: const Duration(minutes: 1),
                  ),
                );
                return buttonCtx.respond(paginated);
              } else if (buttonCtx.parsedComponentId == storyId) {
                final story = hero.story;
                final embed = EmbedBuilder(
                  color: DiscordColor(0xffa500),
                  title: t.overwatch.story,
                  description: story.summary,
                  thumbnail: EmbedThumbnailBuilder(
                    url: Uri.parse(hero.portrait!),
                  ),
                );

                final chaptersId = ComponentId.generate(allowedUser: ctx.user.id);

                final row = ActionRowBuilder(
                  components: [
                    ButtonBuilder.primary(
                      customId: chaptersId.toString(),
                      label: t.overwatch.chapters,
                    ),
                  ],
                );

                final paginated = await pagination.generate(
                  (index) {
                    final chapter = story.chapters[index];
                    return MessageBuilder(
                      embeds: [
                        EmbedBuilder(
                          color: DiscordColor(0xffa500),
                          title: chapter.title,
                          description: utf8.decode(utf8.encode(chapter.content)),
                          image: EmbedImageBuilder(
                            url: Uri.parse(chapter.picture),
                          ),
                        ),
                      ],
                    );
                  },
                  pages: story.chapters.length,
                  userId: ctx.user.id,
                  options: PaginationOptions(
                    timeout: const Duration(minutes: 3),
                  ),
                );

                final msgStory = await buttonCtx.respond(MessageBuilder(embeds: [embed], components: [row]));

                final storyButtonCtx = await ctx.getButtonPress(msgStory);

                if (storyButtonCtx.parsedComponentId == chaptersId) {
                  return storyButtonCtx.respond(paginated);
                }
              }
            },
          ),
        ),
      ],
    ),
  ],
);

types.Locale appLocaleToBlizz(AppLocale locale) => switch (locale) {
      AppLocale.enGb => types.Locale.enGb,
      AppLocale.frFr => types.Locale.frFr,
    };

String formatKey(String key, Translations t, {bool onlyCapital = false}) => switch (key) {
      'best' => onlyCapital ? t['overwatch.${snakeToCamel(key)}'] : '${t['overwatch.${snakeToCamel(key)}']} (${t.overwatch.mostInGame})',
      'average' => onlyCapital ? t['overwatch.${snakeToCamel(key)}'] : '${t['overwatch.${snakeToCamel(key)}']} (${t.overwatch.per10Min})',
      _ => t['overwatch.${snakeToCamel(key)}'],
    };

// String translateKey(String key) {}

Future<Iterable<CommandOptionChoiceBuilder<dynamic>>> heroesAutocomplete(AutocompleteContext ctx) async {
  final heroes = await client.heroes.heroes(locale: types.Locale.frFr);
  final current = ctx.currentValue.toLowerCase();
  final filtered = heroes.where((element) => element.name.toLowerCase().contains(current) || element.key.name.contains(current)).take(25).toList();
  return filtered.map((e) => CommandOptionChoiceBuilder(name: e.name, value: e.name));
}

// Parse the battle tag, which is in the form of "name#1234", or "name-1234"
String? parseBattleTag(String battleTag) {
  final match = RegExp(r'(\w+)[#\-](\d+)').firstMatch(battleTag);
  if (match == null) {
    return null;
  }

  return '${match.group(1)}-${match.group(2)}';
}
