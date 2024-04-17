import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

extension ContextExtension on ChatContext {
  Future<Message> send(String content) => respond(MessageBuilder(content: content));
}

// extension ThreadExtension on Thread {
//   // GuildTextChannel get parent => client.channels[p
// }

extension EmbedBuilderBetter on EmbedBuilder {
  void addBlankField({bool isInline = false}) => addField(
        name: '\u200b',
        value: '\u200b',
        isInline: isInline,
      );

  void addField({required String name, required String value, bool isInline = false}) => (fields ?? (fields = [])).add(
        EmbedFieldBuilder(
          name: name,
          value: value,
          isInline: isInline,
        ),
      );

  void maybeAddField({String? name, String? value, bool isInline = false}) {
    if (name != null && value != null) {
      addField(name: name, value: value, isInline: isInline);
    }
  }
}

extension ListExtension<E> on List<E> {
  String joinWithStep([String separator = '', int step = 1, String inBetween = ' ']) {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i += step) {
      buffer.write(this[i]);
      if (i + step < length) {
        buffer.write(separator);
      }
    }
    return buffer.toString();
  }
}

extension SnowflakeExtension on Snowflake {
  /// Converts a [Snowflake] to a [BigInt].
  BigInt toBigInt() => BigInt.from(value);
}

extension SnowflakeInt on int {
  Snowflake get snowflake => Snowflake(this);
}

extension SnowflakeString on String {
  Snowflake get snowflake => Snowflake.parse(this);
}

extension StringExtension on String {
  String get capitalize => '${this[0].toUpperCase()}${substring(1)}';
  String get firstLetterUpperCase => '${this[0].toUpperCase()}${substring(1)}';
  String get title => splitMapJoin(' ', onNonMatch: (s) => s.capitalize, onMatch: (s) => s[0]!);
}
