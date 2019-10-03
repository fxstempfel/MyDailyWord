class HistoryToWordInfoArguments {
  String wordName;
  bool isFavorite;

  HistoryToWordInfoArguments(this.wordName, this.isFavorite);
}

class HistoryToFavoritesArguments {
  List<String> favoritesNames;

  HistoryToFavoritesArguments(this.favoritesNames);
}