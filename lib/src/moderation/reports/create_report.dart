import 'package:get_it/get_it.dart';

import '../../../database.dart';

enum ReportType {
  message,
  user,
}

enum ReportStatus {
  pending,
  approved,
  denied,
  spam,
}

Future<Report> createReport(Report report) {
  final db = GetIt.I.get<AppDatabase>();

  return db.createReport(report);
}
