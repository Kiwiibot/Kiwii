import 'package:nyxx/nyxx.dart';

abstract class Module {
  String get name;
  final Snowflake guildId;
  final NyxxGateway client;

  Module(this.guildId, this.client);
}

