import 'package:nyxx_commands/nyxx_commands.dart' as nyxx_commands;

class CommandOptions extends nyxx_commands.CommandOptions {
  /// An URL representing the image of the command.
  final String? img;

  const CommandOptions({
    this.img,
    super.acceptBotCommands,
    super.type,
    super.acceptSelfCommands,
    super.defaultResponseLevel,
    super.autoAcknowledgeDuration,
    super.caseInsensitiveCommands,
    super.autoAcknowledgeInteractions,
  });
}
