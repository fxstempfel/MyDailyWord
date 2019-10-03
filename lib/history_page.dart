import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dict_db.dart';
import 'favorites_page.dart';
import 'utils.dart';
import 'word_page.dart';

class History extends StatefulWidget {
  @override
  HistoryState createState() => HistoryState();
}

// TODO what if no internet connection?
class HistoryState extends State<History> {
  final _bigFont = const TextStyle(fontSize: 18);
  final HistoryDatabaseHelper helper = HistoryDatabaseHelper();
  final chunkSize = 10;

  ScrollController _scrollController = ScrollController();
  List<HistoryWord> _history = <HistoryWord>[];
  int _dateOfLastWord;
  bool _isRequestingMoreHistoryWords = false;
  List<String> _favorites = List<String>();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr');

    print('initializing state');

    _dateOfLastWord = DateTime.now().millisecondsSinceEpoch;
    _getMoreWords();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _getMoreWords();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Mes mots'),
          actions: <Widget>[
            IconButton(
              icon: Image.asset('assets/images/list_favorites.png'),
              onPressed: _toFavorites,
            )
          ],
        ),
        body: _buildListViewHistory(),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: addNewWord,
        ),
      );

  void addNewWord() async {
    // TODO check if button has been pressed today
    // get documents
    QuerySnapshot querySnapshot =
        await Firestore.instance.collection('dictionary').getDocuments();

    // make a List of words out of them
    List<Map<dynamic, dynamic>> documentsList =
        querySnapshot.documents.map((DocumentSnapshot snapshot) {
      return snapshot.data;
    }).toList();

    // choose a word that has not been chosen yet
    // to do so, remove elements which are in db
    print('loadMore GET start');
    var pickedWords = await helper.getAlreadyPickedWords();
    print('loadMore GET end, already picked words: $pickedWords');
    documentsList.removeWhere((item) => pickedWords.contains(item[columnName]));

    // choose randomly in the remainder
    final _random = Random();
    if (documentsList.isEmpty) {
      Flushbar(
          title: "C'est fini ! (Pour le moment)",
          message: 'Tu as épuisé tous mes mots !',
          duration: Duration(seconds: 4),
          mainButton: FlatButton(
              onPressed: () async {
                const mailto =
                    "mailto:fxstempfel@gmail.com?subject=[DailyWord] Mots épuisés&body=Il n'y a plus de mots disponibles ! Je VEUX des mots !";
                if (await canLaunch(mailto)) {
                  await launch(mailto);
                }
              },
              child: Text(
                'DIS-LE MOI',
                style: TextStyle(color: Colors.blue),
              ))).show(context);
    } else {
      var _chosenWord = documentsList[_random.nextInt(documentsList.length)];

      final dateNow = DateTime.now();
      final dateToday = DateTime(dateNow.year, dateNow.month, dateNow.day);

      // this is our new word:
      Map<String, dynamic> mapNewWord = {
        columnName: _chosenWord['name'],
        columnDateChosen: dateToday.millisecondsSinceEpoch,
        columnIsFavorite: 0
      };
      HistoryWord newWord = HistoryWord.fromMap(mapNewWord);

      // TODO animate when searching the new word => popup with CircularProgress ?

      // add it to history and set state to refresh view
      setState(() {
        _history.insert(0, newWord);
      });

      // store it into db
      helper.storeWord(wordMap: mapNewWord);

      // to new route
      _pushToWordInfo(newWord);
    }
  }

  Widget _buildListViewHistory() => ListView.builder(
        controller: _scrollController,
        itemCount: _isRequestingMoreHistoryWords
            ? 2 * _history.length + 1
            : 2 * _history.length,
        itemBuilder: (context, index) {
          if (index.isOdd) {
            return Divider();
          } else if (index == 2 * _history.length) {
            if (_isRequestingMoreHistoryWords) {
              return _buildProgressIndicator();
            } else {
              return Divider(
                height: 0.0,
              );
            }
          } else {
            return _buildRow(index ~/ 2);
          }
        },
      );

  Widget _buildProgressIndicator() => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Opacity(
            opacity: _isRequestingMoreHistoryWords ? 1.0 : 0.0,
            child: CircularProgressIndicator(),
          ),
        ),
      );

  Widget _buildRow(int index) {
    final dateNow = DateTime.now();
    final dateToday = DateTime(dateNow.year, dateNow.month, dateNow.day);
    var word = _history[index];
    var dateWord = DateTime.fromMillisecondsSinceEpoch(word.dateChosen);
    var difference = dateToday.difference(dateWord);

    var dateText;
    if (difference.inDays == 0) {
      dateText = "Auj";
    } else if (difference.inDays == 1) {
      dateText = 'Hier';
    } else if (difference.inDays < 7) {
      dateText =
          Intl.withLocale('fr', () => DateFormat('E d').format(dateWord));
    } else if (difference.inDays < 365) {
      dateText = Intl.withLocale('fr', () => DateFormat('Md').format(dateWord));
    } else {
      dateText = Intl.withLocale('fr', () => DateFormat('y').format(dateWord));
    }

    return ListTile(
      leading: Container(
        alignment: Alignment.centerLeft,
        width: 60.0,
        child: Text(dateText),
      ),
      title: Text(
        word.name,
        style: _bigFont,
      ),
      trailing: Row(
        children: <Widget>[
          _saveFavoriteButton(word),
          _deleteFromHistoryButton(word),
        ],
        mainAxisSize: MainAxisSize.min,
      ),
      onTap: () async {
        _pushToWordInfo(word);
      },
    );
  }

  void _pushToWordInfo(HistoryWord word) async {
    var isFavorite = await Navigator.of(context).pushNamed(
        WordInfoPage.routeName,
        arguments: HistoryToWordInfoArguments(word.name, word.isFavorite));
    print('returned from wordpage with $isFavorite');
    if (isFavorite && !word.isFavorite) {
      print('adding to favs');
      setState(() {
        _favorites.add(word.name);
        word.isFavorite = true;
      });
    } else if (!isFavorite && word.isFavorite) {
      print('removing from favs');
      setState(() {
        _favorites.remove(word.name);
        word.isFavorite = false;
      });
    }
  }

  Widget _saveFavoriteButton(HistoryWord word) {
    return IconButton(
      onPressed: () async {
        setState(() {
          if (word.isFavorite) {
            _favorites.remove(word.name);
            word.isFavorite = false;
          } else {
            _favorites.add(word.name);
            word.isFavorite = true;
          }
        });
        print('calling update favorite');
        await helper.updateFavoriteWord(word.name, word.isFavorite);
        print('call returned');
      },
      icon: Icon(
        word.isFavorite ? Icons.favorite : Icons.favorite_border,
        color: word.isFavorite ? Colors.red : null,
      ),
    );
  }

  Widget _deleteFromHistoryButton(HistoryWord word) => IconButton(
        icon: Icon(
          Icons.delete,
        ),
        onPressed: () {
          _showDialogDelete(word);
        },
      );

  void _showDialogDelete(HistoryWord word) {
    var contentText = _favorites.contains(word)
        ? "Es-tu sûr·e de vouloir supprimer ${word.name} ?\nC'est un de tes favoris !"
        : "Es-tu sûr·e de vouloir supprimer ${word.name} ?";

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Supprimer ce mot ?'),
            content: Text(contentText),
            actions: <Widget>[
              Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: FlatButton(
                    child: Text('Annuler'),
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )),
              FlatButton(
                child: Text('Confirmer la suppression'),
                textColor: Colors.blue,
                onPressed: () {
                  _deleteWord(word);
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  Future _deleteWord(HistoryWord word) async {
    // first, remove from history
    setState(() {
      _history.remove(word);
      _favorites.remove(word.name);
    });

    // second, remove from database
    await helper.deleteWord(word.name);
  }

  Future _getMoreWords() async {
    print('getNextWord start');
    if (!_isRequestingMoreHistoryWords) {
      // showing progress indicator
      setState(() {
        _isRequestingMoreHistoryWords = true;
      });

      // get new words
      List<HistoryWord> _newWords =
          (await helper.getMostRecentWordsAfter(chunkSize, _dateOfLastWord));

      // add them to history
      if (_newWords == null) {
        // unless none have been found. In this case, scroll up to hide last ListView item (ie progress indicator)
        double edge = 50.0;
        double offsetFromBottom = _scrollController.position.maxScrollExtent -
            _scrollController.position.pixels;
        if (offsetFromBottom < edge) {
          _scrollController.animateTo(
              _scrollController.offset - (edge - offsetFromBottom),
              duration: new Duration(milliseconds: 500),
              curve: Curves.easeOut);
        }
        // TODO this is not working
        // removing indicator
        setState(() {
          _isRequestingMoreHistoryWords = false;
        });
      } else {
        setState(() {
          _history.addAll(_newWords);
          _favorites.addAll(_newWords
              .where((word) => word.isFavorite)
              .map((word) => word.name));
          _dateOfLastWord = _newWords.last.dateChosen;
          _isRequestingMoreHistoryWords = false;
        });
      }
    }
    print('getNextWord end');
  }

  // go to a page listing favorite words
  void _toFavorites() async {
    if (_favorites.isNotEmpty) {
      // go to FavoritesPage and update _favorites when returning (some words might have been deleted)
      _favorites = await Navigator.of(context).pushNamed(
          FavoritesPage.routeName,
          arguments: HistoryToFavoritesArguments(_favorites)) as List<String>;

      if (_favorites == null) {
        _favorites = <String>[];
      }

      // update HistoryWords accordingly
      setState(() {
        _history.forEach((word) {
          if (!_favorites.contains(word.name) && word.isFavorite) {
            word.isFavorite = false;
          }
        });
      });
    } else {
      Flushbar(
              backgroundColor: Colors.orange,
              messageText: Text(
                "Tu n'as pas encore de favoris. Clique sur un cœur !",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
              duration: Duration(seconds: 3))
          .show(context);
    }
  }
}
