import 'dart:core';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'cache_db.dart';
import 'history_db.dart';
import 'utils.dart';

final firebaseCollectionName = 'dictionary';

class WordInfoPage extends StatefulWidget {
  static const routeName = '/word';

  @override
  State<StatefulWidget> createState() => WordInfoPageState();
}

// TODO see malévole, "ou" between precisions / also boulingrin
// TODO when unfav-ing and pushing back buttons, refav-ing
class WordInfoPageState extends State<WordInfoPage> {
  final HistoryDatabaseHelper dbHelperHistory = HistoryDatabaseHelper();
  final CacheDatabaseHelper dbHelperCache = CacheDatabaseHelper();

  WordInfo wordInfo;
  String wordName;
  bool isFavorite;

  // TODO animate transitions

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments =
        ModalRoute.of(context).settings.arguments as HistoryToWordInfoArguments;

    wordName = arguments.wordName;
    isFavorite = arguments.isFavorite;
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            wordName,
          ),
          leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: colorSecondary,
              ),
              onPressed: () => Navigator.of(context)
                  .pop(WordInfoToHistoryArguments.favorite(isFavorite))),
        ),
        body: _buildBody(wordName),
      ),
      onWillPop: () async {
        Navigator.of(context)
            .pop(WordInfoToHistoryArguments.favorite(isFavorite));
        return Future.value(false);
      });

  Widget _buildBody(String wordName) => Container(
      constraints: BoxConstraints.expand(),
      child: (wordInfo == null)
          ? FutureBuilder(
              future: _getWordInfo(wordName),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.active:
                    return _showProgressIndicator();
                  case ConnectionState.waiting:
                    return _showProgressIndicator();
                  case ConnectionState.none:
                    return Center(
                        child: Text('Connexion au serveur impossible.'));
                  case ConnectionState.done:
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                            'Impossible de contacter le serveur :\n${snapshot.error}'),
                      );
                    } else {
                      wordInfo = snapshot.data;
                      if (wordInfo == null) {
                        return _buildWordNotFound();
                      } else {
                        return _buildWordInfo();
                      }
                    }
                    break;
                  default:
                    return null;
                }
              },
            )
          : _buildWordInfo());

  Widget _showProgressIndicator() => Column(children: <Widget>[
        SizedBox(
          height: 50.0,
        ),
        // word name
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Container(
                // to center word name
                width: 60.0,
              ),
              Container(
                alignment: Alignment.topCenter,
                child: AutoSizeText(
                  wordName,
                  style: Theme.of(context)
                      .textTheme
                      .display1
                      .copyWith(color: colorAccent),
                  maxLines: 1,
                ),
              ),
              Container(
                  alignment: Alignment.bottomLeft,
                  width: 60.0,
                  padding: EdgeInsets.only(bottom: 0, top: 12),
                  child: IconButton(
                    onPressed: () async {
                      setState(() {
                        isFavorite = !isFavorite;
                      });
                      dbHelperHistory.updateFavoriteWord(wordName, isFavorite);
                    },
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? colorAccent : colorPrimaryDark,
                    ),
                  )),
            ]),
