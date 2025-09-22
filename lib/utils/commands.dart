import 'package:nyxx_commands/nyxx_commands.dart' hide userConverter, memberConverter;
import '../commands/admin/rest.dart';
import '../commands/admin/run_as.dart';
import '../commands/admin/stats.dart';
import '../commands/core/avatar.dart';
import '../commands/core/help.dart';
import '../commands/core/info.dart';
import '../commands/fun/emoji.dart';
import '../commands/fun/images.dart';
import '../commands/fun/markov.dart';
import '../commands/fun/uwurandom.dart';
import '../commands/moderation/ban.dart';
import '../commands/moderation/case.dart';
import '../commands/moderation/lookup.dart';
import '../commands/moderation/reason.dart';
import '../commands/moderation/report.dart';
import '../commands/moderation/timeout.dart';
import '../commands/moderation/warn.dart';
import '../commands/ping.dart';
import '../commands/utils/settings.dart';
import '../commands/utils/source.dart';
import '../commands/utils/tag.dart';
import '../src/converters/converters.dart';
import '../src/settings.dart' as settings;

final commands = CommandsPlugin(
  prefix: mentionOr(dmOr((_) => settings.prefix)),
  options: CommandsOptions(
    logErrors: false,
    defaultResponseLevel: ResponseLevel(hideInteraction: false, isDm: false, mention: false, preserveComponentMessages: true),
  ),
);

void registerCommands() {
  commands.addCommand(ping);
  commands.addCommand(markov);
  commands.addCommand(uwurandom);
  commands.addCommand(tagCommand);
  commands.addCommand(helpCommand);
  commands.addCommand(sourceCommand);
  commands.addCommand(settingsCommand);
  commands.addCommand(runAsCommand);
  commands.addCommand(warnCommand);
  commands.addCommand(timeoutCommand);
  commands.addCommand(reasonCommand);
  commands.addCommand(banCommand);
  commands.addCommand(lookupCommand);
  commands.addCommand(userLookupCommand);
  commands.addCommand(caseCommand);
  commands.addCommand(infoCommand);
  commands.addCommand(infoUserCommand);
  commands.addCommand(restCommand);
  commands.addCommand(statsCommand);
  commands.addCommand(namesCommand);
  commands.addCommand(avatarCommand);
  commands.addCommand(avatarsCommand);
  commands.addCommand(reportCommand);
  commands.addCommand(imagesCommand);
  commands.addCommand(emojiCommand);
}

void registerConverters() {
  commands.addConverter(listConverter);
  commands.addConverter(chatCommandConverter);
  commands.addConverter(basePluginConverter);
  commands.addConverter(tagConverter);
  commands.addConverter(localeConverter);
  commands.addConverter(mapObjectConverter);
  commands.addConverter(httpRouteConverter);
  commands.addConverter(durationConverter);
  commands.addConverter(userConverter);
  commands.addConverter(messageConverter);
  commands.addConverter(memberConverter);
  commands.addConverter(forumChannelConverter);
  commands.addConverter(emojiConverter);
}
