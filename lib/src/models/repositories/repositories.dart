import 'package:postgres/postgres.dart';

import 'appeal.dart';
import 'case.dart';
import 'guild.dart';
import 'report.dart';
import 'tag.dart';

class Repository {
  final Connection connection;

  const Repository({required this.connection});
}

class Repositories {
  final Connection connection;

  TagRepository get tags => TagRepository(connection: connection);
  GuildRepository get guilds => GuildRepository(connection: connection);
  AppealRepository get appeals => AppealRepository(connection: connection);
  CaseRepository get cases => CaseRepository(connection: connection);
  ReportRepository get reports => ReportRepository(connection: connection);

  const Repositories({required this.connection});

  factory Repositories.fromConnection(Connection connection) => Repositories(connection: connection);
}
