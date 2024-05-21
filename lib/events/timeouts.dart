import 'package:darq/darq.dart';
import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart' hide Cache;

import '../kiwii.dart';
import '../plugins/localization.dart';
import '../src/moderation/case/delete_case.dart';
import '../utils/extensions.dart';
import '../src/models/case.dart';
import '../src/moderation/case/create_case.dart';
import '../src/moderation/replies/acknowledge_case.dart';

Future<void> onAutoModerationActionExecutionTimeout(AutoModerationActionExecutionEvent event) async {
  try {
    if (event.action.type != ActionType.timeout) {
      return;
    }

    final guild = await event.guild.get();

    final client = event.guild.manager.client;

    final user = await event.user.get();

    await client.cache['guild${guild.id}:user:${user.id}:automodtimeout'].set('', const Duration(seconds: 15));

    final reason = switch (event.triggerType) {
      TriggerType.keyword => guild.t.moderation.logs.autoMod.keyword,
      TriggerType.keywordPreset => guild.t.moderation.logs.autoMod.keywordPreset,
      TriggerType.mentionSpam => guild.t.moderation.logs.autoMod.mentionSpam,
      TriggerType.spam => guild.t.moderation.logs.autoMod.spam,
    };

    final ccase = await createCase(
      guild,
      CreateCase(
        guildId: guild.id,
        action: CaseAction.timeout,
        targetId: user.id,
        targetTag: user.tag,
        reason: reason,
        duration: event.action.metadata?.duration,
        modId: guild.manager.client.user.id,
        modTag: (await guild.manager.client.user.get()).tag,
      ),
      skip: true,
    );

    await acknowledgeCase(guild, ccase, '/', await guild.manager.client.user.get());
  } catch (e, st) {
    final logger = GetIt.I.get<Logger>();
    logger.warning('Failed create case for timeout action', e, st);
  }
}

Future<void> onGuildMemberUpdateTimeout(GuildMemberUpdateEvent event) async {
  try {
    final GuildMemberUpdateEvent(:oldMember, member: newMember) = event;

    final client = event.guild.manager.client;

    final guildSettings = await client.db.getGuildOrNull(event.guildId);

    if (guildSettings == null) {
      return;
    }

    final guild = await event.guild.get();

    if (guildSettings.modLogChannelId == null || oldMember?.communicationDisabledUntil == newMember.communicationDisabledUntil) {
      return;
    }

    final deleted = await client.cache['guild:${event.guildId}:user:${newMember.id}:timeout'].get();

    // If null, either the user was never timed out or the TTL expired.
    if (deleted != null) {
      await client.cache['guild:${event.guildId}:user:${newMember.id}:timeout'].purge();
      return;
    }

    // Wait to prevent collisions.
    await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 500));

    final autoMod = await client.cache['guild:${event.guildId}:user:${newMember.id}:automodtimeout'].get();

    // Same as above.
    if (autoMod != null) {
      await client.cache['guild:${event.guildId}:user:${newMember.id}:automodtimeout'].purge();
      return;
    }

    final auditLogs = await event.guild.auditLogs.list(limit: 10, type: AuditLogEvent.memberUpdate);

    final logs = auditLogs.firstWhereOrDefault((e) => e.targetId == newMember.id && e.changes?.any((c) => c.key == 'communication_disabled_until') == true,
        defaultValue: null);

    if (logs?.changes?.isEmpty == true) {
      return;
    }

    final timeoutChanges = logs!.changes!.firstWhereOrDefault((value) => value.key == 'communication_disabled_until', defaultValue: null);

    if (timeoutChanges == null) {
      return;
    }

    final oldVal = timeoutChanges.oldValue as String?;
    final newVal = timeoutChanges.newValue as String?;

    final hasTimeoutEnded = (oldVal != null && oldVal.isNotEmpty) && (newVal == null || newVal.isEmpty); 

    final user = await logs.user?.get();
    User? target;
    if (logs.targetId != null) {
      target = await client.users.get(logs.targetId!);
    }

    final ccase = hasTimeoutEnded
        ? await deleteCase(
            DeleteCase(
              guildId: event.guildId,
              modId: logs.userId,
              modTag: user?.tag,
              targetId: logs.targetId,
              targetTag: target?.tag,
              reason: logs.reason,
              action: CaseAction.timeout,
            ),
            await event.guild.get(),
            isManual: true,
            shouldSkip: true,
          )
        : await createCase(
            (await event.guild.get()),
            CreateCase(
              guildId: event.guildId,
              action: CaseAction.timeout,
              targetId: target!.id,
              targetTag: target.tag,
              duration: (newMember.communicationDisabledUntil ?? DateTime.now()).difference(DateTime.now()),
              modId: logs.userId,
              modTag: user?.tag,
              reason: logs.reason,
            ),
            skip: true,
          );

    await acknowledgeCase(guild, ccase, '/', user);
  } catch (e, st) {
    final logger = GetIt.I.get<Logger>();
    logger.warning('Failed to update timeout', e, st);
  }
}
