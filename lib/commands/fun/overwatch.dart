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

import 'dart:convert';

import 'package:dartx/dartx.dart' hide StringCapitalizeExtension;
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:overfast_api/heroes/heroes_data.dart';
import 'package:overfast_api/overfast_api.dart';
import 'package:overfast_api/players/player.dart';
import 'package:overfast_api/utils/types.dart' as types;

import '../../kiwii.dart';
import '../../plugins/localization.dart';
import '../../translations.g.dart';
import '../../utils/constants.dart';

final client = Overfast();

const overwatch2Year = 2077;

String s(String v) => utf8.decode(utf8.encode(v));

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
                for (var (k, v) in source.entries.$) {
                  if (k == 'time_played') {
                    v = prettyDuration(Duration(seconds: v), t.$meta.locale);
                  }

                  if (v is Map) {
                    v = [for (final (key, value) in v.entries.$) '${formatKey(key, t)}: **$value**'].join('\n');
                  }

                  embed.addField(
                    name: formatKey(k, t, onlyCapital: true),
                    value: separateThousands(v.toString(), t.general.thousandsSeparator),
                    isInline: true,
                  );
                }
              }

              void getMostPlayedHero(Map<String, StatsRecap> source) {
                String name = t.general.nonAvailable;
                Duration timePlayed = Duration.zero;
                for (final (k, v) in source.entries.$) {
                  if (v.timePlayed > timePlayed) {
                    name = k;
                    timePlayed = v.timePlayed;
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

              final selectedHero =
                  heroes.firstOrNullWhere((element) => element.name.toLowerCase() == heroName.toLowerCase() || element.key.name == heroName.toLowerCase());
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
                description: s(hero.description),
              );

              if (hero.hitpoints != null) {
                final healthEmoji = '<:Health:1298260216848056381>';
                final armourEmoji = '<:Armour:1298260720147759155>';
                final shieldsEmoji = '<:Shields:1298260692712816723>';

                // Every 25 HP is 1 health point, so we calculate how many repetitions of the health emoji we need
                final (health, armour, shields) = calculateHealthPoints(hero.hitpoints!.cast<String, int>());

                final healthBar = StringBuffer(healthEmoji * health);

                if (armour > 0) {
                  healthBar.write(armourEmoji * armour);
                }

                if (shields > 0) {
                  healthBar.write(shieldsEmoji * shields);
                }

                embed.addField(
                  name: t.overwatch.hitpoints,
                  value: [
                    for (final (k, v) in hero.hitpoints!.entries.$) '${formatKey(k, t)}: **$v**',
                  ].join('\n'),
                  isInline: true,
                );

                embed.addField(name: '\u200b', value: healthBar.toString());
              }

              embed.addField(name: t.overwatch.role, value: hero.role.name.capitalize, isInline: true);
              embed.addField(name: t.overwatch.location, value: s(hero.location), isInline: true);
              embed.addField(name: t.overwatch.age, value: hero.age.toString(), isInline: true);
              embed.addField(
                name: t.overwatch.dateofBirth,
                value: hero.birthday == null ? t.general.nonAvailable : '${s(hero.birthday.toString())} ${overwatch2Year - hero.age}',
                isInline: true,
              );
              embed.addBlankField(isInline: true);

              final abilities = <String>[];

              for (final ability in hero.abilities) {
                final staticName = ability.video.thumbnail.split('/').last.split('.').first;
                final split = staticName.split('_');
                String hName = split.first;
                String name = split.skip(1).join('_');
                // Blizzard is inconsistent with their naming, so we have to do this :skull_emoji:
                if (hName case 'PHARAH') {
                  hName = 'Pharah';
                }
                if (ability.video.link.webm.contains('DVaSelfDestruct')) {
                  name = 'SELFDESTRUCT';
                } else if (staticName case 'Overrun' || 'Cardiac' || 'Berserker' || 'Cage_fight') {
                  hName = 'Mauga';
                  name = split.join('_');
                } else if (staticName case 'Void_Accelerator' || 'Void_Barrier' || 'Pummel' || 'Ravenous_Vortex' || 'Annihilation') {
                  hName = 'Ramattra';
                  name = split.join('_');
                } else if (hName case 'JUNKER') {
                  hName = 'JUNKER_QUEEN';
                  name = split.skip(2).join('_');
                } else if (staticName case 'Pig_Pen_Poster') {
                  hName = 'ROADHOG';
                  name = 'PIGPEN';
                } else if (hName case 'Sombra' when name == 'Virus') {
                  hName = 'SOMBRA';
                  name = 'VIRUS';
                } else if (staticName case 'WRECKING_GRAPPLING_CLAW' when selectedHero.key == types.HeroKey.widowmaker) {
                  hName = 'WIDOWMAKER';
                  name = 'GRAPPLINGHOOK';
                } else if (staticName case 'Primary_Fire' || 'Dash' || 'Burrow' || 'Ult') {
                  hName = 'VENTURE';
                  name = staticName;
                } else if (staticName == 'WRECKING_GRAPPLING_CLAW') {
                  hName = 'WRECKING_BALL';
                  name = 'GRAPPLING_CLAW';
                } else if (hName case 'WRECKING') {
                  hName = 'WRECKING_BALL';
                  name = split.skip(2).join('_');
                } else if (staticName case 'WINSTON_PROJECTEDBARRIER' when selectedHero.key == types.HeroKey.zarya) {
                  hName = 'ZARYA';
                  name = 'PROJECTEDBARRIER';
                }
                final emoji = overwatchEmojisMappings[hName]?[name];
                abilities.add('${emoji ?? ''} \u2014 ${s(ability.name)} - ${s(ability.description)}');
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
              String getCorrectUrl(String url, Ability ability) {
                if (selectedHero.key == types.HeroKey.widowmaker &&
                    ability.icon.split('/').last.split('.').first == '72fec7acac37ad840835839e72f368134498583686e91f7e30fe5d48aa44f7a1') {
                  return 'https://cdn.kiwii.rapougnac.moe/WidowmakerGraplingHook.png';
                } else if (selectedHero.key == types.HeroKey.zarya &&
                    ability.icon.split('/').last.split('.').first == '6e42984ee8329a50e9c2460ae2df7670d7be9846a093c336e4576d1eea1fb2f1') {
                  return 'https://cdn.kiwii.rapougnac.moe/ZaryaProjectedBarrier.png';
                }
                return url;
              }

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
                            url: Uri.parse(
                              getCorrectUrl(ability.video.thumbnail, ability),
                            ),
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
                          description: s(chapter.content),
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

(int, int, int) calculateHealthPoints(Map<String, int> hitpoints) {
  final health = hitpoints['health']! ~/ 25;
  final armour = hitpoints['armor']! ~/ 25;
  final shields = hitpoints['shields']! ~/ 25;

  return (health, armour, shields);
}

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
  final loc = switch (ctx.guild.t.$meta.locale) {
    AppLocale.enGb => types.Locale.enGb,
    AppLocale.frFr => types.Locale.frFr,
  };

  final heroes = await client.heroes.heroes(locale: loc);
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
