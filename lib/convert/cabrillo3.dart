/// http://wwrof.org/cabrillo/cabrillo-specification-v3/
part of hamlog;

const _TAG_QSO = "QSO";
const _TAG_CALLSIGN = "CALLSIGN";
const _TAG_START_OF_LOG = "START-OF-LOG";
const _TAG_END_OF_LOG = "END-OF-LOG";
const _TAG_CATEGORY_ASSISTED = "CATEGORY-ASSISTED";
const _TAG_CATEGORY_BAND = "CATEGORY-BAND";
const _TAG_CATEGORY_MODE = "CATEGORY-MODE";
const _TAG_CATEGORY_OPERATOR = "CATEGORY-OPERATOR";
const _TAG_CATEGORY_STATION = "CATEGORY-STATION";
const _TAG_CATEGORY_TIME = "CATEGORY-TIME";
const _TAG_CATEGORY_TRANSMITTER = "CATEGORY-TRANSMITTER";
const _TAG_CATEGORY_OVERLAY = "CATEGORY-OVERLAY";
const _TAG_CERTIFICATE = "CERTIFICATE";
const _TAG_CLAIMED_SCORE = "CLAIMED-SCORE";
const _TAG_CLUB = "CLUB";
const _TAG_CONTEST = "CONTEST";
const _TAG_CREATED_BY = "CREATED-BY";
const _TAG_EMAIL = "EMAIL";
const _TAG_LOCATION = "LOCATION";
const _TAG_NAME = "NAME";
const _TAG_ADDRESS = "ADDRESS"; // 4 lines allowed
const _TAG_ADDRESS_CITY = "ADDRESS-CITY";
const _TAG_ADDRESS_STATE_PROVINCE = "ADDRESS-STATE-PROVINCE";
const _TAG_ADDRESS_POSTALCODE = "ADDRESS-POSTALCODE";
const _TAG_ADDRESS_COUNTRY = "ADDRESS-COUNTRY";
const _TAG_OPERATORS = "OPERATORS";
const _TAG_OFFTIME = "OFFTIME";
const _TAG_SOAPBOX = "SOAPBOX";
const _TAG_DEBUG = "DEBUG";

const __VALID_HEADER = _TAG_START_OF_LOG + ": 3.0";

const _DATE = 'date';
const _MY_CALL = "myCall";
const _EXCH_SENT = 'exchSent';
const _EXCH_RCVD = 'exchRcvd';
final _COMMON_FIELDS = const [Qso.FREQ, Qso.MODE, _DATE, Qso.TIME, _MY_CALL, _EXCH_SENT, Qso.CALL, _EXCH_RCVD];

final _EXCH_RST = const {_EXCH_SENT: Qso.RST_SENT, _EXCH_RCVD: Qso.RST_RCVD};
final _EXCH_OPT = const {_EXCH_SENT: Qso.EXCH_SENT, _EXCH_RCVD: Qso.EXCH_RCVD};

// final qsoDateTimeFormat = new DateFormat('yyyy-MM-dd HHmm');

class Cabrillo3Codec implements convert.Codec<Log, String> {
  const Cabrillo3Codec();

  Cabrillo3Decoder get decoder => new Cabrillo3Decoder();
  Cabrillo3Encoder get encoder => new Cabrillo3Encoder();

  Log decode(String input, {bool rstUsed: true, int exchCount: 1, LogType logType}) =>
    decoder.convert(input, rstUsed: rstUsed, exchCount: exchCount, logType: logType);
  String encode(Log log) => encoder.convert(log);

  bool validate(String content) => content?.startsWith(__VALID_HEADER);
}

class Cabrillo3Decoder implements convert.Converter<String, Log> {
  Map<String,String> _header = {};
  List<Qso> _qsos = [];
  var _qsoFields;

  // const Cabrillo3Decoder._();

  Log convert(String input, {bool rstUsed: true, int exchCount: 1, LogType logType}) {
    this._qsoFields = _buildQsoFieldsList(rstUsed, exchCount);

    input.split('\n').forEach((line) => _parseLine(line));

    // Qso firstQso = this._qsos.first;
    String logDate = new DateFormat('yyyy-MM-dd').format(new DateTime.fromMillisecondsSinceEpoch(_qsos.first.time)) ?? currentUTCDateYYYYMMDD();
    if (logType == null) {
      String stationType = _header[_TAG_CATEGORY_STATION];
      bool expedition = stationType?.contains("EXPEDITION") ?? false;
      logType = expedition ? LogType.DXPEDITION : LogType.CONTEST;
    }
    Log log = new Log(this._header[_TAG_CALLSIGN], this._header[_TAG_CONTEST], logDate, logType);

//    print("log: " + log.toString());
    _qsos.forEach((qso) => log.addQso(qso));
    return log;
  }

  void _parseLine(line) {
    line = line.trim();
    if (line.isEmpty) {
      return;
    }

    var splited = line.split(':'); // TODO handle more ':' at line, eg. SOAPBOX
    var tag = splited[0];
    var value = splited[1];

    if ( !tag.isEmpty && value != null) {
      if (tag == _TAG_QSO) {
        _parseQso(value.trim());
      } else {
        _header[tag] = value.trim();
        // _parseHeader(header, tag, value);
      }
    }
  }

  void _parseQso(line) {
    List<String> fields = line.split(' ');
    var map = {};
    int i = 0;
    fields
      .where((field) => field != null && !field.isEmpty && field != " ")
      .takeWhile((_) => i < this._qsoFields.length)
      .forEach((field) => map[this._qsoFields[i++]] = field);

    String qsoTime = "${map[_DATE]} ${map[Qso.TIME]}";
    map[Qso.TIME] = DateTime.parse(qsoTime).millisecondsSinceEpoch;
    // map[Qso.FREQ] = double.parse(map[Qso.FREQ]);
    var qso = new Qso.fromMap(map);
    this._qsos.add(qso);
  }

  async.Stream<Log> bind(async.Stream<String> stream) => super.bind(stream);
}

class Cabrillo3Encoder implements convert.Converter<Log, String> {
  // const Cabrillo3Encoder._();

  String convert(Log log) {
    return null; // TODO
  }

  async.Stream<String> bind(async.Stream<Log> stream) => super.bind(stream);
}

_buildQsoFieldsList(rstUsed, exchCount) {
  var fields = [];
  _COMMON_FIELDS.forEach((field) {
    if (field == _EXCH_RCVD || field == _EXCH_SENT) {
      if (rstUsed) {
        fields.add(_EXCH_RST[field]);
      }
      for (var i = 0; i < exchCount; i++) {
        fields.add(_EXCH_OPT[field]);
      }
    } else {
      fields.add(field);
    }
  });
  return fields;
}
