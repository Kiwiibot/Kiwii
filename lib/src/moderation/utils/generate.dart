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

import 'package:dartx/dartx.dart';
import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../../../database.dart';
import '../../../kiwii.dart';
import '../../../translations.g.dart';
import '../appeal/create_appeal.dart';
import '../case/create_case.dart';
import 'strings.dart';

enum HistoryType {
  // ignore: constant_identifier_names
  case_,
  report,
}

enum Colours {
  lime._(0x7ef31f),
  green._(0x80f31f),
  greenYellow._(0xa5de0b),
  yellow._(0xc7c101),
  orangeYellow._(0xe39e03),
  orange._(0xf6780f),
  red._(0xfe5326),
  crimson._(0xfb3244),
  unknown._(0x5865f2);

  final int value;

  const Colours._(this.value);
}

typedef HistoryRecord = ({DateTime createdAt, String identifierLabel, Uri identifierUri, String label, String? description});

Future<EmbedBuilder> generateHistory(({Member? member, User user}) target, Snowflake guildId, Translations t, [HistoryType type = HistoryType.case_]) async {
  final embed = generateUserInfo(target, t);

  return switch (type) {
    HistoryType.case_ => mergeEmbeds(await generateCaseHistory(target, guildId, t), embed),
    _ => embed,
  };
}

Future<EmbedBuilder> generateCaseHistory(({Member? member, User user}) target, Snowflake guildId, Translations t) async {
  final db = GetIt.I.get<AppDatabase>();
  final guildSettings = await db.getGuild(guildId);
  final cases = await (db.cases.select()
        ..where((tbl) => tbl.guildId.equalsValue(guildId) & tbl.targetId.equalsValue(target.user.id) & tbl.action.isNotIn([1, 8]))
        ..orderBy([(u) => OrderingTerm(expression: u.createdAt, mode: OrderingMode.desc)]))
      .get();

  final caseFolded = cases.fold<Map<CaseAction, int>>({}, (acc, c) {
    final action = c.action;
    acc.update(action, (value) => value + 1, ifAbsent: () => 1);
    return acc;
  });

  // // Add 0s for missing actions
  // for (final action in CaseAction.values) {
  //   if (!caseFolded.containsKey(action)) {
  //     caseFolded[action] = 0;
  //   }
  // }

  // final values = caseFolded.values.toList();
  final values = [
    caseFolded.getOrElse(CaseAction.role, () => 0),
    caseFolded.getOrElse(CaseAction.warn, () => 0),
    caseFolded.getOrElse(CaseAction.kick, () => 0),
    caseFolded.getOrElse(CaseAction.softBan, () => 0),
    caseFolded.getOrElse(CaseAction.ban, () => 0),
    caseFolded.getOrElse(CaseAction.unban, () => 0),
    caseFolded.getOrElse(CaseAction.timeout, () => 0)
  ];
  final coloursIndex = min(values.isEmpty ? 0 : values.reduce((a, b) => a + b), Colours.values.length - 1);

  final records = cases.map<HistoryRecord>(
    (case_) => (
      createdAt: case_.createdAt.dateTime,
      identifierLabel: '#${case_.caseId}',
      identifierUri: Uri.https('discord.com', '/channels/$guildId/${guildSettings.modLogChannelId}/${case_.logMessageId}'),
      label: formatCaseAction(case_.action, t),
      description: case_.reason,
    ),
  );

  return generateHistoryEmbed(
    target.user,
    t.moderation.history.cases.title,
    Colours.values[coloursIndex].value,
    records,
    actionSummary(values, t),
    t,
  );
}

String actionSummary(List<int> actions, Translations t) {
  final [restrictions, warns, kicks, softbans, bans, unbans, timeout] = actions;

  return [
    t.moderation.history.cases.summary.restriction(n: restrictions),
    t.moderation.history.cases.summary.warning(n: warns),
    t.moderation.history.cases.summary.kick(n: kicks),
    t.moderation.history.cases.summary.softban(n: softbans),
    t.moderation.history.cases.summary.ban(n: bans),
    t.moderation.history.cases.summary.unban(n: unbans),
    t.moderation.history.cases.summary.timeout(n: timeout),
  ].join(', ');
}

