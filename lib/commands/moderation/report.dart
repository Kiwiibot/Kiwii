import 'dart:async';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:option/option.dart';
import '../../kiwii.dart';
import '../../plugins/localization.dart';
import '../../src/errors/errors.dart';
import '../../src/models/report.dart';
import '../../src/moderation/replies/acknowledge_report.dart';
import '../../src/moderation/replies/forward_report.dart';
import '../../src/moderation/reports/create_report.dart';
import '../../src/moderation/reports/update_report.dart';
import '../../utils/extensions/iterable.dart';

final _reportCommandPermissions = Permissions.sendMessages | Permissions.viewChannel;
final _reportCommandClientPermissions = Permissions.sendMessages | Permissions.viewChannel;

Future<void> userReport(
  InteractionCommandContext ctx,
  ({({User user, Member? member}) user, String reason, Attachment? attachment}) args, [
  Report? pendingReport,
]) async {
  final cache = ctx.client.selfCache;
  final key = 'guild:${ctx.guild!.id}:report:user:${args.user.user.id}';
  final guild = await ctx.guild?.get();

  final (:reason, :attachment, :user) = args;

  final trimmedReason = reason.trim();

  if (attachment != null) {
    final attachmentIsImage = switch (attachment.contentType) {
      'image/png' => true,
      'image/jpeg' => true,
      'image/gif' => true,
      'image/webp' => true,
      _ => false,
    };

    if (!attachmentIsImage) {
      throw InvalidAttachmentException();
    }
  }

  final reportId = ComponentId.generate(allowedUser: ctx.user.id, expirationTime: const Duration(minutes: 2));
  final cancelId = ComponentId.generate(allowedUser: ctx.user.id, expirationTime: const Duration(minutes: 2));

  final reportButton = ButtonBuilder(
    style: pendingReport != null ? ButtonStyle.primary : ButtonStyle.danger,
    customId: reportId.toString(),
    label: guild.t['moderation.report.buttons.${pendingReport != null ? 'forwardAttachment' : 'execute'}'],
  );
  final cancelButton = ButtonBuilder.secondary(customId: cancelId.toString(), label: guild.t.moderation.report.buttons.cancel);
  final trustAndSafetyButton = ButtonBuilder.link(
    label: guild.t.moderation.report.buttons.discordReport,
    url: Uri.parse('https://discord.com/safety/360044103651-reporting-abusive-behavior-to-discord'),
  );

  final s = guild.t['moderation.report.user.pending${pendingReport != null ? 'Forward' : ''}'];

  final contentParts = <String>[
    s is Function ? s(user: '${user.user.mention} - `${user.user.tag}` (${user.user.id})', reason: cutText(trimmedReason, 1500)) : s,
  ];

  if (attachment == null) {
    final reportCommand = ctx is InteractionChatContext ? ctx.client.commands.cache.values.firstWhereOrNull((c) => c.name == 'report') : null;

    contentParts.add(
      guild.t.moderation.report.user.attachmentUpsell.base(
        reportCommand:
            reportCommand != null
                ? guild.t.moderation.report.user.attachmentUpsell.mentions(reportCommand: '</report user:${reportCommand.id}>')
                : guild.t.moderation.report.user.attachmentUpsell.option,
      ),
    );
  }

  contentParts.add(guild.t.moderation.report.common.warnings);

  final embed = EmbedBuilder(
    author: EmbedAuthorBuilder(name: '${user.user.tag} (${user.user.id})', iconUrl: user.user.avatar.url),
    color: const DiscordColor(0x2f3136),
  );

  if (attachment != null) {
    embed.image = EmbedImageBuilder(url: attachment.url);
  }

  final message = await ctx.interaction.updateOriginalResponse(
    MessageUpdateBuilder(
      content: contentParts.join('\n'),
      embeds: [embed],
      components: [
        ActionRowBuilder(components: [cancelButton, reportButton, trustAndSafetyButton]),
      ],
    ),
  );

  ButtonComponentContext? buttonContext;

  try {
    buttonContext = await ctx.getButtonPress(message);
  } on InteractionTimeoutException {
    await ctx.interaction.updateOriginalResponse(MessageUpdateBuilder(content: guild.t.moderation.report.common.errors.timedOut, components: [], embeds: []));
    return;
  }

  if (buttonContext.parsedComponentId == cancelId) {
    await buttonContext.interaction.respond(
      MessageUpdateBuilder(content: guild.t.moderation.report.user.cancel, embeds: [], components: []),
      updateMessage: true,
    );
    return;
  }

  if (buttonContext.parsedComponentId == reportId) {
    await buttonContext.interaction.acknowledge(updateMessage: true);

    if (pendingReport != null) {
      final attachmentUrl = await forwardReport((author: ctx.user, reason: trimmedReason), guild!, attachment, pendingReport);

      await updateReport(UpdateReport(reportId: pendingReport.reportId, guildId: ctx.guild!.id, attachmentUrl: Option.fromNullable(attachmentUrl?.toString()), updatedAt: Some(DateTime.now())));
    } else {
      if (await cache[key].get() != null) {
        await buttonContext.interaction.respond(
          MessageUpdateBuilder(content: guild.t.moderation.report.common.errors.recentlyReported.user, embeds: [], components: []),
          updateMessage: true,
        );
        return;
      }

      await cache[key].set('', const Duration(seconds: 3));

      final report = await createReport(
        CreateReport(
          guildId: guild!.id,
          targetId: user.user.id,
          targetTag: user.user.tag,
          authorId: ctx.user.id,
          authorTag: ctx.user.tag,
          type: ReportType.user,
          attachmentUrl: attachment?.proxiedUrl.toString(),
          reason: trimmedReason,
        ),
      );

      await acknowledgeReport(guild, report);
    }

    await cache[key].set('', const Duration(hours: 12));

    await buttonContext.interaction.respond(
      MessageUpdateBuilder(
        content: guild.t['moderation.report.user.success${pendingReport != null ? 'Forward' : ''}'],
        embeds: [embed],
        components: [
          ActionRowBuilder(components: [trustAndSafetyButton]),
        ],
      ),
      updateMessage: true,
    );
  }
}

