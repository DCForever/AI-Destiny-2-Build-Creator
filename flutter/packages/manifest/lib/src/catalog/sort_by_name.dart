/// Case-insensitive display-name ordering (product `compareDisplayName`).
int compareDisplayName(String a, String b) {
  return a.toLowerCase().compareTo(b.toLowerCase());
}

/// Stable alpha sort of catalog-like rows by [nameOf].
List<T> sortByDisplayName<T>(
  Iterable<T> items,
  String Function(T) nameOf,
) {
  final list = List<T>.from(items);
  list.sort((a, b) => compareDisplayName(nameOf(a), nameOf(b)));
  return list;
}
