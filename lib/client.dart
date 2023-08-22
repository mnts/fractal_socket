import 'dart:async';
import 'dart:convert';

import 'package:frac/index.dart';
import 'package:fractal/fractal.dart';
import 'package:fractal/types/file.dart';
import 'package:fractal_base/index.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/common.dart';
import 'package:path/path.dart';

import 'socket.dart';

class FClient extends FSocket {
  DBF get dbf => DBF.main;
  CommonDatabase get db => dbf.db;

  FClient({required super.name}) {
    connect();
  }

  StreamSubscription? _channelSub;
  StreamSubscription? _streamSub;

  connect() {
    final uri = Uri.parse(join(
      FileF.wsUrl,
      'socket',
      name,
    ));
    print('Connect: $uri');

    try {
      _channelSub?.cancel();
      //_streamSub?.cancel();

      _channel = WebSocketChannel.connect(uri)
        ..ready.then(
          (_) {
            // set connected
            connected();
            print('Connected to: $name');
            synch();
          },
          onError: (e) {
            disconnected();
            print('couldnt connect to $name');
          },
        );

      _channelSub = _channel?.stream.listen(receive);
      /*
      _streamSub = elements.stream.listen((m) {
        final request = jsonEncode(m);
        _channel?.sink.add(request);
      });
      */

      if (_channel != null) map[name] = _channel!;
    } catch (_) {
      disconnected();
    }

    Timer.periodic(
      Duration(seconds: 3),
      checkClose,
    );
  }

  @override
  sink(d) {
    if (!active.isTrue) return;
    if (d == null || (d is List && d.isEmpty)) return;

    final request = jsonEncode(d);
    _channel?.sink.add(request);
    synched();
  }

  @override
  receive(d) async {
    print(d);
    super.receive(d);
  }

  static final map = <String, WebSocketChannel>{};

  WebSocketChannel? _channel;

  int get lastSynch => dbf['lastSynch $name'] ?? 0;

  synch() async {
    final m = {
      'cmd': 'find',
      'since': lastSynch,
    };
    sink(m);
    final fractals = find(m);
    sink(fractals);
  }

  @override
  handleList(list) {
    final listR = super.handleList(list);
    synched();
    return listR;
  }

  @override
  handle(m) async => switch (m) {
        {'cmd': 'sync'} => synch(),
        {'user': [String name, int age]} => 'ok',
        _ => super.handle(m),
      };

  synched() {
    DBF.main['lastSynch $name'] = unixSeconds;
  }

  checkClose(Timer timer) {
    if (_channel == null && _channel!.closeCode != null) {
      disconnected();
      return connect();
    }

    synched();
    timer.cancel();

    map.remove(name);
  }
}
