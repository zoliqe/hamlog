library hamlog;

// import 'dart:indexed_db' as idb;
// import 'dart:html' as html;
import 'dart:async' as async;
import 'dart:convert' as convert;
import 'package:intl/intl.dart';

export 'src/hamlog_base.dart';

// part 'storage.dart';
part 'convert/cabrillo3.dart';
part 'convert/sotacsv.dart';

const _DEBUG_ENABLED = true; // TODO provide setter?

class Qso implements Comparable<Qso> {
  static const LOG_ID = 'logId';
  static const ID = 'id';
  static const NR = 'nr';
  static const FREQ = 'freq';
  static const MODE = 'mode';
  static const TIME = 'time';
  static const CALL = 'call';
  static const RST_SENT = 'sentRst';
  static const RST_RCVD = 'rcvdRst';
  static const EXCH_SENT = 'sentExch';
  static const EXCH_RCVD = 'rcvdExch';
  static const COMMENT = 'comment';

  static const INDEX_PATH = 'logId';
  static const KEY_PATH = 'id';

  String logId; // is set externaly in Log.addQso()
  int nr;
  Mode mode;
  int time;
  int freq;
  String call;
  String sentRst;
  // String sentCode;
  String rcvdRst;
  // String rcvdCode;
  List<String> sentExch;
  List<String> rcvdExch;
  String comment;

  String get id {
    if (empty(logId) || (nr == null && time == null)) {
            throw new ArgumentError("Qso.id: logId and nr or time must be set");
    }
    return logId + '|${nr}|${time}';
  }

  bool get newQso => nr == null;

  Band get band => Band.fromFreq(freq as int);

  Qso(this.freq, this.mode, this.time, this.call) : rcvdExch = [], sentExch = [], comment = '' {
    _debug("qso init");
    sentRst = mode.defaultRst;
    rcvdRst = mode.defaultRst;
  }

  Qso.copy(Qso o) : nr = o.nr, freq = o.freq, mode = o.mode,
      time = o.time, call = o.call, comment = o.comment {
    sentRst = o.sentRst != null ? o.sentRst : mode.defaultRst;
    rcvdRst = o.rcvdRst != null ? o.rcvdRst : mode.defaultRst;
    sentExch = o.sentExch != null ? o.sentExch : [];
    rcvdExch = o.rcvdExch != null ? o.rcvdExch : [];
  }

  Qso.fromMap(Map data) {
    _debug('mapping Qso from ' + data.toString());

    logId = data[LOG_ID];
    if (data[NR] is int) {
      nr = data[NR];
    } else if (data[NR] != null) {
      nr = int.parse(data[NR]);
    }
    if (data[FREQ] is int) {
      freq = data[FREQ];
    } else if (data[FREQ] != null) {
      freq = int.parse(data[FREQ]);
    }
    mode = Mode.valueOf(data[MODE]);
    if (data[TIME] is int) {
      time = data[TIME];
    } else if (data[TIME] != null) {
      time = int.parse(data[TIME]);
    }
    call = data[CALL];
    sentRst = data[RST_SENT];
    rcvdRst = data[RST_RCVD];
    sentExch = data[EXCH_SENT];
    rcvdExch = data[EXCH_RCVD];
    comment = data[COMMENT];
  }

//  Qso(this.band, this.mode, this.time, this.call, this.sentCode, this.rcvdCode, this.comment) {
//    this(band, mode, time, call);
//  }

  // TODO nefunguje!
  Map toMap() => {
    ID: id,
    LOG_ID: logId,
    NR: nr,
    FREQ: freq,
    MODE: mode,
    TIME: time,
    CALL: call,
    RST_SENT: sentRst,
    RST_RCVD: rcvdRst,
    EXCH_SENT: sentExch,
    EXCH_RCVD: rcvdExch,
    COMMENT: comment
  };

  /// Sets [rcvdRst] and [sentRst] to default by current [mode].
  void resetRst() {
    rcvdRst = mode.defaultRst;
    sentRst = mode.defaultRst;
  }

