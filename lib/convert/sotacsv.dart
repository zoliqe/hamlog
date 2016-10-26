/*
 * SOTA CSV V2 format
 * http://www.sotadata.org.uk/ActivatorCSVInfo.htm
 */
part of hamlog;

// <V2> <My Callsign><My Summit> <Date> <Time> <Band> <Mode> <His Callsign><His Summit> <Notes or Comments>
// V2,G3WGV,G/LD-008 24/04/03,1227,144MHz,FM,GW4GTE,,Dave
const version = 'V2';
final __FIELDS = const [Qso.FREQ, Qso.MODE, _DATE, Qso.TIME, _MY_CALL, _EXCH_SENT, Qso.CALL, _EXCH_RCVD];
final qsoDateFormat = new DateFormat('dd/MM/yyyy');
final qsoTimeFormat = new DateFormat('HHmm');
final bandMap = const {Band.B160: "1.8MHz", Band.B80: "3.5MHz", Band.B40: "7.0MHz",
  Band.B30: "10.1MHz", Band.B20: "14.0MHz", Band.B17: "18.0MHz", Band.B15: "21.0MHz",
  Band.B12: "24.9MHz", Band.B10: "28.0MHz"};

class SotaCsvCodec implements convert.Codec<Log, String> {
  const SotaCsvCodec();

  SotaCsvDecoder get decoder => new SotaCsvDecoder();
  SotaCsvEncoder get encoder => new SotaCsvEncoder();

  Log decode(String input, {bool rstUsed: true, int exchCount: 1, LogType logType: LogType.CONTEST}) =>
    decoder.convert(input, rstUsed: rstUsed, exchCount: exchCount, logType: logType);
  String encode(Log log) => encoder.convert(log);
}

class SotaCsvDecoder implements convert.Converter<String, Log> {
  Log convert(String input, {bool rstUsed: true, int exchCount: 1, LogType logType: LogType.DXPEDITION}) {
    // TODO implement
    return null;
  }

  async.Stream<Log> bind(async.Stream<String> stream) => super.bind(stream);
}

class SotaCsvEncoder implements convert.Converter<Log, String> {
  // const Cabrillo3Encoder._();

  String convert(Log log) {
    String result = "";
    log.qsos.forEach((Qso qso) {
      var date = qsoDateFormat.format(new DateTime.fromMillisecondsSinceEpoch(qso.time));
      var time = qsoTimeFormat.format(new DateTime.fromMillisecondsSinceEpoch(qso.time));
      result = result + "${version},${log.owner},${log.name},${date},${time},${bandMap[qso.band]},${qso.mode},${qso.call}\n";
    });
    return result; // TODO
  }

  async.Stream<String> bind(async.Stream<Log> stream) => super.bind(stream);
}