// word type
        SizedBox(
          height: 80.0,
        ),
        Row(children: [
          Expanded(
              child: Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorAccent)),
          ))
        ])
      ]);

  // TODO propose to replace with another word
  Widget _buildWordNotFound() => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Center(
                  child: RichText(
                text: TextSpan(
                    text: 'Impossible de trouver ',
                    style: Theme.of(context).textTheme.body2,
                    children: [
                      TextSpan(
                          text: '$wordName',
                          style: Theme.of(context)
                              .textTheme
                              .body2
                              .copyWith(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text:
                              " dans la base de données. Cela est probablement dû à sa suppression. Tu n'auras plus accès à sa définition, à moins qu'il soit à nouveau ajouté. Veux-tu le supprimer de tes mots ?",
                          style: Theme.of(context).textTheme.body2)
                    ]),
              ))),
          SizedBox(
            height: 32,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              FlatButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(WordInfoToHistoryArguments.favorite(isFavorite));
                  },
                  child: Text('GARDER',
                      style: Theme.of(context).textTheme.button)),
              FlatButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(WordInfoToHistoryArguments.toDelete());
                },
                child: Text('SUPPRIMER',
                    style: Theme.of(context)
                        .textTheme
                        .button
                        .copyWith(color: colorSecondary)),
                color: colorAccent,
              )
            ],
          )
        ],
      );

  Widget _buildWordInfo() => Column(
        children: <Widget>[
          SizedBox(
            height: 50.0,
          ),
          // word name
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Container(
                  // to center word name
                  width: 60.0,
                ),
                Container(
                  alignment: Alignment.topCenter,
                  child: AutoSizeText(
                    wordName,
                    style: Theme.of(context)
                        .textTheme
                        .display1
                        .copyWith(color: colorAccent),
                    maxLines: 1,
                  ),
                ),
                Container(
                    alignment: Alignment.bottomLeft,
                    width: 60.0,
                    padding: EdgeInsets.only(bottom: 0, top: 12),
                    child: IconButton(
                      onPressed: () async {
                        setState(() {
                          isFavorite = !isFavorite;
                        });
                        dbHelperHistory.updateFavoriteWord(
                            wordName, isFavorite);
                      },
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? colorAccent : colorPrimaryDark,
                      ),
                    )),
              ]),
          // word type
          Container(
            padding: EdgeInsets.only(top: 0.0, bottom: 16.0),
            alignment: Alignment.topCenter,
            child: Text(
              wordInfo.type,
              style: Theme.of(context).textTheme.subhead,
            ),
          ),
          // definition link & conjugation link if existing
          Container(
              padding: EdgeInsets.only(bottom: 24.0),
              alignment: Alignment.topCenter,
              height: 60.0,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    OutlineButton(
                        shape: StadiumBorder(),
                        borderSide: BorderSide(color: colorAccent),
                        onPressed: () async {
                          if (await canLaunch(wordInfo.link)) {
                            await launch(wordInfo.link);
                          }
                        },
                        child: Text(
                          wordInfo.link.contains('wiktionary')
                              ? 'Wiktionnaire'
                              : wordInfo.link.contains('larousse')
                                  ? 'Larousse'
                                  : 'Lien',
                          style: Theme.of(context).textTheme.button.copyWith(
                              color: colorAccent,
                              fontSize: 20,
                              fontFamily: 'DancingScript'),
                        )),
                    (wordInfo.conjugationLink != null)
                        ? OutlineButton(
                            shape: StadiumBorder(),
                            borderSide: BorderSide(color: colorAccent),
                            onPressed: () async {
                              if (await canLaunch(wordInfo.conjugationLink)) {
                                await launch(wordInfo.conjugationLink);
                              }
                            },
                            child: Text(
                              'Conjugaison',
                              style: Theme.of(context)
                                  .textTheme
                                  .button
                                  .copyWith(
                                      color: colorAccent,
                                      fontSize: 20,
                                      fontFamily: 'DancingScript'),
                            ))
                        : null
                  ].where((Object o) => o != null).toList())),
          // list of definitions
          _buildDefinitionList(),
        ],
      );

  Widget _buildDefinitionList() => Expanded(
          child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 32.0),
        shrinkWrap: true,
        itemCount: wordInfo.definitions.length,
        itemBuilder: (context, index) =>
            _buildDefinitionRow(index, wordInfo.definitions[index]),
        separatorBuilder: (context, index) => Divider(),
      ));

  Widget _buildDefinitionRow(int index, Definition definition) =>
      DefinitionItem(index, definition);

  Future<WordInfo> _getWordInfo(String wordName) async {
    // look for the info in cache
    var word = await dbHelperCache.getWordInfo(wordName);
    if (word != null) {
      return WordInfo.fromMap(word);
    } else {
      // if not found, get from firebase
      var documentSnapshot = await Firestore.instance
          .collection(firebaseCollectionName)
          .document(wordName)
          .get();

      if (documentSnapshot == null || documentSnapshot.data == null) {
        // if still not found in firebase, it might have been deleted
        return null;
      } else {
        // else, everything OK
        var wordFirebase = WordInfo.fromMap(documentSnapshot.data);
        dbHelperCache.storeWordInfo(wordFirebase);
        return wordFirebase;
      }
    }
  }
}

class DefinitionItem extends StatefulWidget {
  final int index;
  final Definition definition;
  final bool unrolled;

  const DefinitionItem(this.index, this.definition, [this.unrolled = false]);

  @override
  State<StatefulWidget> createState() => DefinitionItemState();
}

class DefinitionItemState extends State<DefinitionItem> {
  var unrolled = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: () {
        setState(() {
          if (widget.definition.examples != null) {
            unrolled = !unrolled;
          }
        });
      },
      child: Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Container(
                alignment: Alignment.topRight,
                child: Text(
                  '${widget.index + 1}. ',
                  style: Theme.of(context).textTheme.body2,
                ),
              ),
            ),
            Expanded(
                flex: 11, child: _buildDefinitionAndExample(widget.definition)),
            Expanded(
                flex: 1,
                child: widget.definition.examples == null
                    ? Container()
                    : Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                            unrolled ? Icons.expand_less : Icons.expand_more,
                            color: colorPrimaryDark),
                      ))
          ],
        ),
        padding: EdgeInsets.only(bottom: 8.0),
      ));

  Widget _buildDefinitionAndExample(Definition definition) {
    var textSpans = <TextSpan>[];
    // 1. add precisions surrounded with parenthesis
    if (definition.precisions != null) {
      var textPrecisions =
          definition.precisions.map((precision) => '($precision)').join(' ') +
              ' ';
      textSpans.add(TextSpan(
          text: textPrecisions,
          style: Theme.of(context).textTheme.body2.copyWith(
              color: colorPrimaryDark,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400)));
    }

    // 2. add meaning
    textSpans.add(TextSpan(
        text: '${definition.meaning}\n',
        style: Theme.of(context).textTheme.body2));

    if (definition.examples != null && unrolled) {
      // 3. add examples with author & work
      for (var example in definition.examples) {
        textSpans.add(TextSpan(
            text: '\n"${example.text}"',
            style: Theme.of(context).textTheme.body1));
        if (example.author != null || example.work != null) {
          textSpans.add(TextSpan(text: '\n'));
        }
        if (example.author != null) {
          textSpans.add(TextSpan(
              text: example.work == null
                  ? ' ${example.author.toUpperCase()}'
                  : ' ${example.author.toUpperCase()},',
              style: Theme.of(context)
                  .textTheme
                  .caption
                  .copyWith(fontStyle: FontStyle.normal)));
        }
        if (example.work != null) {
          textSpans.add(TextSpan(
              text: ' ${example.work}',
              style: Theme.of(context).textTheme.caption));
        }
        textSpans.add(TextSpan(text: '\n'));
      }
    }

    final richText = RichText(
        textAlign: TextAlign.justify,
        text: TextSpan(
            text: textSpans[0].text,
            style: textSpans[0].style,
            children: textSpans.getRange(1, textSpans.length).toList()));
    return AnimatedContainer(
        duration: Duration(seconds: 1),
        alignment: Alignment.topLeft,
        curve: Curves.easeOutQuint,
        child: richText);
  }
}
