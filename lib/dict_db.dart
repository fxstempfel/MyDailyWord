import 'package:sqflite/sqflite.dart';

final String wordDbName = 'word.db';
final String wordTableName = 'words';
final String columnName = 'name';
final String columnDateChosen = "date";

class HistoryWord {
  String name;
  int dateChosen;

  HistoryWord({this.name, this.dateChosen});

  HistoryWord.fromMap(Map<String, dynamic> map) {
    name = map[columnName];
    dateChosen = map[columnDateChosen];
  }

  Map<String, dynamic> toMap() => {
    columnName: name,
    columnDateChosen: dateChosen
  };
}

class HistoryDatabaseHelper {
  Database db;

  Future open() async {
    db = await openDatabase(
      wordDbName,
      onCreate: (Database db, int version) async {
        await db.execute('CREATE TABLE IF NOT EXISTS $wordTableName(name TEXT PRIMARY KEY, dateChosen INTEGER)');
      },
      version: 1,
    );
  }

  Future<List<HistoryWord>> getLastWords(int chunkSize, int oldestPreviousDate) async {
    List<Map> maps = await db.query(
        wordTableName,
        where: '$columnDateChosen < ?',
        whereArgs: [oldestPreviousDate],
        orderBy: '$columnDateChosen DESC',
        limit: chunkSize
    );
    if (maps.length == 0) {
      return null;
    } else {
      return maps.map((m) => HistoryWord.fromMap(m)).toList();
    }
  }

  Future storeWord(HistoryWord word) async {
    await db.insert(
      wordTableName,
      word.toMap(),
    );
  }
}

