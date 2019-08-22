import 'package:flutter/material.dart';

import 'dict_db.dart';

final int updateChunkSize = 10;


void main() => runApp(DailyWordApp());

// TODO use json_serializable to store words = make Word class

class DailyWordApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Daily Word',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Mes derniers mots'),
        ),
        body: Center(
          child: History(),
        ),
      ),
    );
  }
}

class History extends StatefulWidget {
  @override
  HistoryState createState() => HistoryState();
}

class HistoryState extends State<History> {
  final Set<HistoryWord> _favorites = Set<HistoryWord>();
  final _bigFont = const TextStyle(fontSize: 18);
  final HistoryDatabaseHelper helper = HistoryDatabaseHelper();
  var dateOfLastWord = DateTime
      .now()
      .millisecondsSinceEpoch;

  @override
  Widget build(BuildContext context) =>
      Scaffold(
        appBar: AppBar(
          title: Text("My Words"),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.list), onPressed: _pushSaved,)
          ],
        ),
        body: _buildSuggestions(),
      );

  void _pushSaved() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) {
          final Iterable<ListTile> tiles = _favorites.map(
                  (HistoryWord word) {
                return ListTile(
                  title: Text(
                    word.name,
                    style: _bigFont,
                  ),
                );
              }
          );
          final List<Widget> divided = ListTile
              .divideTiles(
            tiles: tiles,
            context: context,
          ).toList();

          return Scaffold(
            appBar: AppBar(
              title: Text("Saved Suggestions"),
            ),
            body: ListView(children: divided,),
          );
        }));
  }

  Widget _buildSuggestions() =>
      FutureBuilder(
          future: _getNextWord(),
          builder: (BuildContext context, AsyncSnapshot<HistoryWord> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
              // loading...
                return Center(child: new CircularProgressIndicator());
              case ConnectionState.active:
              // should not happen
                return Text('');
              case ConnectionState.none:
                return Text(
                  'Failing to load this word',
                  style: TextStyle(color: Colors.red),
                );
              case ConnectionState.done:
              // data or error received
                var result;
                if (snapshot.hasError) {
                  result = Text("Could not load this word: ${snapshot.error}");
                } else {
                  result = wordListViewBuilder(snapshot);
                }
                return result;
              default:
                return Text('Something unexpected happended');
            }
          },
      );

  Widget wordListViewBuilder(AsyncSnapshot snapshot) =>
      ListView.builder(
          padding: const EdgeInsets.all(16),
          itemBuilder: (BuildContext context, int i) {
            if (i.isOdd)
              return Divider();
            else
              return _buildRow(snapshot.data);
          }
      );

  Future<HistoryWord> _getNextWord() async {
    HistoryWord word = (await helper.getLastWords(1, dateOfLastWord))[0];
    dateOfLastWord = word.dateChosen;
    return word;
  }

  Widget _buildRow(HistoryWord word) {
    final bool alreadySaved = _favorites.contains(word);
    return ListTile(
      title: Text(
        word.name,
        style: _bigFont,
      ),
      trailing: FlatButton.icon(
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
          label: null
      ),
      onTap: () {
        // TODO change that to open word description instead
      },
    );
  }
}
