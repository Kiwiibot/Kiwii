import 'package:nyxx/nyxx.dart';

extension SnowflakeExtension on Snowflake {
  /// Converts a [Snowflake] to a [BigInt].
  BigInt toBigInt() => BigInt.from(value);
}
