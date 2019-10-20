import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import 'word_page.dart';
import 'utils.dart';

class FavoritesPage extends StatefulWidget {
  static const routeName = '/favorites';

  @override
  State<StatefulWidget> createState() => FavoritesPageState();
}

class FavoritesPageState extends State<FavoritesPage> {
  var _favoritesNames = <String>[];
  var _toDeleteFromHistory = <String>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context).settings.arguments
        as HistoryToFavoritesArguments;

    _favoritesNames = arguments.favoritesNames;
  }

  Widget build(BuildContext context) => WillPopScope(
      child: Scaffold(
        appBar: AppBar(
            title: Text(
              "Favoris",
            ),
            leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: colorSecondary,
                ),
                onPressed: () => Navigator.of(context).pop(
                    FavoritesToHistoryArguments(
                        _favoritesNames, _toDeleteFromHistory)))),
        body: Builder(
          builder: (context) => ListView.builder(
              itemCount: _favoritesNames.length,
              itemBuilder: (context, index) =>
                  _buildFavoriteTile(index, context)),
        ),
      ),
      onWillPop: () async {
        Navigator.of(context).pop(
            FavoritesToHistoryArguments(_favoritesNames, _toDeleteFromHistory));
        return Future.value(false);
      });

  Widget _buildFavoriteTile(int index, BuildContext context) {
    var wordName = _favoritesNames[index];
    return Dismissible(
        key: Key(wordName),
        background: Container(
          color: colorAccent,
          child: Center(
            child: Text(
              'Supprimer',
              style: TextStyle(color: colorTextOnAccent, fontSize: 18),
            ),
          ),
        ),
        onDismissed: (direction) {
          setState(() {
            _favoritesNames.remove(wordName);
          });

          // display SnackBar
          flushbarFactory(
              context: context,
              messageString: 'Tu as supprimé $wordName de tes favoris.',
              buttonOnPressed: () {
                setState(() {
                  _favoritesNames.insert(index, wordName);
                });

              },
              buttonString: 'Annuler',
              onStatusChanged: (status) {
                // when bar has disappeared, pop if no favs left
                if (status == FlushbarStatus.DISMISSED &&
                    _favoritesNames.isEmpty) {
                  Navigator.of(context).pop(FavoritesToHistoryArguments(
                      _favoritesNames, _toDeleteFromHistory));
                }
              });
        },
        child: ListTile(
            title: Text(
              wordName,
              style: Theme.of(context).textTheme.title,
            ),
            onTap: () async {
              var backArgs = await Navigator.of(context).pushNamed(
                      WordInfoPage.routeName,
                      arguments: HistoryToWordInfoArguments(wordName, true))
                  as WordInfoToHistoryArguments;

              if (backArgs.toDelete) {
                setState(() {
                  _favoritesNames.remove(wordName);
                });
                _toDeleteFromHistory.add(wordName);
                if (_favoritesNames.isEmpty) {
                  Navigator.of(context).pop(FavoritesToHistoryArguments(
                      _favoritesNames, _toDeleteFromHistory));
                }
              }

              if (!backArgs.isFavorite) {
                setState(() {
                  _favoritesNames.remove(wordName);
                });
                if (_favoritesNames.isEmpty) {
                  Navigator.of(context).pop(FavoritesToHistoryArguments(
                      _favoritesNames, _toDeleteFromHistory));
                }
              }
            }));
  }
}
