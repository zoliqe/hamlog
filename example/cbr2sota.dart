// Copyright (c) 2016, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:hamlog/hamlog.dart';

void main(List<String> args) {
  String cbrName = args.isEmpty ? null : args[0];
  if (cbrName == null || cbrName.isEmpty) {
    print('Cabrillo3 to SOTA CSV converter; Usage: cbr2sota <cbr_filename>');
    exit(0);
  }
  String csvName = cbrName.substring(0, cbrName.lastIndexOf('.')) + '.csv';
  print('cbr: ${cbrName}');
  print('csv: ${csvName}');

  String cabrillo = new File(cbrName)
    .readAsStringSync();
  Log log = const Cabrillo3Codec().decode(cabrillo, logType: LogType.DXPEDITION, exchCount: 0);
  print('call: ${log.owner}');
  print('sota: ${log.name}');
  print('qsos: ${log.qsos.length}');

  String csv = const SotaCsvCodec().encode(log);
  new File(csvName)
    ..createSync()
    ..writeAsStringSync(csv);
}