EmbedBuilder generateHistoryEmbed(User author, String title, int colour, Iterable<HistoryRecord> records, String footerText, Translations t) {
  return EmbedBuilder(
    description: <String>[
      if (records.isEmpty)
        t.moderation.common.errors.noHistory
      else
        for (final record in records)
          '${formatDate(record.createdAt, TimestampStyle.shortDate)} ${inlineCode(record.label)} ${hyperlink(record.identifierLabel, record.identifierUri.toString())} ${record.description ?? ''}'
    ].join('\n'),
    title: title,
    color: DiscordColor(colour),
    footer: EmbedFooterBuilder(text: footerText),
    author: EmbedAuthorBuilder(
      name: '${author.tag} (${author.id})',
      iconUrl: author.avatar.url,
    ),
  );
}

EmbedBuilder generateUserInfo(({Member? member, User user}) target, Translations t) {
  final since = formatDate(target.user.id.timestamp, TimestampStyle.relativeTime);
  final createdAt = formatDate(target.user.id.timestamp, TimestampStyle.shortDateTime);

  final embed = EmbedBuilder(
    author: EmbedAuthorBuilder(
      name: '${target.user.tag} (${target.user.id})',
      iconUrl: target.user.avatar.url,
    ),
    color: DiscordColor(0x5865f2),
    fields: [
      EmbedFieldBuilder(
        name: t.moderation.history.common.userDetails.title,
        value: t.moderation.history.common.userDetails.description(
          mention: target.user.mention,
          tag: target.user.tag,
          id: target.user.id,
          created: createdAt,
          createdSince: since,
          createdAtTimestamp: target.user.id.timestamp.millisecondsSinceEpoch,
        ),
        isInline: false,
      ),
    ],
  );

  if (target.member != null) {
    final joinedAt = formatDate(target.member!.joinedAt, TimestampStyle.shortDateTime);
    final joinedSince = formatDate(target.member!.joinedAt, TimestampStyle.relativeTime);

    final nonDefaultRoles = target.member!.roles.where((role) => role.id != target.member?.manager.guildId);

    embed.addField(
      name: t.moderation.history.common.memberDetails.title,
      value: [
        if (target.member?.nick != null) t.moderation.history.common.memberDetails.description.nickname(nickname: target.member!.nick!),
        if (nonDefaultRoles.isNotEmpty)
          t.moderation.history.common.memberDetails.description.roles(n: nonDefaultRoles.length, roles: nonDefaultRoles.map((r) => r.mention).join(', ')),
        t.moderation.history.common.memberDetails.description.joined(
          joined: joinedAt,
          joinedSince: joinedSince,
          joinedAtTimestamp: target.member!.joinedAt.millisecondsSinceEpoch,
        ),
      ].join('\n'),
      isInline: false,
    );
  }

  return embed;
}

