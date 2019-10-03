import 'dart:core';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dict_db.dart';
import 'utils.dart';

final styleName = TextStyle(
    fontWeight: FontWeight.bold, fontSize: 30.0, fontFamily: 'Roboto');
final styleType = TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0);
final styleDefinition =
TextStyle(fontSize: 16.0, color: Colors.black, fontStyle: FontStyle.normal);
final styleDefinitionNumber = TextStyle(
    fontSize: 16.0, color: Colors.grey[700], fontStyle: FontStyle.normal);
final styleDefinitionPrecision = TextStyle(
    fontSize: 16.0, color: Colors.grey[700], fontStyle: FontStyle.italic);
final styleExample = TextStyle(
    fontStyle: FontStyle.italic, fontSize: 16.0, color: Colors.blueAccent);
final styleExampleAuthors = TextStyle(
    fontFamily: 'CarroisGothic', fontSize: 14.0, fontStyle: FontStyle.normal);
final styleExampleWork = TextStyle(fontStyle: FontStyle.italic, fontSize: 14.0);

final firebaseCollectionName = 'dictionary';

class WordInfoPage extends StatefulWidget {
  static const routeName = '/word';

  @override
  State<StatefulWidget> createState() => WordInfoPageState();
}

// TODO PRIORITY: rewrite isFavorite handling. Do not make that many calls to db
// TODO     but pass from page to page. Call db only when changing and at init

// TODO page style => background, font etc
class WordInfoPageState extends State<WordInfoPage> {
  final HistoryDatabaseHelper helper = HistoryDatabaseHelper();

  WordInfo wordInfo;
  String wordName;
  bool isFavorite;

  // TODO cache recent def?
  // TODO animate transitions

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments =
    ModalRoute
        .of(context)
        .settings
        .arguments as HistoryToWordInfoArguments;

    wordName = arguments.wordName;
    isFavorite = arguments.isFavorite;
  }

  @override
  Widget build(BuildContext context) =>
      WillPopScope(
          child: Scaffold(
            appBar: AppBar(
              title: Text(wordName),
              leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(isFavorite)),
            ),
            body: _buildBody(wordName),
          ),
          onWillPop: () async {
            Navigator.of(context).pop(isFavorite);
            return Future.value(false);
          });

  Widget _buildBody(String wordName) =>
      Hero(
          tag: wordName,
          child: Container(
              constraints: BoxConstraints.expand(),

              // TODO display word name while retrieving info
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
                      return Center(child: Text('ERROR: cannot connect'));
                    case ConnectionState.done:
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                              'ERROR: could not get data from server\n${snapshot
                                  .error}'),
                        );
                      } else {
                        wordInfo = snapshot.data;
                        return _buildWordInfo();
                      }
                      break;
                    default:
                      return null;
                  }
                },
              )
                  : _buildWordInfo()));

  Widget _showProgressIndicator() =>
      Row(children: [
        Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ))
      ]);

  Widget _buildWordInfo() =>
      Column(
        children: <Widget>[
          SizedBox(
            height: 50.0,
          ),
          // word name
          ListTile(
            leading: Container(
              // to center word name
              width: 60.0,
            ),
            title: Container(
              alignment: Alignment.center,
              child: AutoSizeText(
                wordInfo.name,
                style: styleName,
                maxLines: 1,
              ),
            ),
            trailing: Container(
                alignment: Alignment.centerLeft,
                width: 60.0,
                child: IconButton(
                  onPressed: () async {
                    print('tapped fav = $isFavorite');
                    setState(() {
                      isFavorite = !isFavorite;
                    });
                    await helper.updateFavoriteWord(wordName, isFavorite);
                    print('after = $isFavorite');
                  },
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                )),
          ),
          // word type
          Container(
            padding: EdgeInsets.only(top: 0.0, bottom: 16.0),
            alignment: Alignment.topCenter,
            child: Text(
              wordInfo.type,
              style: styleType,
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
                        borderSide: BorderSide(color: Colors.blue),
                        textColor: Colors.blue,
                        onPressed: () async {
                          print('link pressed');
                          if (await canLaunch(wordInfo.link)) {
                            await launch(wordInfo.link);
                          }
                        },
                        child: Text(wordInfo.link.contains('wiktionary')
                            ? 'WIKTIONNAIRE'
                            : wordInfo.link.contains('larousse')
                            ? 'LAROUSSE'
                            : 'LIEN')),
                    (wordInfo.conjugationLink != null)
                        ? OutlineButton(
                        shape: StadiumBorder(),
                        borderSide: BorderSide(color: Colors.blue),
                        textColor: Colors.blue,
                        onPressed: () async {
                          print('conjugation pressed');
                          if (await canLaunch(wordInfo.conjugationLink)) {
                            await launch(wordInfo.conjugationLink);
                          }
                        },
                        child: Text('CONJUGAISON'))
                        : null
                  ].where((Object o) => o != null).toList())),
          // list of definitions
          _buildDefinitionList(),
        ],
      );

  Widget _buildDefinitionList() =>
      Expanded(
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

// TODO unroll some words by default

  Future<WordInfo> _getWordInfo(String wordName) async {
    DocumentSnapshot documentSnapshot = await Firestore.instance
        .collection(firebaseCollectionName)
        .document(wordName)
        .get();
    return WordInfo.fromMap(documentSnapshot.data);
  }
}

