import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'history_db.dart';
import 'favorites_page.dart';
import 'utils.dart';
import 'word_page.dart';

class History extends StatefulWidget {
  @override
  HistoryState createState() => HistoryState();
}

// TODO sometimes black screen when back button
// TODO what if no internet connection?
class HistoryState extends State<History> {
  static const chunkSize = 10;
  static const tagFab = 'fab_add_word';
  static const lastDayAddedWordKey = 'last_day_added_word';

  final HistoryDatabaseHelper helper = HistoryDatabaseHelper();

  ScrollController _scrollController = ScrollController();
  List<HistoryWord> _history = <HistoryWord>[];
  int _dateOfLastWord;
  bool _isRequestingMoreHistoryWords = false;
  List<String> _favorites = <String>[];
  List<HistoryWord> listSelected = <HistoryWord>[];
  bool _canCallFeatureDiscovery;
  bool _canAddNewWord = false;
  bool _isAddingNewWord = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr');

    _dateOfLastWord = DateTime.now().millisecondsSinceEpoch;
    _getMoreWords();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _getMoreWords();
      }
    });
    _canCallFeatureDiscovery = false;

    checkCanAddNewWord();
  }

  Future<DateTime> getLastDayAddedWord() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var lastDayInt = prefs.getInt(lastDayAddedWordKey);
    return DateTime.fromMillisecondsSinceEpoch(lastDayInt ?? 12700000000);
  }

  Future storeLastDayAddedWord() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final dateNow = DateTime.now();
    final dateToday = DateTime(dateNow.year, dateNow.month, dateNow.day);
    prefs.setInt(lastDayAddedWordKey, dateToday.millisecondsSinceEpoch);
  }

  Future checkCanAddNewWord() async {
    final dateNow = DateTime.now();
    final dateToday = DateTime(dateNow.year, dateNow.month, dateNow.day);
    var lastDayAddedWord = await getLastDayAddedWord();
    var isAfter = dateToday.isAfter(lastDayAddedWord);
    if (isAfter && !_canAddNewWord) {
      setState(() {
        _canAddNewWord = true;
      });
    } else if (!isAfter && _canAddNewWord) {
      setState(() {
        _canAddNewWord = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    checkCanAddNewWord();
    WidgetsBinding.instance.addPostFrameCallback((duration) {
      if (_canAddNewWord) {
        if (_canCallFeatureDiscovery) {
          if (_history.isEmpty) {
            FeatureDiscovery.discoverFeatures(context, const <String>[
              tagFab
            ] // Feature ids for every feature that you want to showcase in order},
                );
          } else {
            FeatureDiscovery.dismiss(context);
          }
        } else {
          // build is called after initState and called once afterwards.
          // We do not want to display feature discovery after initState because _history is not filled yet.
          _canCallFeatureDiscovery = true;
        }
      }
    });
    var nbSelectedWords = listSelected.length;
    return Scaffold(
        appBar: listSelected.isEmpty
            ? AppBar(
                title: Text(
                  'Mes mots',
                ),
                actions: <Widget>[
                  IconButton(
                    icon: Image.asset('assets/images/list_favorites.png'),
                    onPressed: _toFavorites,
                  )
                ],
              )
            : AppBar(
                backgroundColor: colorSecondary,
                leading: IconButton(
                  icon: Icon(Icons.close, color: colorAccentSecond),
                  onPressed: () {
                    setState(() {
                      listSelected = [];
                    });
                  },
                ),
                title: Text(
                  nbSelectedWords == 1
                      ? '1 mot sélectionné'
                      : '$nbSelectedWords mots sélectionnés',
                  style: TextStyle(color: colorAccentSecond),
                ),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.delete, color: colorAccentSecond),
                    onPressed: deleteAllSelected,
                  )
                ],
              ),
        body: _buildListViewHistory(),
        floatingActionButton: _isAddingNewWord
            ? FloatingActionButton(
                backgroundColor: colorAccent,
                child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.8,
                      valueColor: AlwaysStoppedAnimation<Color>(colorSecondary),
                    )),
                onPressed: null)
            : _canAddNewWord
                ? DescribedFeatureOverlay(
                    featureId: tagFab,
                    backgroundColor: colorAccentSecond,
                    textColor: colorSecondary,
                    tapTarget: Icon(Icons.add),
                    title: Text('Ajouter des mots'),
                    description: Text(
                        "Tu n'as pas encore de mots. Pour en obtenir, utilise le bouton \"plus\". Tu as droit à un mot par jour."),
                    child: FloatingActionButton(
                      child: Icon(Icons.add),
                      foregroundColor: colorSecondary,
                      onPressed: addNewWord,
                    ),
                  )
                : FloatingActionButton(
                    child: Icon(Icons.add),
                    foregroundColor: colorSecondary,
                    backgroundColor: colorGrayAccent,
                    onPressed: () {
                      flushbarFactory(
                          context: context,
                          messageString:
                              "Patiente jusqu'à demain pour découvrir un nouveau mot !");
                    },
                  ));
  }

  void deleteAllSelected() {
    var nbSelectedWords = listSelected.length;
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      nbSelectedWords == 1
                          ? 'Supprimer ce mot ?'
                          : 'Supprimer ces $nbSelectedWords mots ?',
                      style: TextStyle(
                          color: colorTextOnPrimary,
                          fontSize: 20,
                          fontStyle: FontStyle.normal),
                    ),
                    Divider(
                      color: colorAccentSecond,
                    )
                  ]),
              content: Text(
                  nbSelectedWords == 1
                      ? "Es-tu sûr·e de vouloir supprimer ${listSelected[0].name} ?"
                      : "Es-tu sûr·e de vouloir supprimer $nbSelectedWords mots ?",
                  style: TextStyle(
                      color: colorTextOnPrimary,
                      fontSize: 16,
                      fontStyle: FontStyle.normal)),
              actions: <Widget>[
                FlatButton(
                  child: Text(
                    'SUPPRIMER',
                    style: TextStyle(
                        color: colorTextOnPrimary,
                        fontSize: 16,
                        fontStyle: FontStyle.normal),
                  ),
                  onPressed: () {
                    setState(() {
                      listSelected.forEach((word) {
                        _deleteWord(word);
                      });
                      listSelected = [];
                    });
                    Navigator.of(context).pop();
                  },
                ),
                Container(
                    decoration: BoxDecoration(
                      color: colorAccent,
                    ),
                    child: FlatButton(
                      child: Text('ANNULER',
                          style: TextStyle(
                              color: colorSecondary,
                              fontSize: 16,
                              fontStyle: FontStyle.normal)),
                      textColor: colorTextOnAccent,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ))
              ],
            ));
  }

  void addNewWord() async {
    // display progress indicator
    setState(() {
      _isAddingNewWord = true;
    });

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
    var pickedWords = await helper.getAlreadyPickedWords();
    documentsList.removeWhere((item) => pickedWords.contains(item[columnName]));

    // choose randomly in the remainder
    final _random = Random();
    if (documentsList.isEmpty) {
      flushbarFactory(
          context: context,
          messageString: 'Tu as épuisé tous mes mots !',
          titleString: "C'est fini ! (Pour le moment)",
          buttonOnPressed: () async {
            const mailto =
                "mailto:fxstempfel@gmail.com?subject=[DailyWord] Mots épuisés&body=Il n'y a plus de mots disponibles ! Je VEUX des mots !";
            if (await canLaunch(mailto)) {
              await launch(mailto);
            }
          },
          buttonString: 'Dis-le moi');
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
        _canAddNewWord = false;
      });

      // store it into db
      helper.storeWord(wordMap: mapNewWord);

      // store date
      storeLastDayAddedWord();

      // stop progress indicator
      setState(() {
        _isAddingNewWord = false;
      });

      // to new route
      _pushToWordInfo(newWord);
    }
  }

  Widget _buildListViewHistory() => _history.isEmpty
      ? Column(children: <Widget>[
          Expanded(
              child: Center(
                  child: Text(
                "C'est bien triste sans mots...",
                style: Theme.of(context).textTheme.title,
              )),
              flex: 2),
          Expanded(
            child: Container(),
            flex: 3,
          )
        ])
      : ListView.builder(
          controller: _scrollController,
          itemCount: _isRequestingMoreHistoryWords
              ? 2 * _history.length + 1
              : 2 * _history.length,
          itemBuilder: (context, index) {
            if (index.isOdd) {
              return Divider(
                height: 0,
              );
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
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorAccent),
            ),
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
      dateText = "auj.";
    } else if (difference.inDays == 1) {
      dateText = 'hier';
    } else if (difference.inDays < 7) {
      dateText =
          Intl.withLocale('fr', () => DateFormat('E d').format(dateWord));
    } else if (difference.inDays < 365) {
      dateText = Intl.withLocale('fr', () => DateFormat('Md').format(dateWord));
    } else {
      dateText = Intl.withLocale('fr', () => DateFormat('y').format(dateWord));
    }

    return WordTile(this, word, dateText);
  }

  void _pushToWordInfo(HistoryWord word) async {
    var backArgs = await Navigator.of(context).pushNamed(WordInfoPage.routeName,
            arguments: HistoryToWordInfoArguments(word.name, word.isFavorite))
        as WordInfoToHistoryArguments;

    if (backArgs.toDelete) {
      _deleteWord(word);
    } else {
      if (backArgs.isFavorite && !word.isFavorite) {
        setState(() {
          _favorites.add(word.name);
          _favorites.sort();
          word.isFavorite = true;
        });
      } else if (!backArgs.isFavorite && word.isFavorite) {
        setState(() {
          _favorites.remove(word.name);
          word.isFavorite = false;
        });
      }
    }
  }

  Widget _saveFavoriteButton(HistoryWord word, {Color color}) => IconButton(
        onPressed: () async {
          setState(() {
            if (word.isFavorite) {
              _favorites.remove(word.name);
              word.isFavorite = false;
            } else {
              _favorites.add(word.name);
              _favorites.sort();
              word.isFavorite = true;
            }
          });
          helper.updateFavoriteWord(word.name, word.isFavorite);
        },
        icon: Icon(
          word.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: color ?? (word.isFavorite ? colorAccent : colorPrimary),
        ),
      );

  Widget _deleteFromHistoryButton(HistoryWord word) => IconButton(
        icon: Icon(
          Icons.delete,
          color: colorPrimary,
        ),
        onPressed: () {
          _showDialogDelete(word);
        },
      );

  void _showDialogDelete(HistoryWord word) {
    var contentText = (word.isFavorite)
        ? "Es-tu sûr·e de vouloir supprimer ${word.name} ?\nC'est un de tes favoris !"
        : "Es-tu sûr·e de vouloir supprimer ${word.name} ?";

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Supprimer ce mot ?',
                      style: TextStyle(
                          color: colorTextOnPrimary,
                          fontSize: 20,
                          fontStyle: FontStyle.normal),
                    ),
                    Divider(
                      color: colorAccentSecond,
                    )
                  ]),
              content: Text(contentText,
                  style: TextStyle(
                      color: colorTextOnPrimary,
                      fontSize: 16,
                      fontStyle: FontStyle.normal)),
              actions: <Widget>[
                FlatButton(
                  child: Text(
                    'SUPPRIMER',
                    style: TextStyle(
                        color: colorTextOnPrimary,
                        fontSize: 16,
                        fontStyle: FontStyle.normal),
                  ),
                  onPressed: () {
                    _deleteWord(word);
                    Navigator.of(context).pop();
                  },
                ),
                Container(
                    decoration: BoxDecoration(
                      color: colorAccent,
                    ),
                    child: FlatButton(
                      child: Text('ANNULER',
                          style: TextStyle(
                              color: colorSecondary,
                              fontSize: 16,
                              fontStyle: FontStyle.normal)),
                      textColor: colorTextOnAccent,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ))
              ],
            ));
  }

  Future _deleteWord(HistoryWord word) async {
    // first, remove from history
    setState(() {
      _history.remove(word);
      _favorites.remove(word.name);
    });

    // second, remove from database
    helper.deleteWord(word.name);
  }

  Future _getMoreWords() async {
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
        if (_history.isNotEmpty) {
          // scroller does not exist if in no scroller view has been initialized
          double edge = 50.0;
          double offsetFromBottom = _scrollController.position.maxScrollExtent -
              _scrollController.position.pixels;
          if (offsetFromBottom < edge) {
            _scrollController.animateTo(
                _scrollController.offset - (edge - offsetFromBottom),
                duration: new Duration(milliseconds: 500),
                curve: Curves.easeOut);
          }
        }
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
          _favorites.sort();
          _dateOfLastWord = _newWords.last.dateChosen;
          _isRequestingMoreHistoryWords = false;
        });
      }
    }
  }

