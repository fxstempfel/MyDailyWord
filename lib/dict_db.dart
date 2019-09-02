import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

final String wordDbName = 'word.db';
final String wordTableName = 'words';
final String columnName = 'name';
final String columnDateChosen = 'dateChosen';
final String columnIsFavorite = 'isFavorite';
final int sqlFalse = 0;
final int sqlTrue = 1;

class HistoryWord {
  String name;
  int dateChosen;
  bool isFavorite;

  HistoryWord({this.name, this.dateChosen, this.isFavorite});

  HistoryWord.fromMap(Map<String, dynamic> map) {
    name = map[columnName];
    dateChosen = map[columnDateChosen];
    isFavorite = map[columnIsFavorite] == 1 ? true : false;
  }

  Map<String, dynamic> toMap() => {
    columnName: name,
    columnDateChosen: dateChosen,
    columnIsFavorite: isFavorite ? 1 : 0,
  };
}

class HistoryDatabaseHelper {
  Database _db;
  final _lock = Lock();

  Future open() async {
    print('open start');
    if (_db == null) {
      await _lock.synchronized(() async {
        if (_db == null) {
          print('opening db');
          _db = await openDatabase(
            wordDbName,
            version: 2,
          );
        }
      });
    }
    await _db.execute(
        'CREATE TABLE IF NOT EXISTS $wordTableName ($columnName TEXT PRIMARY KEY, $columnDateChosen INTEGER, $columnIsFavorite INTEGER)'
    );
    print('open end');
  }

  Future<List<HistoryWord>> getMostRecentWordsAfter(int chunkSize, int afterDate) async {
    print('getWords start');
    await open();
    print('db content ${await _db.query(wordTableName)}');
    List<Map> maps = await _db.query(
        wordTableName,
        where: '$columnDateChosen < ?',
        whereArgs: [afterDate],
        orderBy: '$columnDateChosen DESC',
        limit: chunkSize
    );
    print('getWords end');
    if (maps.length == 0) {
      return null;
    } else {
      return maps.map((m) => HistoryWord.fromMap(m)).toList();
    }
  }

  Future<HistoryWord> getMostRecentWordAfter(int afterDate) async {
    print('getWord start');
    await open();
    var list = await getMostRecentWordsAfter(1, afterDate);
    var word = list == null ? null : list[0];
    print('getWord end with ${word.name}');
    return word;
  }

  Future<List<String>> getAlreadyPickedWords() async {
    // Returns the list of names of words that have already been picked
    await open();
    var names = await _db.query(
      wordTableName,
      columns: <String>[columnName],
    );

    return names.map((Map<String, dynamic> map) => map[columnName] as String).toList();
  }

  Future storeWord({HistoryWord word, Map<String, dynamic> wordMap}) async {
    assert((word != null || wordMap != null) && !(word != null && wordMap != null));
    if (word != null) {
      wordMap = word.toMap();
    }
    await open();
    await _db.insert(
      wordTableName,
      wordMap,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future deleteWord(String wordName) async {
    await open();
    await _db.delete(
        wordTableName,
        where: '$columnName = ?',
        whereArgs: [wordName],
    );
  }
}

