/// Extension method for using mapIndexed with lists
extension IterableExtensions<T> on List<T> {
  List<R> mapIndexed<R>(R Function(int index, T item) callback) {
    return asMap().entries
        .map((entry) => callback(entry.key, entry.value))
        .toList();
  }
}