class WordInfo {
  String name;
  String type;
  List<Definition> definitions;
  String conjugationLink;
  String link;

  WordInfo(this.name, this.type, this.definitions, this.conjugationLink,
      this.link);

  WordInfo.fromMap(Map<String, dynamic> wordMap) {
    name = wordMap['name'];
    type = wordMap['type'];
    conjugationLink = wordMap['conjugation_link'];
    definitions = wordMap['definitions']
        .map((defMap) => Definition.fromMap(defMap))
        .toList()
        .cast<Definition>();
    link = wordMap['link'];
  }
}

class Definition {
  String meaning;
  List<Example> examples;
  List<String> precisions;

  Definition(this.meaning, this.examples, this.precisions);

  Definition.fromMap(Map<dynamic, dynamic> argMap) {
    this.meaning = argMap['meaning'];
    this.examples = (argMap['examples'] == null)
        ? null
        : argMap['examples']
        .map((exampleMap) => Example.fromMap(exampleMap))
        .toList()
        .cast<Example>();
    this.precisions = (argMap['precisions'] == null)
        ? null
        : argMap['precisions'].cast<String>();
  }

  String toString() => '${this.meaning}\nExamples: ${this.examples}';
}

class Example {
  String text;
  String author;
  String work;

  Example(this.text, this.author, this.work);

  Example.fromMap(Map<dynamic, dynamic> map) {
    this.text = map['text'];
    this.author = map['author'];
    this.work = map['work'];
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
  Widget build(BuildContext context) =>
      GestureDetector(
          onTap: () {
            setState(() {
              // todo test when no examples (nothing to unroll)
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
                      style: styleDefinitionNumber,
                    ),
                  ),
                ),
                Expanded(
                    flex: 11,
                    child: _buildDefinitionAndExample(widget.definition)),
                Expanded(
                  flex: 1,
                  child: widget.definition.examples == null
                      ? Container()
                      : Icon(unrolled ? Icons.expand_less : Icons.expand_more),
                )
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
      textSpans
          .add(TextSpan(text: textPrecisions, style: styleDefinitionPrecision));
    }

    // 2. add meaning
    textSpans
        .add(TextSpan(text: '${definition.meaning}\n', style: styleDefinition));

    if (definition.examples != null && unrolled) {
      // 3. add examples with author & work
      for (var example in definition.examples) {
        textSpans
            .add(TextSpan(text: '\n"${example.text}"', style: styleExample));
        if (example.author != null || example.work != null) {
          textSpans.add(TextSpan(text: '\n'));
        }
        if (example.author != null) {
          textSpans.add(TextSpan(
              text: example.work == null
                  ? ' ${example.author}'
                  : ' ${example.author},',
              style: styleExampleAuthors));
        }
        if (example.work != null) {
          textSpans
              .add(TextSpan(text: ' ${example.work}', style: styleExampleWork));
        }
        textSpans.add(TextSpan(text: '\n'));
      }
    }

    final richText = RichText(
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
