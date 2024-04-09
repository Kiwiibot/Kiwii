import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

extension SnowflakeInt on int {
  Snowflake get snowflake => Snowflake(this);
}

extension SnowflakeString on String {
  Snowflake get snowflake => Snowflake.parse(this);
}

// extension ThreadExtension on Thread {
//   // GuildTextChannel get parent => client.channels[p
// }

extension EmbedBuilderBetter on EmbedBuilder {
  void addField({required String name, required String value, bool isInline = false}) => (fields ?? (fields = [])).add(
        EmbedFieldBuilder(
          name: name,
          value: value,
          isInline: isInline,
        ),
      );

  void addBlankField({bool isInline = false}) => (fields ?? (fields = [])).add(
        EmbedFieldBuilder(
          name: '\u200b',
          value: '\u200b',
          isInline: isInline,
        ),
      );
}

extension ContextExtension on ChatContext {
  Future<Message> send(String content) => respond(MessageBuilder(content: content));
}
