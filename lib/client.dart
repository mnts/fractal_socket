import 'dart:async';
import 'dart:convert';
import 'package:fractal_base/fractals/device.dart';
import 'package:signed_fractal/models/index.dart';
import 'package:signed_fractal/signed_fractal.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sqlite3/common.dart';
import 'package:path/path.dart';

import 'socket.dart';

class ClientCtrl<T extends ClientFractal> extends ConnectionCtrl<T> {
  ClientCtrl({
    super.name = 'client',
    required super.make,
    required super.extend,
    super.attributes = const <Attr>[],
  });
}

class ClientFractal extends ConnectionFractal with FSocketMix {
  DBF get dbf => DBF.main;
  CommonDatabase get db => dbf.db;

  //static String get sid => DBF.main['socket'] ??= getRandomString(8);

  ClientFractal({
    required NetworkFractal super.to,
    required super.from,
  }) {
    //connect();
  }

  //late final String name;
  /*
  Function(
    Map<String, dynamic>, [
    List<String>,
  ])? spread;


  @override
  filter(f) {
    final contains = f.sharedWith.contains(from.name);
    if (!contains) f.sharedWith.add(from.name);
    return !contains;
  }
  */

  @override
  disconnected() {
    EventFractal.map.unListen(distribute);

    _channel?.sink.close();
    _channel = null;

    super.disconnected();
  }

  @override
  connected() {
    EventFractal.map.listen(distribute);
    super.connected();
  }

  @override
  prepare(MP item) async {
    final f = await super.prepare(item);
    if (f == null) return null;
    if (from case DeviceFractal device) {
      f.sharedWith.add(device);
    }
    f.syncAt = unixSeconds;

    f.synch();

    return f;
  }

  /*
  void spread(EventFractal event) {
    //return;
    //if (event is UserFractal) return;
    if (!event.sharable || event.state == StateF.removed) return;
    if (!active.isTrue) return;
    if (event.sharedWith.contains(from.name)) return;
    // event.ownerC.future.then((_) {
    final m = event.toMap();
    m.remove('id');
    sink([m]);
    //});
    return;
  }
  */

  /*
  FSocket({
    required this.name,
  }) {
    FSocketMix.sockets[name] = this;
  }
  */
  static final Map<DeviceFractal, ClientFractal> sockets = {};
  List<ClientFractal> get otherSockets =>
      sockets.values.where((s) => s != this).toList();

  static final _onConnectedCBs = <Function(ClientFractal socket)>[];
  static onConnected(Function(ClientFractal socket) cb) {
    _onConnectedCBs.add(cb);
  }

  static ClientFractal? main;

  StreamSubscription? _channelSub;
  StreamSubscription? _streamSub;

  establish() async {
    active.listen((a) {
      if (a) toSynch();
    });

    await connect();
    Timer.periodic(
      Duration(seconds: 3),
      (t) => checkIfClosed(t),
    );
  }

  Future<bool> connect() async {
    final net = to as NetworkFractal;
    final uri = Uri.parse(join(
      FileF.wsUrl(net.name),
      'socket',
      from.name,
    ));

    print('Connect: $uri');

    try {
      _channelSub?.cancel();
      _streamSub?.cancel();

      _channel = WebSocketChannel.connect(uri);
      _channelSub = _channel?.stream.listen(receive);
      await _channel!.ready;
      print('Connected with: ${from.name}');
      connected();

      _streamSub = elements.stream.listen((m) {
        final request = jsonEncode(m);
        _channel?.sink.add(request);
      });

      return true;

      //if (_channel != null) map[from.name] = _channel!;
    } catch (_) {
      _channel = null;
      _channelSub = null;
      print('cant connect to $uri');
    }
    return false;
  }

  @override
  sink(d) {
    if (!active.isTrue) return;
    super.sink(d);
    synched();
  }

  WebSocketChannel? _channel;

  int get lastSynch => dbf['lastSynch ${from.name}'] ?? 0;

  toSynch() {
    if (!active.isTrue) return;
    final c = CatalogFractal(
      filter: {
        'event': {
          'sync_at': 0,
        },
      },
      source: EventFractal.controller,
    );
    c.createdAt = 1;
    c.doHash();

    sink([
      ...c.list.map(
        (f) => f.toMap(),
      )
    ]);

    for (var f in c.list) {
      f.setSynched();
    }
  }

  @override
  handleList(list) {
    final listR = super.handleList(list);
    synched();
    return listR;
  }

  @override
  handle(m) async => switch (m) {
        //{'cmd': 'sync'} => synch(),
        {'user': [String name, int age]} => 'ok',
        _ => super.handle(m),
      };

  synched() {
    DBF.main['lastSynch ${from.name}'] = unixSeconds;
  }

  checkIfClosed(Timer timer) {
    if (_channel == null || _channel!.closeCode != null) {
      disconnected();
      return connect();
    }

    //

    //map.remove(from.name);
  }
}