// go to a page listing favorite words
  void _toFavorites() async {
    if (_favorites.isNotEmpty) {
      // go to FavoritesPage
      var backArgs = await Navigator.of(context).pushNamed(
              FavoritesPage.routeName,
              arguments: HistoryToFavoritesArguments(_favorites))
          as FavoritesToHistoryArguments;

      // delete words that have been deleted (can occur when navigating to word page, if the word is not found in firebase)
      backArgs.toDeleteFromHistoryNames.forEach((wordName) {
        _deleteWord(
            _history.where((word) => word.name == wordName).toList()[0]);
      });

      // update _favorites (some words might have been deleted)
      _favorites = backArgs.favoritesNames;

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
      flushbarFactory(
          context: context,
          messageString: "Tu n'as pas encore de favoris. Clique sur un cœur !");
    }
  }
}

class WordTile extends StatefulWidget {
  final HistoryState historyState;
  final HistoryWord word;
  final String dateText;

  const WordTile(this.historyState, this.word, this.dateText);

  @override
  State createState() => _WordTileState();
}

class _WordTileState extends State<WordTile> {
  var isSelected;

  @override
  void initState() {
    super.initState();
    isSelected = false;
  }

  void _selectWord(select) {
    if (select) {
      setState(() {
        isSelected = true;
      });
      widget.historyState.setState(() {
        widget.historyState.listSelected.add(widget.word);
      });
    } else {
      setState(() {
        isSelected = false;
      });
      widget.historyState.setState(() {
        widget.historyState.listSelected.remove(widget.word);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    isSelected = widget.historyState.listSelected.contains(widget.word);
    return Container(
        padding: EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
            color: isSelected ? colorAccentSecond : colorSecondary,
            border: BorderDirectional(
                top: BorderSide(color: colorSecondary, width: 0.5),
                bottom: BorderSide(color: colorSecondary, width: 0.5))),
        child: ListTile(
          leading: Container(
            alignment: Alignment.centerLeft,
            width: 60.0,
            child: Text(
              widget.dateText,
              style: isSelected
                  ? Theme.of(context)
                      .textTheme
                      .subtitle
                      .copyWith(color: colorSecondary)
                  : Theme.of(context).textTheme.subtitle,
            ),
          ),
          title: Text(
            widget.word.name,
            style: isSelected
                ? Theme.of(context)
                    .textTheme
                    .title
                    .copyWith(color: colorSecondary)
                : Theme.of(context).textTheme.title,
          ),
          trailing: Row(
            children: <Widget>[
              widget.historyState._saveFavoriteButton(widget.word,
                  color: isSelected ? colorSecondary : null),
              isSelected
                  ? IconButton(
                      icon: Icon(Icons.delete, color: colorAccentSecond),
                      onPressed: () {},
                    )
                  : widget.historyState._deleteFromHistoryButton(widget.word),
            ],
            mainAxisSize: MainAxisSize.min,
          ),
          onTap: () async {
            if (widget.historyState.listSelected.isNotEmpty) {
              _selectWord(!isSelected);
            } else {
              widget.historyState._pushToWordInfo(widget.word);
            }
          },
          onLongPress: () {
            _selectWord(!isSelected);
          },
        ));
  }
}
