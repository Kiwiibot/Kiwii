import 'dart:async';

extension IterableExtensions<E> on Iterable<E> {
  /// Creates a new lazy [Iterable] with all the elements that have NOT type [T].
  ///
  /// The matched elements are discarded from the [Iterable].
  Iterable<E> whereNotType<T>() => _WhereNotTypeIterable<E, T>(this);

  /// Same as [map], but returns a [List] instead of an [Iterable] of [Future]s.
  Future<List<T>> mapAsync<T>(FutureOr<T> Function(E) toElement) => Future.wait(map((e) async => await toElement(e)));

  /// Same as [where], but can have an async context.
  Future<Iterable<E>> whereAsync(FutureOr<bool> Function(E) test) async {
    final List<Future<(E, bool)>> futures = [];
    for (final element in this) {
      futures.add((() async => (element, await test(element)))());
    }

    final List<(E, bool)> results = await Future.wait(futures);

    return [
      for (final entry in results)
        if (entry.$2) entry.$1,
    ];
  }

  E? firstWhereOrNull(bool Function(E) test) => where(test).firstOrNull;
}

class _WhereNotTypeIterable<E, T> extends Iterable<E> {
  final Iterable<Object?> _source;
  _WhereNotTypeIterable(this._source);

  @override
  Iterator<E> get iterator => _WhereNotTypeIterator<E, T>(_source.iterator);
}

class _WhereNotTypeIterator<T, E> implements Iterator<T> {
  final Iterator<Object?> _source;
  _WhereNotTypeIterator(this._source);

  @override
  bool moveNext() {
    while (_source.moveNext()) {
      if (_source.current is! E) return true;
    }
    return false;
  }

  @override
  T get current => _source.current as T;
}
