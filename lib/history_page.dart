import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dict_db.dart';
import 'utils.dart';
import 'word_page.dart';

class History extends StatefulWidget {
  @override
  HistoryState createState() => HistoryState();
}

// TODO what if no connection?
class HistoryState extends State<History> {
  final Set<HistoryWord> _favorites = Set<HistoryWord>();
  final _bigFont = const TextStyle(fontSize: 18);
  final HistoryDatabaseHelper helper = HistoryDatabaseHelper();
  final chunkSize = 10;

  ScrollController _scrollController = ScrollController();
  List<HistoryWord> _history = <HistoryWord>[];
  int _dateOfLastWord;
  bool _isRequestingNewWords = false;

  @override
  void initState() {
    super.initState();
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
              icon: Icon(Icons.playlist_add_check),
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
    print('loadMore GET end');
    documentsList.removeWhere((item) => pickedWords.contains(item[columnName]));

    // choose randomly in the remainder
    final _random = Random();
    if (documentsList.length == 0) {
      // TODO display some message (LaertDialog/Toast/SnackBar)
      return null;
    }
    var _chosenWord = documentsList[_random.nextInt(documentsList.length)];

    // this is our new word:
    Map<String, dynamic> mapNewWord = {
      columnName: _chosenWord['name'],
      columnDateChosen: DateTime.now().millisecondsSinceEpoch,
      columnIsFavorite: 0
    };
    HistoryWord newWord = HistoryWord.fromMap(mapNewWord);

    // TODO animate when searching the new word

    // add it to history and set state to refresh view
    setState(() {
      _history.insert(0, newWord);
    });

    // store it into db
    helper.storeWord(wordMap: mapNewWord);

    // to new route
    _pushToWordInfo(newWord);
  }

  Widget _buildListViewHistory() => ListView.builder(
        controller: _scrollController,
        itemCount: 2 * _history.length + 1,
        itemBuilder: (context, index) {
          if (index.isOdd) {
            return Divider();
          } else if (index == 2 * _history.length) {
            if (_isRequestingNewWords) {
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
            opacity: _isRequestingNewWords ? 1.0 : 0.0,
            child: CircularProgressIndicator(),
          ),
        ),
      );

  Widget _buildRow(int index) {
    final dateNow = DateTime.now();
    var word = _history[index];
    var dateWord = DateTime.fromMillisecondsSinceEpoch(word.dateChosen);
    var difference = dateNow.difference(dateWord);

    var format;
    if (difference.inDays <= 7) {
      format = 'E d';
    } else if (difference.inDays <= 365) {
      format = 'Md';
    } else {
      format = 'y';
    }

    return Hero(
        tag: word.name,
        child: ListTile(
          leading: Container(
            alignment: Alignment.centerLeft,
            width: 60.0,
            child: Text(
              DateFormat(format).format(dateWord),
            ),
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
            // TODO update db with isFavorite
            _pushToWordInfo(word);
          },
        ));
  }

  void _pushToWordInfo(HistoryWord word) async {
    var isFavorite = await Navigator.pushNamed(
        context, WordInfoPage.routeName,
        arguments: HistoryToWordInfoArguments(
            word.name, _favorites.contains(word))) as bool;
    if (isFavorite && !_favorites.contains(word)) {
      _favorites.add(word);
    } else if (!isFavorite && _favorites.contains(word)) {
      _favorites.remove(word);
    }
  }

  Widget _saveFavoriteButton(HistoryWord word) {
    final bool alreadySaved = _favorites.contains(word);
    return IconButton(
      onPressed: () {
        setState(() {
          if (alreadySaved) {
            _favorites.remove(word);
          } else {
            _favorites.add(word);
          }
        });
      },
      icon: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
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
        ? "Are you sure you want to delete ${word.name}?\nIt's one of your favorites!"
        : "Are you sure you want to delete ${word.name}?";

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Delete word'),
            content: Text(contentText),
            actions: <Widget>[
              FlatButton(
                child: Text('Keep it!'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Delete it'),
                textColor: Colors.red,
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
    // first, remove from database
    await helper.deleteWord(word.name);

    // second, remove from history
    setState(() {
      _history.remove(word);
    });
  }

  Future _getMoreWords() async {
    print('getNextWord start');
    if (!_isRequestingNewWords) {
      // showing progress indicator
      setState(() {
        _isRequestingNewWords = true;
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
          _isRequestingNewWords = false;
        });
      } else {
        setState(() {
          _history.addAll(_newWords);
          _dateOfLastWord = _newWords.last.dateChosen;
          _isRequestingNewWords = false;
        });
      }
    }
    print('getNextWord end');
  }

  void _toFavorites() {
    // TODO case where there's no favorite
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      final Iterable<ListTile> tiles = _favorites.map((HistoryWord word) {
        return ListTile(
          title: Text(
            word.name,
            style: _bigFont,
          ),
          onTap: () => Navigator.pushNamed(context, WordInfoPage.routeName,
              arguments: word.name),
        );
      });
      final List<Widget> divided = ListTile.divideTiles(
        tiles: tiles,
        context: context,
      ).toList();

      return Scaffold(
        appBar: AppBar(
          title: Text("Favorite Words"),
        ),
        body: ListView(
          children: divided,
        ),
      );
    }));
  }
}
