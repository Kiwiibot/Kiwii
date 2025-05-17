import 'dart:async';

import 'iterable.dart';

extension FutureExtensions<T> on Future<T> {
  /// Same as [wait], but allows you to take [FutureOr<T>].
  /// 
  /// The returned [List] will always have the non-futures elements first.
  static Future<List<T>> waitFor<T>(Iterable<FutureOr<T>> futures, {bool eagerError = false, void Function(T)? cleanup}) async {
    final nonFutures = futures.whereNotType<Future<T>>() as Iterable<T>;
    final realFutures = futures.whereType<Future<T>>();

    return [...nonFutures, ...await Future.wait<T>(realFutures)];
  }
}
