// part of hamlog;

abstract class HamlogStorage {
  // Storage(String url);

  async.Future<List<Log>> loadLogs();

  async.Future<Log> loadQsos(Log log);

  async.Future<Qso> addQso(Qso qso);

  async.Future<Log> addLog(Log log);

  async.Future<Qso> updateQso(Qso qso);

  async.Future<Log> updateLog(Log log);

  async.Future<Qso> deleteQso(Qso qso);

  async.Future<Log> deleteLog(Log log);
}

class IndexedDBStorage implements HamlogStorage {
  static const VERSION = 1;
  static const DATABASE = "hamlog";
  static const LOGS_STORAGE = "logs";
  static const QSOS_STORAGE = "qsos";
  static const LOGS_INDEX = "logId";
  static const QSOS_INDEX = "qsoId";

  idb.Database _db;

  IndexedDBStorage(String url) {
    if (!idb.IdbFactory.supported) {
      throw new UnsupportedError("Used DataStorage implementation is not supported");
    }
//    html.window.indexedDB.deleteDatabase(DATABASE);
    open(url);
  }

  async.Future open(String url) {
    _debug("HamlogStorage.open: ${url}");
    return html.window.indexedDB.open(url, version: VERSION,
        onUpgradeNeeded: (e) {
          _debug("Initializing storage...");
          idb.Database db = e.target.result;
          if (!db.objectStoreNames.contains(LOGS_STORAGE)) {
            var objectStore = db.createObjectStore(LOGS_STORAGE, /*keyPath: Log.KEY_PATH,*/ autoIncrement: false);
            objectStore.createIndex(LOGS_INDEX, Log.KEY_PATH, unique: true);
          }
          if (!db.objectStoreNames.contains(QSOS_STORAGE)) {
            var objectStore = db.createObjectStore(QSOS_STORAGE, /*keyPath: Qso.KEY_PATH,*/ autoIncrement: false);
            objectStore.createIndex(QSOS_INDEX, Qso.KEY_PATH, unique: true);
          }
        }).then((db) {
          _db = db;
          info();
        });

  }

  info() {
    html.window.indexedDB.getDatabaseNames().then((names) {
      _debug("databases: ${names.join(' ')}");
    });

    _debug("db: ${_db.name}, version: ${_db.version}");
    _debug("object stores: ${_db.objectStoreNames.join(' ')}");
    _db.transaction([LOGS_STORAGE], 'readonly').objectStore(LOGS_STORAGE).indexNames.forEach((name) => _debug("log index: ${name}"));
    _db.transaction([QSOS_STORAGE], 'readonly').objectStore(QSOS_STORAGE).indexNames.forEach((name) => _debug("qso index: ${name}"));
  }

  async.Future<List<Log>> loadLogs() {
    _debug("HamlogStorage.loadLogs");
    // async.StreamController<Log> controller = new async.StreamController<Log>();
    var logs = <Log>[];
    idb.Transaction tx = _db.transaction([LOGS_STORAGE], 'readonly');
    tx.objectStore(LOGS_STORAGE).openCursor(autoAdvance: true)
      .listen(
        (cursor) {
          Log log = new Log.fromMap(cursor.key, cursor.value);
          logs.add(log);
        },
        // onError: (e) => controller.addError(e),
        // onDone: () => controller.close()
        onDone: () => logs.sort());

    // return controller.stream;
    return tx.completed.then((_) => logs);
  }

  async.Future<Log> loadQsos(Log log) {
    _debug("HamlogStorage.loadQsos: ${log.id}");
    var qsos = [];
    idb.Transaction tx = _db.transaction([QSOS_STORAGE], 'readonly');
    tx.objectStore(QSOS_STORAGE).openCursor(autoAdvance: true)
//      .length.then((len) => print("cursor aa len: " + len.toString()));
//      var index = objectStore.index(QSOS_INDEX);
//      index.count().then((count) => print("count: " + count.toString()));
//      index.count(logKey).then((count) => print("count ${logKey}: " + count.toString()));
//      index.openCursor(key: logKey).length.then((len) => print("cursor len: " + len.toString()));
//      index.openCursor(key: logKey)
      .listen(
        (cursor) {
          Qso qso = new Qso.fromMap(cursor.value);
          if (qso.logId == log.id) {
            qsos.add(qso);
          }
        },
        onDone: () {
          log.qsos = qsos; // insert qsos to log on success
          log.qsos.sort();
        });
    return tx.completed.then((_) => log);
  }

  async.Future<Qso> addQso(Qso qso) {
    _debug("HamlogStorage.addQso: ${qso}");
    if (qso.id == null) { // check for id, throws error
      return null;
    }
    idb.Transaction tx = _db.transaction([QSOS_STORAGE], 'readwrite');
    tx.objectStore(QSOS_STORAGE).add(qso.toMap(), qso.id);
    return tx.completed.then((_) => qso);
  }

  async.Future<Log> addLog(Log log) {
    _debug("HamlogStorage.addLog: ${log}");
    if (log.id == null) { // check for id, throws error
      return null;
    }
    idb.Transaction tx = _db.transaction([LOGS_STORAGE], 'readwrite');
    tx.objectStore(LOGS_STORAGE).add(log.toMap(), log.id);
    return tx.completed.then((_) => log);
  }

  async.Future<Qso> updateQso(Qso qso) {
    _debug("HamlogStorage.updateQso: ${qso}");
    if (qso.id == null) { // check for id, throws error
      return null;
    }
    idb.Transaction tx = _db.transaction([QSOS_STORAGE], 'readwrite');
    tx.objectStore(QSOS_STORAGE).put(qso.toMap(), qso.id);
    return tx.completed.then((_) => qso);
  }

  async.Future<Log> updateLog(Log log) {
    _debug("HamlogStorage.updateLog: ${log}");
    if (log.id == null) {  // check for id, throws error
      return null;
    }
    idb.Transaction tx = _db.transaction([LOGS_STORAGE], 'readwrite');
    tx.objectStore(LOGS_STORAGE).add(log.toMap(), log.id);
    return tx.completed.then((_) => log);
  }

  async.Future<Qso> deleteQso(Qso qso) {
    _debug("HamlogStorage.deleteQso: ${qso}");
    if (qso.id == null) { // check for id, throws error
      return null;
    }
    idb.Transaction tx = _db.transaction([QSOS_STORAGE], 'readwrite');
    tx.objectStore(QSOS_STORAGE).delete(qso.id);
    return tx.completed.then((_) => qso);
  }

  async.Future<Log> deleteLog(Log log) {
    _debug("HamlogStorage.deleteLog: ${log}");
    if (log.id == null) { // check for id, throws error
      return null;
    }
    idb.Transaction tx = _db.transaction([LOGS_STORAGE], 'readwrite');
    tx.objectStore(LOGS_STORAGE).delete(log.id);
    return tx.completed.then((_) => log);
  }
}


