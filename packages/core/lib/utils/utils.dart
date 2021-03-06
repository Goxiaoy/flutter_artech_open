import 'dart:collection';

import 'package:artech_core/configuration/app_config.dart';

export 'package:artech_core/utils/json_extension.dart';

typedef GetFactory<T> = T? Function();
typedef SetFactory<T> = void Function(T? value);

typedef GetFactoryAsync<T> = Future<T?> Function();
typedef SetFactoryAsync<T> = Future<void> Function(T? value);

T? getOr<T>(GetFactory<T> cache, GetFactory<T> creator,
    {SetFactory<T>? setter}) {
  final cacheValue = cache();
  if (cacheValue != null) {
    return cacheValue;
  }
  //call create
  final createValue = creator();
  if (setter != null) {
    setter(createValue);
  }
  return createValue;
}

Future<T?> getOrAsync<T>(GetFactoryAsync<T> cache, GetFactoryAsync<T> creator,
    {SetFactoryAsync<T>? setter}) async {
  final cacheValue = await cache();
  if (cacheValue != null) {
    return cacheValue;
  }
  //call create
  final createValue = await creator();
  if (setter != null) {
    await setter(createValue);
  }
  return createValue;
}

Future<T> executeWithStopwatch<T>(Future<T> Function() f,
    {bool debugOnly = true,
    int thresholdMilliseconds = 20,
    Function(int t)? overAction}) async {
  if (!debugOnly || kIsDebug) {
    final Stopwatch sw = Stopwatch();
    sw.start();
    final res = await f();
    sw.stop();
    if (sw.elapsedMilliseconds > thresholdMilliseconds) {
      overAction?.call(sw.elapsedMilliseconds);
    }
    return res;
  } else {
    return await f();
  }
}

extension IterableExtension<T> on Iterable<T> {
  Iterable<E> mapIndexed<E>(E Function(int index, T item) f) sync* {
    var index = 0;
    for (final item in this) {
      yield f(index, item);
      index = index + 1;
    }
  }
}

///dfs access node
void dfs<T, TKey>(
  T node,
  TKey Function(T node) keyAccessor,
  Iterable<T> Function(T node) childrenAccessor,
  void Function(T node, List<T> parents) access,
) {
  return _dfsWithParent(
      node, keyAccessor, childrenAccessor, access, HashSet<TKey>(), <T>[]);
}

void _dfsWithParent<T, TKey>(
    T node,
    TKey Function(T node) keyAccessor,
    Iterable<T> Function(T node) childrenAccessor,
    void Function(T node, List<T> parents) access,
    HashSet<TKey> accessed,
    List<T> parents) {
  final children = childrenAccessor(node);
  if (children.isNotEmpty) {
    parents.add(node);
    for (final child in children) {
      if (!accessed.contains(keyAccessor(child))) {
        _dfsWithParent(
            child, keyAccessor, childrenAccessor, access, accessed, parents);
      }
    }
    parents.remove(node);
  }
  access(node, parents);
  accessed.add(keyAccessor(node));
}

extension BoolParsing on String? {
  bool? parseBool() {
    return this == null ? null : this!.toLowerCase() == 'true';
  }
}
