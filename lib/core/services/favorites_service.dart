class FavoritesService {
  static final Set<String> _favorites = {};

  static bool isFavorite(String id) => _favorites.contains(id);

  static void toggle(String id) {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
  }
}