  bool operator ==(other) {
    if (identical(other, this)) {
      return true;
    }
    return other.id == this.id;
  }

  void updateFrom(Qso qso) {
    nr = qso.nr;
    freq = qso.freq;
    mode = qso.mode;
    time = qso.time;
    call = qso.call;
    sentRst = qso.sentRst;
    sentExch = qso.sentExch;
    rcvdRst = qso.rcvdRst;
    rcvdExch = qso.rcvdExch;
    comment = qso.comment;
  }

  int compareTo(Qso other) {
    return this.id.compareTo(other.id);
  }

  String toString() => toMap().toString();
}

class Log implements Comparable<Log> {
  static const INDEX_PATH = 'name';
  static const KEY_PATH = 'id';

  // static const DEFAULT_VALUE = '#####';

  String name;
  String owner;
  String date;
  LogType type;
  List<Band> bands;
  List<Mode> modes;
  List<Qso> qsos;

  String get id {
    if (empty(owner) || empty(date) || empty(name)) {
      throw new ArgumentError("Log.id: owner, name and date must be set");
    }
    return "${owner}|${date}|${name}";
  }

  List<String> get bandValues => bands.map((band) => band.value);

  List<String> get modeValues => modes.map((mode) => mode.value);

  Log(this.owner, this.name, this.date, [LogType type = LogType.DXPEDITION,
      List<Band> bands, List<Mode> modes]) : this.type = type, this.qsos = [] {
    _debug("log init");
    this.bands = bands != null ? bands : Band.values(type);
    this.modes = modes != null ? modes : Mode.values();
  }

  Log.fromMap(id, Map data) {
    _debug('mapping Log.id=' + id);

    name = data['name'];
    owner = data['owner'];
    date = data['date'];
    type = LogType.valueOf(data['type']);
    bands.addAll(data['bands'].map((value) => Band.valueOf(value)));
    modes.addAll(data['modes'].map((value) => Mode.valueOf(value)));
  }

  // bool get defaultOwner => owner == DEFAULT_VALUE;

  // bool get defaultName => name == DEFAULT_VALUE;

  /**
   * Wether this is new empty log without basic attributes filled in.
   */
  // bool get newLog => defaultOwner || defaultName;

  /**
   * Map representation of Log doesn't contain [qsos]
   */
  Map toMap() => {'id': id, 'name': name, 'owner': owner, 'date': date, 'type': type, 'bands': bands, 'modes': modes};

  Qso createQso([double currentFreq, Mode mode, int time, String call = '']) {
    if (time = null) {
      time = currentUTC();
    }
    if (qsos.isEmpty) {
      return new Qso(currentFreq != null ? currentFreq : bands.first.minFreq,
          mode != null ? mode : modes.first, time, call);
    }
    return new Qso(currentFreq != null ? currentFreq : qsos.last.freq,
        mode != null ? mode : qsos.last.mode, time, call);
  }

  void addQso(Qso qso) {
    // _debug("addQso: " + qso.toString());
    if (empty(qso.call)) throw new ArgumentError("qso.call=${qso.call}");
    qso.nr = (!qsos.isEmpty ? qsos.last.nr : 0) + 1;
    qso.call = qso.call.toUpperCase();
    qso.comment = qso.comment?.trim();
    qso.logId = id;
    qsos.add(qso);
  }

  Qso previousQso(Qso qso) {
    var nr = qso.nr - 1;
    if (nr > 0 && nr <= qsos.length) {
      return qsoByNr(nr);
    }
    return null;
  }

  Qso nextQso(Qso qso) {
    var nr = qso.nr + 1;
    if (nr > 0 && nr <= qsos.length) {
      return qsoByNr(nr);
    }
    return null;
  }

  Qso qsoByNr(int nr) {
    return qsos.singleWhere((qso) => qso.nr == nr);
  }

