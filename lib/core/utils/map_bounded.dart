Future<List<R>> mapBounded<T, R>(
  List<T> items,
  Future<R> Function(T) transform, {
  int concurrency = 5,
}) async {
  if (concurrency < 1) throw ArgumentError.value(concurrency, 'concurrency');
  final results = <int, R>{};
  var next = 0;
  Future<void> worker() async {
    while (next < items.length) {
      final index = next++;
      results[index] = await transform(items[index]);
    }
  }

  await Future.wait(
    List.generate(
      items.length < concurrency ? items.length : concurrency,
      (_) => worker(),
    ),
  );
  return List.generate(items.length, (index) => results[index] as R);
}
