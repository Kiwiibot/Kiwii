// /*
//  * Kiwii, a stupid Discord bot.
//  * Copyright (C) 2019-2024 Lexedia
//  *
//  * This program is free software: you can redistribute it and/or modify
//  * it under the terms of the GNU General Public License as published by
//  * the Free Software Foundation, either version 3 of the License, or
//  * (at your option) any later version.
//  *
//  * This program is distributed in the hope that it will be useful,
//  * but WITHOUT ANY WARRANTY; without even the implied warranty of
//  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  * GNU General Public License for more details.
//  *
//  * You should have received a copy of the GNU General Public License
//  * along with this program.  If not, see <https://www.gnu.org/licenses/>.
//  */

import 'package:get_it/get_it.dart';
import 'package:postgres/postgres.dart' as pg;

import '../../models/report.dart';

enum ReportType { message, user }

enum ReportStatus { pending, approved, denied, spam }

Future<Report> createReport(CreateReport report) async {
  final connection = GetIt.I.get<pg.Connection>();

  final row =
      (await connection.execute(
        r'''
        INSERT INTO reports (
          report_id,
          guild_id,
			    type,
			    status,
			    message_id,
			    channel_id,
			    target_id,
			    target_tag,
			    author_id,
			    author_tag,
			    reason,
			    attachment_url,
			    log_post_id,
			    ref_id,
			    context_messages_ids
        ) VALUES (
          next_report($1),
          $1,
          $2,
          $3,
          $4,
          $5,
          $6,
          $7,
          $8,
          $9,
          $10,
          $11,
          $12,
          $13,
          $14
        ) RETURNING *;
      ''',
        parameters: [
          report.guildId.value,
          report.type.index,
          (report.status ?? ReportStatus.pending).index,
          report.messageId?.value,
          report.channelId?.value,
          report.targetId.value,
          report.targetTag,
          report.authorId.value,
          report.authorTag,
          report.reason,
          report.attachmentUrl,
          report.logPostId?.value,
          report.refId,
          report.contextMessageIds?.map((e) => e.value).toList() ?? [],
        ],
      )).single;

  return Report.fromRow(row.toColumnMap());
}
