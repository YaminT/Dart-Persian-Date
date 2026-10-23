/// Runs [task] for every item with at most [concurrency] running at once and
/// returns the results in the order of [items].
Future<List<R>> mapWithConcurrency<T, R>(
  List<T> items,
  int concurrency,
  Future<R> Function(T item) task,
) async {
  final results = List<R?>.filled(items.length, null);
  var next = 0;
  Future<void> worker() async {
    while (next < items.length) {
      final index = next++;
      results[index] = await task(items[index]);
    }
  }

  final workers = concurrency < 1 ? 1 : concurrency;
  await Future.wait([for (var i = 0; i < workers; i++) worker()]);
  return results.cast<R>();
}
