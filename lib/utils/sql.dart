import 'package:nyxx/nyxx.dart';
import 'package:option/option.dart';

(int, String, List<Object?>) sql(Map<String, Option<Object?>> entries) {
  entries.removeWhere((_, v) => v.isNone);

  final buffer = StringBuffer();

  int index = 0;

  buffer.write(entries.entries.indexed.map((i) => '${i.$2.key} = \$${index = i.$1 + 1}').join(', '));

  final args =
      entries.values
          .map(
            (v) => switch (v.unwrap()) {
              Snowflake(:final value) => value,
              final List<Snowflake> list => list.map((e) => e.value).toList(),
              final value => value,
            },
          )
          .toList();

  return (index, buffer.toString(), args);
}