Future<void> messageReport(InteractionCommandContext ctx, ({Message message, String reason}) args, [Report? pendingReport]) async {
  final userKey = 'guild:${ctx.guild!.id}:report:user:${args.message.author.id}';
  final guild = ctx.guild!;

  final trimmedReason = args.reason.trim();

  final reportId = ComponentId.generate(allowedUser: ctx.user.id, expirationTime: const Duration(minutes: 2));
  final cancelId = ComponentId.generate(allowedUser: ctx.user.id, expirationTime: const Duration(minutes: 2));

  final reportButton = ButtonBuilder(
    style: pendingReport != null ? ButtonStyle.primary : ButtonStyle.danger,
    customId: reportId.toString(),
    label: guild.t['moderation.report.buttons.${pendingReport != null ? 'forwardAttachment' : 'execute'}'],
  );
  final cancelButton = ButtonBuilder.secondary(customId: cancelId.toString(), label: guild.t.moderation.report.buttons.cancel);
  final trustAndSafetyButton = ButtonBuilder.link(
    label: guild.t.moderation.report.buttons.discordReport,
    url: Uri.parse('https://discord.com/safety/360044103651-reporting-abusive-behavior-to-discord'),
  );

  final s = guild.t['moderation.report.message.pending${pendingReport != null ? 'Forward' : ''}'];

  final contentParts = <String>[
    Function.apply(s, [], {#messageLink: await args.message.url, if (pendingReport == null) #reason: cutText(trimmedReason, 1500)}),
    guild.t.moderation.report.common.warnings,
  ];

  final message = await ctx.interaction.updateOriginalResponse(
    MessageUpdateBuilder(
      content: contentParts.join('\n'),
      embeds: [await formatMessageToEmbed(args.message, guild.t)],
      components: [
        ActionRowBuilder(
          components: [
            cancelButton,
            reportButton,
            trustAndSafetyButton,
            ButtonBuilder.link(url: await args.message.url, label: guild.t.general.common.messageReference),
          ],
        ),
      ],
    ),
  );

  ButtonComponentContext? buttonContext;

  try {
    buttonContext = await ctx.getButtonPress(message);
  } on InteractionTimeoutException {
    await ctx.interaction.updateOriginalResponse(MessageUpdateBuilder(content: guild.t.moderation.report.common.errors.timedOut, components: [], embeds: []));
    return;
  }

  if (buttonContext.parsedComponentId == cancelId) {
    await buttonContext.interaction.respond(
      MessageUpdateBuilder(content: guild.t.moderation.report.message.cancel, embeds: [], components: []),
      updateMessage: true,
    );
    return;
  }

  if (buttonContext.parsedComponentId == reportId) {
    await buttonContext.interaction.acknowledge(updateMessage: true);

    final latestReport = await ctx.client.repositories.reports.getPendingReportByTarget(ctx.guild!.id, args.message.author.id);

    if (latestReport?.contextMessageIds?.contains(args.message.id) ?? false) {
      await buttonContext.interaction.respond(
        MessageUpdateBuilder(content: guild.t.moderation.report.common.errors.recentlyReported.message, embeds: [], components: []),
        updateMessage: true,
      );
      return;
    }

    if (pendingReport != null) {
      await forwardReport((author: buttonContext.user, reason: trimmedReason), guild, args.message, pendingReport);
    } else {
      final messageContext = await (await args.message.channel.get() as GuildTextChannel).messages.fetchMany(around: args.message.id, limit: 20);

      final targetContextMessageIds = messageContext.where((msg) => msg.author.id == args.message.author.id).map((msg) => msg.id);

      final report = await createReport(
        CreateReport(
          guildId: ctx.guild!.id,
          targetId: args.message.author.id,
          targetTag: args.message.author.tag,
          authorId: ctx.user.id,
          authorTag: ctx.user.tag,
          type: ReportType.message,
          messageId: args.message.id,
          channelId: args.message.channelId,
          contextMessageIds: targetContextMessageIds.toList(),
          reason: trimmedReason,
        ),
      );

      await acknowledgeReport(guild, report, args.message, messageContext);
    }

    await ctx.client.selfCache[userKey].set('', const Duration(hours: 12));

    await buttonContext.interaction.respond(
      MessageUpdateBuilder(
        content: guild.t['moderation.report.message.success${pendingReport != null ? 'Forward' : ''}'],
        components: [
          ActionRowBuilder(components: [trustAndSafetyButton]),
        ],
      ),
      updateMessage: true,
    );
  }
}

final reportCommand = ChatGroup(
  'report',
  'Report a message or a user to the server moderators',

  checks: [BasePermissionsCheck(_reportCommandPermissions), BaseSelfPermissionsCheck(_reportCommandClientPermissions)],
  options: KiwiiCommandOptions(
    permissions: _reportCommandPermissions,
    clientPermissions: _reportCommandClientPermissions,
    usage: '',
    examples: [(command: '', description: '')],
    type: CommandType.slashOnly,
    defaultResponseLevel: ResponseLevel.hint,
  ),
  children: [reportUserCommand, reportMessageCommand],
);

final reportMessageCommand = ChatCommand(
  'message',
  'Report a message to the server moderators',
  id('report-message', (ChatContext ctx, Message message, String reason) async {
    Report? pendingReport;
    try {
      pendingReport = await validateReport(ctx.member!, message.author, message);
    } on NoSelfReportException {
      await ctx.respond(MessageBuilder(content: ctx.guild.t.moderation.report.common.errors.noSelf));
      return;
    } on NoBotReportException {
      await ctx.respond(MessageBuilder(content: ctx.guild.t.moderation.report.common.errors.bot));
      return;
    } on RecentlyReportedMessage {
      await ctx.respond(MessageBuilder(content: ctx.guild.t.moderation.report.common.errors.recentlyReported.message));
      return;
    } on RecentlyReportedUser {
      await ctx.respond(MessageBuilder(content: ctx.guild.t.moderation.report.common.errors.recentlyReported.user));
      return;
    }

    await messageReport(ctx as InteractionChatContext, (reason: reason, message: message), pendingReport);
  }),
);
final reportUserCommand = ChatCommand(
  'user',
  'Report a user to the server moderators',
  id('report-user', (ChatContext ctx, Member member, String reason, [Attachment? attachment]) async {
    ctx as InteractionChatContext;
    final user = await ctx.client.users.get(member.id);

    Report? pendingReport;
    try {
      pendingReport = await validateReport(ctx.member!, user);
    } on NoSelfReportException {
      await ctx.respond(MessageBuilder(content: ctx.guild.t.moderation.report.common.errors.noSelf));
      return;
    } on NoBotReportException {
      await ctx.respond(MessageBuilder(content: ctx.guild.t.moderation.report.common.errors.bot));
      return;
    } on RecentlyReportedMessage {
      await ctx.respond(MessageBuilder(content: ctx.guild.t.moderation.report.common.errors.recentlyReported.message));
      return;
    } on RecentlyReportedUser {
      await ctx.respond(MessageBuilder(content: ctx.guild.t.moderation.report.common.errors.recentlyReported.user));
      return;
    }

    if (pendingReport != null && attachment == null) {
      await ctx.respond(MessageBuilder(content: ctx.guild.t.moderation.report.common.errors.noAttachmentForward));
      return;
    }

    await userReport(ctx, (attachment: attachment, reason: reason, user: (user: user, member: member)), pendingReport);
  }),
);

Future<Report?> validateReport(Member author, MessageAuthor target, [Message? message]) async {
  if (target is WebhookAuthor || (target is User && target.isBot)) {
    throw NoBotReportException();
  }

  if (target.id == author.id) {
    throw NoSelfReportException();
  }

  final userKey = 'guild:${author.manager.guildId}:report:user:${target.id}';

  final latestReport = await author.manager.client.repositories.reports.getPendingReportByTarget(author.manager.guildId, target.id);

  if (latestReport != null || await author.manager.client.selfCache[userKey].get() != null) {
    if (latestReport == null || (latestReport.attachmentUrl != null && message != null)) {
      throw RecentlyReportedUser();
    }

    if (message != null && (latestReport.contextMessageIds ?? []).contains(message.id)) {
      throw RecentlyReportedMessage();
    }
  }

  return latestReport;
}
