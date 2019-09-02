import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'utils.dart';

final styleName = TextStyle(
    fontWeight: FontWeight.bold, fontSize: 30.0, fontFamily: 'Roboto');
final styleType = TextStyle(fontStyle: FontStyle.italic, fontSize: 16.0);
final styleDefinition = TextStyle(fontSize: 16.0);
final styleDefinitionLead = TextStyle(fontSize: 16.0, color: Colors.grey[700]);
final styleExample = TextStyle(
    fontStyle: FontStyle.italic, fontSize: 16.0, color: Colors.grey[700]);

final firebaseCollectionName = 'dictionary';

class WordInfoPage extends StatefulWidget {
  static const routeName = '/word';

  @override
  State<StatefulWidget> createState() => WordInfoPageState();
}

// TODO page style => background, font etc
class WordInfoPageState extends State<WordInfoPage> {
  WordInfo wordInfo;
  String wordName;
  bool isFavorite;

  // TODO cache recent def?
  // TODO see issues with definitions of eg glacis, eg "GéographiePlan"
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(wordName),
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context, isFavorite)),
        ),
        body: _buildBody(wordName),
      );

  Widget _buildBody(String wordName) => Hero(
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
                                    'ERROR: could not get data from server\n${snapshot.error}'),
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

  Widget _showProgressIndicator() => Row(children: [
        Expanded(
            child: Center(
          child: CircularProgressIndicator(),
        ))
      ]);

  Widget _buildWordInfo() => Column(
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
              ),
            ),
            trailing: Container(
                alignment: Alignment.centerLeft,
                width: 60.0,
                child: IconButton(
                  onPressed: () {
                    print('tapped fav = $isFavorite');
                    setState(() {
                      isFavorite = !isFavorite;
                    });
                    print('after $isFavorite');
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
          // conjugation link or empty space
          Container(
            padding: EdgeInsets.only(
                bottom: (wordInfo.conjugationLink == null) ? 0.0 : 24.0),
            alignment: Alignment.topCenter,
            height: 60.0,
            child: (wordInfo.conjugationLink == null)
                ? Container()
                : OutlineButton(
                    // TODO check button is working
                    shape: StadiumBorder(),
                    borderSide: BorderSide(color: Colors.blue),
                    textColor: Colors.blue,
                    onPressed: () async {
                      print('conjugation pressed');
                      if (await canLaunch(wordInfo.conjugationLink)) {
                        await launch(wordInfo.conjugationLink);
                      }
                    },
                    child: Text('CONJUGAISON')),
          ),
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

  WordInfo(this.name, this.type, this.definitions, this.conjugationLink);

  WordInfo.fromMap(Map<String, dynamic> wordMap) {
    name = wordMap['name'];
    type = wordMap['type'];
    conjugationLink = wordMap['conjugation_link'];
    definitions = wordMap['definitions']
        .map((defMap) => Definition(defMap['meaning'], defMap['example']))
        .toList()
        .cast<Definition>();
  }
}

class Definition {
  String meaning;
  String example;

  Definition(this.meaning, this.example);

  String toString() => '${this.meaning}\nExample: ${this.example}';
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
          unrolled = !unrolled;
        });
        print(
            'example ${widget.definition.example.length} = ${widget.definition.example}');
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
                  style: styleDefinitionLead,
                ),
              ),
            ),
            Expanded(
                flex: 11, child: _buildDefinitionAndExample(widget.definition)),
          ],
        ),
        padding: EdgeInsets.only(bottom: 8.0),
      ));

  Widget _buildDefinitionAndExample(Definition definition) => AnimatedContainer(
      duration: Duration(seconds: 1),
      alignment: Alignment.topLeft,
      child: (definition.example == null || !unrolled)
          ? Text(
              definition.meaning,
              style: styleDefinition,
            )
          : AutoSizeText.rich(TextSpan(
              text: definition.meaning,
              style: styleDefinition,
              children: <InlineSpan>[
                  TextSpan(text: '\n${definition.example}', style: styleExample)
                ])));
}