Future<String> generateCaseLog(Case ccase, Snowflake logChannelId, Translations t, String prefix) async {
  final client = GetIt.I.get<NyxxGateway>();
  final logger = GetIt.I.get<Logger>();
  final db = GetIt.I.get<AppDatabase>();

  var action = formatCaseAction(ccase.action, t);

  if (ccase.action case CaseAction.role || CaseAction.unrole when ccase.roleId != null) {
    try {
      final guild = await client.guilds.get(ccase.guildId);
      final role = await guild.roles.get(ccase.roleId!);

      action += ' `@${role.name}` (${role.id})';
    } catch (e) {
      logger.warning('Failed to fetch role for case ${ccase.caseId}', e);
    }
  }

  var msg = t.moderation.logs.cases.description(targetTag: ccase.targetTag, targetID: ccase.targetId, action: action);

  if (ccase.actionExpiration != null) {
    msg += t.moderation.logs.cases.expiration(time: formatDate(ccase.actionExpiration!, TimestampStyle.relativeTime));
  }

  if (ccase.contextMessageId != null) {
    // TODO: Fetch message
  }

  if (ccase.reason != null) {
    msg += t.moderation.logs.cases.reason(reason: ccase.reason!);
  } else {
    msg += t.moderation.logs.cases.reasonFallback(prefix: prefix, caseId: ccase.caseId);
  }

  if (ccase.refId != null) {
    final reference = await db.getCase(ccase.refId!, ccase.guildId);

    msg += t.moderation.logs.cases.caseReference(
      action: formatCaseAction(reference.action, t),
      ref: hyperlink('#${ccase.refId}', 'https://discord.com/channels/${ccase.guildId}/$logChannelId/${reference.logMessageId}'),
    );
  }

  if (ccase.reportRefId != null) {
    // TODO: Fetch report
  }

  return msg;
}

Future<EmbedBuilder> generateCaseEmbed(Snowflake guildId, Snowflake logChannelId, Case ccase, Translations t, String prefix, [User? user]) async {
  final embed = EmbedBuilder(
    color: DiscordColor(generateCaseColour(ccase.action).value),
    description: await generateCaseLog(ccase, logChannelId, t, prefix),
    footer: EmbedFooterBuilder(text: t.moderation.logs.cases.footer(caseId: ccase.caseId)),
    timestamp: ccase.createdAt.dateTime.toUtc(),
    author: user != null
        ? EmbedAuthorBuilder(
            name: '${user.tag} (${user.id})',
            iconUrl: user.avatar.url,
          )
        : null,
  );

  if (user != null) {
    embed.author = EmbedAuthorBuilder(
      name: '${user.tag} (${user.id})',
      iconUrl: user.avatar.url,
    );
  }

  return embed;
}

Colours generateCaseColour(CaseAction action) => switch (action) {
      CaseAction.role || CaseAction.warn || CaseAction.timeout => Colours.yellow,
      CaseAction.kick || CaseAction.softBan => Colours.orangeYellow,
      CaseAction.ban => Colours.red,
      CaseAction.unban => Colours.green,
      _ => Colours.unknown,
    };

Future<EmbedBuilder> generateAppealEmbed(Appeal appeal, User user, Translations t, [User? mod]) async {
  final footerText = switch (appeal.status) {
    AppealStatus.accepted => t.moderation.logs.appeals.footerAccepted(moderator: mod!.tag),
    AppealStatus.denied => t.moderation.logs.appeals.footerRejected(moderator: mod!.tag),
    _ => t.moderation.logs.appeals.footer,
  };

  final embed = EmbedBuilder(
    title: t.moderation.logs.appeals.title,
    description: t.moderation.logs.appeals.description(
      user: user.mention,
      caseId: appeal.refId!,
      reason: appeal.reason!,
      userID: user.id,
      userTag: user.tag,
    ),
    author: EmbedAuthorBuilder(
      name: user.tag,
      iconUrl: user.avatar.url,
    ),
    footer: EmbedFooterBuilder(
      text: footerText,
    ),
    color: DiscordColor(0x5865f2),
  );

  return embed;
}

Future<List<ActionRowBuilder>> generateAppealComponents(Appeal appeal, User user, Translations t) async {
  final List<ActionRowBuilder> components = switch (appeal.status) {
    AppealStatus.accepted => [],
    AppealStatus.denied => [],
    _ => [
        ActionRowBuilder(
          components: [
            ButtonBuilder(
              style: ButtonStyle.primary,
              label: t.moderation.buttons.appealApprove,
              customId: 'appeal-accept-${appeal.refId}-${user.id}',
            ),
            ButtonBuilder(
              style: ButtonStyle.danger,
              label: t.moderation.buttons.appealReject,
              customId: 'appeal-reject-${appeal.refId}-${user.id}',
            ),
          ],
        ),
      ],
  };

  return components;
}
