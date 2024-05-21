import 'package:nyxx/nyxx.dart';

import '../moderation/appeal/create_appeal.dart';

class CreateAppeal {
  final Snowflake targetId;
  final String targetTag;
  final Snowflake guildId;
  final int refId;

  CreateAppeal({
    required this.targetId,
    required this.targetTag,
    required this.guildId,
    required this.refId,
  });
}

class UpdateAppeal {
  final String? reason;
  final int appealId;
  final Snowflake guildId;
  final Snowflake? modId;
  final String? modTag;
  final AppealStatus? status;
  final Snowflake? logMessageId;
  // final int refId;

  UpdateAppeal({
    required this.appealId,
    required this.guildId,
    this.reason,
    this.modId,
    this.modTag,
    this.status,
    this.logMessageId,
    // required this.refId,
  });
}
