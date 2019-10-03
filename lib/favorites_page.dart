import 'package:flutter/material.dart';
import 'package:flushbar/flushbar.dart';

import 'word_page.dart';
import 'utils.dart';

class FavoritesPage extends StatefulWidget {
  static const routeName = '/favorites';

  @override
  State<StatefulWidget> createState() => FavoritesPageState();
}

class FavoritesPageState extends State<FavoritesPage> {
  final _bigFont = const TextStyle(fontSize: 18);

  var _favoritesNames = <String>[];

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
              title: Text("Favoris"),
              leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(_favoritesNames))),
          body: Builder(
            builder: (context) => ListView.builder(
                itemCount: _favoritesNames.length,
                itemBuilder: (context, index) =>
                    _buildFavoriteTile(index, context)),
          )),
      onWillPop: () async {
        Navigator.of(context).pop(_favoritesNames);
        return false;
      });

  Widget _buildFavoriteTile(int index, BuildContext context) {
    var wordName = _favoritesNames[index];
    return Dismissible(
        key: Key(wordName),
        background: Container(color: Colors.red),
        onDismissed: (direction) {
          setState(() {
            _favoritesNames.remove(wordName);
          });

          // display SnackBar
          Flushbar(
              forwardAnimationCurve: Curves.bounceIn,
              duration: Duration(seconds: 4),
              message: 'Tu as supprimé $wordName de tes favoris.',
                mainButton: FlatButton(
                    onPressed: () {
                      setState(() {
                        _favoritesNames.insert(index, wordName);
                      });
                    },
                    child: Text(
                      'ANNULER',
                      style: TextStyle(color: Colors.blue),
                    ))
              ).show(context);
        },
        child: ListTile(
            title: Text(
              wordName,
              style: _bigFont,
            ),
            onTap: () async {
              var isFav = await Navigator.of(context).pushNamed(
                  WordInfoPage.routeName,
                  arguments: HistoryToWordInfoArguments(wordName, true));
              print('received $isFav from word page');
              if (!isFav) {
                setState(() {
                  _favoritesNames.remove(wordName);
                });
                if (_favoritesNames.isEmpty) {
                  Navigator.of(context).pop();
                }
              }
            }));
  }
}
