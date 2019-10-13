import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

final dbName = 'nosql_database.db';
final cacheStoreName = 'cache_words';
final recentWordsCacheSize = 6;

class CacheDatabaseHelper {
  var db;
  var store;

  CacheDatabaseHelper() {
    store = stringMapStoreFactory.store(cacheStoreName);
  }

  Future open() async {
    var dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    var dbPath = join(dir.path, dbName);
    db = await databaseFactoryIo.openDatabase(dbPath, version: 0);
  }

  Future storeWordInfo(WordInfo word) async {
    if (db == null) {
      await open();
    }

    // check if cache is full
    var allRecords = await store.find(db);
    var amountToDelete = allRecords.length - recentWordsCacheSize + 1;
    if (amountToDelete > 0) {
      // if so delete some words
      allRecords.sort((a, b) => (a[WordInfo.dateCachedKey] as int)
          .compareTo(b[WordInfo.dateCachedKey] as int));
      var toRemove = allRecords
          .sublist(0, amountToDelete)
          .map((rec) => rec[WordInfo.nameKey])
          .toList()
          .cast<String>();

      await db.transaction((txn) async {
        await store.records(toRemove).delete(txn);
      });
    }

    // store record and keep track of date
    await db.transaction((txn) async {
      await store.record(word.name).put(txn, word.toMap(DateTime.now()));
    });
  }

  Future<Map<String, dynamic>> getWordInfo(String wordName) async {
    if (db == null) {
      await open();
    }
    return store.record(wordName)?.get(db);
  }
}

class WordInfo {
  static final nameKey = 'name';
  static final typeKey = 'type';
  static final definitionsKey = 'definitions';
  static final conjugationLinkKey = 'conjugation_link';
  static final linkKey = 'link';
  static final dateCachedKey = 'date_cached';

  String name;
  String type;
  List<Definition> definitions;
  String conjugationLink;
  String link;

  WordInfo(
      this.name, this.type, this.definitions, this.conjugationLink, this.link);

  WordInfo.fromMap(Map<String, dynamic> wordMap) {
    name = wordMap[nameKey];
    type = wordMap[typeKey];
    conjugationLink = wordMap[conjugationLinkKey];
    definitions = wordMap[definitionsKey]
        .map((defMap) => Definition.fromMap(defMap))
        .toList()
        .cast<Definition>();
    link = wordMap[linkKey];
  }

  Map<String, dynamic> toMap([DateTime dateTime]) => {
        nameKey: name,
        typeKey: type,
        definitionsKey: definitions.map((def) => def.toMap()).toList(),
        conjugationLinkKey: conjugationLink,
        linkKey: link,
        dateCachedKey: dateTime?.millisecondsSinceEpoch
      };
}

class Definition {
  final meaningKey = 'meaning';
  final examplesKey = 'examples';
  final precisionsKey = 'precisions';

  String meaning;
  List<Example> examples;
  List<String> precisions;

  Definition(this.meaning, this.examples, this.precisions);

  Definition.fromMap(Map<dynamic, dynamic> argMap) {
    this.meaning = argMap[meaningKey];
    this.examples = argMap[examplesKey]
        ?.map((exampleMap) => Example.fromMap(exampleMap))
        ?.toList()
        ?.cast<Example>();
    this.precisions = argMap[precisionsKey]?.cast<String>();
  }

  Map<String, dynamic> toMap() => {
        meaningKey: meaning,
        examplesKey: examples?.map((ex) => ex.toMap())?.toList(),
        precisionsKey: precisions
      };

  String toString() => '${this.meaning}\nExamples: ${this.examples}';
}

class Example {
  final textKey = 'text';
  final authorKey = 'author';
  final workKey = 'work';

  String text;
  String author;
  String work;

  Example(this.text, this.author, this.work);

  Example.fromMap(Map<dynamic, dynamic> map) {
    this.text = map[textKey];
    this.author = map[authorKey];
    this.work = map[workKey];
  }

  Map<String, String> toMap() =>
      {textKey: text, authorKey: author, workKey: work};
}
