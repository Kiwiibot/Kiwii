/*
 * Kiwii, a stupid Discord bot.
 * Copyright (C) 2019-2024 Lexedia
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:io';

class Stderr implements StringSink {
  /// The file to output to.
  final File file;

  /// The string sink to output to.
  final StringSink sink;

  /// Create a new instance of the [Stderr] sink.
  Stderr(this.file, this.sink);

  @override
  void write(Object? obj) {
    sink.write(obj);
    file.writeAsStringSync(obj.toString(), mode: FileMode.append);
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    sink.writeAll(objects, separator);
    file.writeAsStringSync(objects.join(separator), mode: FileMode.append);
  }

  @override
  void writeCharCode(int charCode) {
    sink.writeCharCode(charCode);
    file.writeAsStringSync(String.fromCharCode(charCode), mode: FileMode.append);
  }

  @override
  void writeln([Object? obj = '']) {
    sink.writeln(obj);
    file.writeAsStringSync('$obj\n', mode: FileMode.append);
  }
}
