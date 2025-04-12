import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:kiwii/src/settings.dart' as settings;

import 'package:args/command_runner.dart';

import 'package:dartx/dartx_io.dart';
import 'package:postgres/postgres.dart';

typedef Revisions = ({int version});

final revisionFile = RegExp(r'(?<kind>V|U)(?<version>[0-9]+)__(?<description>.+).sql');

class Revision {
  final String kind;
  final int version;
  final String description;
  final String path;

  const Revision({required this.description, required this.kind, required this.path, required this.version});

  static Revision fromMatch(RegExpMatch match, String path) =>
      Revision(description: match.namedGroup('description')!, kind: match.namedGroup('kind')!, path: path, version: int.parse(match.namedGroup('version')!));
}

class Migrations {
  final String fileName;

  Directory get root => File(fileName).parent;

  late int version;
  late String databaseUri;

  late Revision _lastRevision;

  late final Map<int, Revision> _revisions;

  Map<int, Revision> get revisions => {
    for (final file in root.listSync().where((f) => f.name.endsWith('.sql')))
      if (revisionFile.hasMatch(file.name)) ((_lastRevision = Revision.fromMatch(revisionFile.firstMatch(file.name)!, file.path)).version): _lastRevision,
  };

  void ensurePath() {
    root.createSync();
  }

  Revisions loadMetadata() {
    try {
      final r = json.decode(File(fileName).readAsStringSync());

      return (version: r['version'] as int);
    } on PathNotFoundException {
      return (version: 0);
    }
  }

  Map<String, Object> toMap() => {'version': version};

  void load() {
    ensurePath();
    final data = loadMetadata();
    version = data.version;
  }

  void save() {
    final temp = File('$fileName.${Random.secure().nextInt(0xffffffff).toRadixString(16)}.tmp');
    temp.writeAsStringSync(json.encode(toMap()), mode: FileMode.writeOnly);

    File(fileName).writeAsStringSync(json.encode(toMap()), mode: FileMode.writeOnly);
    temp.deleteSync();
  }

  bool get isNextRevisionTaken => _revisions.containsKey(version + 1);

  List<Revision> orderedRevision() => _revisions.values.sortedBy((r) => r.version);

  Revision createRevision(String reason, [String kind = 'V']) {
    var cleaned = reason.replaceAll(RegExp(r'\s'), '_');
    var fileName = '$kind${version + 1}__$cleaned.sql';
    final file = root.file(fileName)..createSync();

    file.writeAsStringSync('''
-- Revises: V$version
-- Creation Date: ${DateTime.now().toUtc()} UTC
-- Reason: $reason


''');

    save();
    return Revision(description: reason, kind: kind, path: file.path, version: version + 1);
  }

  Future<int> upgrade(Connection connection) async {
    final ordered = orderedRevision();
    int successes = 0;

    await connection.runTx<void>((t) async {
      for (final revision in ordered) {
        if (revision.version > version) {
          var sql = File(revision.path).readAsStringSync();
          // extended QM doesn't support multiple statments
          await t.execute(Sql(sql), queryMode: QueryMode.simple);
          successes++;
        }
      }
    });

    version += successes;
    save();
    return successes;
  }

  Migrations({this.fileName = 'migrations/revisions.json'}) {
    _revisions = revisions;
    load();
  }
}

Future<int> runUpgrade(Migrations migrations, Connection connection) async {
  return await migrations.upgrade(connection);
}

class InitCommand extends Command<void> {
  @override
  final name = 'init';

  @override
  final description = 'Initializes the database and runs all the current migrations';

  final Connection connection;

  InitCommand(this.connection);

  @override
  Future<void> run() async {
    final migrations = Migrations();

    final applied = await runUpgrade(migrations, connection);

    print('Sucessfully applied $applied revisions');
  }
}

class MigrateCommand extends Command<void> {
  @override
  final name = 'migrate';

  @override
  final description = 'Creates a new revision for you to edit';

  MigrateCommand() {
    argParser.addOption('reason', abbr: 'r', help: 'The reason for this revision', mandatory: true);
  }

  @override
  void run() {
    final reason = argResults!.option('reason')!;

    final migrations = Migrations();

    if (migrations.isNextRevisionTaken) {
      print('An unapplied migration already exists for the next version, exiting');
      exit(1);
    }

    final revision = migrations.createRevision(reason);
    print('Created revision V${revision.version}');
  }
}

class UpgradeCommand extends Command<void> {
  @override
  final name = 'upgrade';

  @override
  final description = 'Upgrades the database at the given revision (if any).';

  final Connection connection;

  UpgradeCommand(this.connection) {
    argParser.addFlag('sql', help: 'Prints the SQL instead of executing it', abbr: 's', negatable: false);
  }

  @override
  Future<void> run() async {
    final sql = argResults!.flag('sql');

    final migrations = Migrations();

    if (sql) {
      for (final revision in migrations.orderedRevision()) {
        if (revision.version > migrations.version) {
          final rawSql = File(revision.path).readAsStringSync();
          print(rawSql);
        }
      }

      return;
    }

    final applied = await runUpgrade(migrations, connection);

    print('Applied $applied revisions');
  }
}

void main(List<String> args) async {
  final connection = await Connection.open(
    Endpoint(
      database: settings.postgresDb,
      host: settings.postgresHost,
      username: settings.postgresUser,
      password: settings.postgresPassword,
      port: settings.postgresPort,
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );

  final runner =
      CommandRunner<void>('mig', 'Migrations')
        ..addCommand(InitCommand(connection))
        ..addCommand(MigrateCommand())
        ..addCommand(UpgradeCommand(connection));

  try {
  await runner.run(args);
  } on ServerException catch (e) {
    print('Postgres errored');

    print(e.message);

    rethrow;
  }

  await connection.close();
}