  updateQso(Qso qso) {
    Qso old = qsoByNr(qso.nr);
    if (old == null) {
      print("ERROR: old qso not found, nr=${qso.nr}");
      throw new ArgumentError("updateQso: qso.nr=${qso.nr} not found");
    }
    qso.call = qso.call.toUpperCase();
    qso.comment = qso.comment.trim();
    old.updateFrom(qso);
  }

  int compareTo(Log other) {
    return this.id.compareTo(other.id);
  }

  String toString() => toMap().toString();
}

class LogType {
  static const CONTEST = const LogType._("CONTEST");
  static const DXPEDITION = const LogType._("DXPEDITION");

  static get values => [CONTEST, DXPEDITION];

  final String value;

  const LogType._(this.value);

  static LogType valueOf(String value) {
    return values.singleWhere((type) => type.value == value);
  }

  toJson() => value;
  String toString() => toJson().toString();
}

class Band {
  static const B160 = const Band._("160M", 1800, 2000);
  static const B80 = const Band._("80M", 3500, 4000);
  static const B60 = const Band._("60M", 5000, 5500);
  static const B40 = const Band._("40M", 7000, 7500);
  static const B30 = const Band._("30M", 10000, 10500);
  static const B20 = const Band._("20M", 14000, 14500);
  static const B17 = const Band._("17M", 18000, 18500);
  static const B15 = const Band._("15M", 21000, 21500);
  static const B12 = const Band._("12M", 24800, 24900);
  static const B10 = const Band._("10M", 28000, 28500);

  final String value;
  final int minFreq;
  final int maxFreq;

  const Band._(this.value, this.minFreq, this.maxFreq);

  static List<Band> values([LogType logType]) {
    if (logType == LogType.CONTEST) {
      return <Band>[B160, B80, B40, B20, B15, B10];
    }
    return <Band>[B160, B80, B60, B40, B30, B20, B17, B15, B12, B10];
  }

  static Band valueOf(String value) {
    return values().singleWhere((band) => band.value == value);
  }

  static Band fromFreq(int freq) => values()
    .singleWhere((band) => (band.minFreq <= freq && band.maxFreq >= freq));

  toJson() => value;

  String toString() => toJson().toString();
}

class Mode {
  static const CW = const Mode._("CW", "599");
  static const PHONE = const Mode._("PHONE", "59");
  static const DIGI = const Mode._("DIGI", "599");

  static List<Mode> values() => [CW, PHONE, DIGI];

  final String value;
  final String defaultRst;

  const Mode._(this.value, this.defaultRst);

  static Mode valueOf(String value) {
    return values().singleWhere((mode) => mode.value == value);
  }

  toJson() => value;
  String toString() => toJson().toString();
}


/////////////
bool empty(value) => value == null || value.isEmpty;
int currentUTC() => new DateTime.now().toUtc().millisecondsSinceEpoch;
String currentUTCDateYYYYMMDD() => new DateFormat('yyyy-MM-dd').format(new DateTime.now().toUtc());
String formatTimeToHHMM(int miliseconds) => new DateFormat('HHmm').format(new DateTime.fromMillisecondsSinceEpoch(miliseconds/*, false*/));

// String formatTimeToHHMM(int milisecondsSinceEpoch) {
//   DateTime time = new DateTime.fromMillisecondsSinceEpoch(milisecondsSinceEpoch/*, false*/);

//   String hours = time.hour.toString();
//   if (time.hour < 10) {
//     hours = "0${hours}";
//   }
//   String minutes = time.minute.toString();
//   if (time.minute < 10) {
//     minutes = "0${minutes}";
//   }
//   return "${hours}${minutes}";
// }

List<Log> logs = [];

_debug(var text) {
  if (_DEBUG_ENABLED) {
    print(text);
  }
}

void loadLogs(HamlogStorage storage) {
  logs.clear();
  storage.loadLogs().then((result) => logs = result);
}

/*Log createLog(LogType type) {
  return new Log(Log.DEFAULT_VALUE, Log.DEFAULT_VALUE, utils.currentUTCDateYYYYMMDD(), type, Band.values, Mode.values);
}*/
