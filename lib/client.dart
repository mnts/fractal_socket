import 'dart:async';
import 'dart:convert';
import 'package:fractal_base/access/abstract.dart';
import 'package:fractal_base/fractals/device.dart';
import 'package:signed_fractal/models/index.dart';
import 'package:signed_fractal/models/network.dart';
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

class ClientFractal extends ConnectionFractal with SinkF, FSocketMix {
  DBF get dbf => DBF.main;
  FDBA get db => dbf.db;

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
    _channel?.sink.close();
    _channel = null;

    super.disconnected();
  }

  @override
  connected() {
    super.connected();
  }

  onSynch() {
    EventFractal.map.listen(distribute);
  }

  offSynch() {
    EventFractal.map.unListen(distribute);
  }

  @override
  prepare(MP item) async {
    if (from case DeviceFractal device) {
      item['shared_with'] = [device];
    }

    final f = await super.prepare(item);
    if (f == null) return null;
    f.syncAt = unixSeconds;

    f.synch();

    return f;
  }

  @override
  bool pass(f) {
    if (!super.pass(f)) return false;
    final isShared = f.sharedWith.contains(from);
    if (!isShared) {
      f.sharedWith.add(from as DeviceFractal);
    }
    return !isShared;
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

  Future<bool> establish() async {
    active.listen((a) {
      if (a) toSynch();
    });

    Timer.periodic(
      Duration(seconds: 3),
      (t) => checkIfClosed(t),
    );
    await connect();
    return true;
  }

  Future<bool> connect() async {
    final net = (await to?.future) as NetworkFractal;
    final f = from;
    final uri = Uri.parse(join(
      FileF.wsUrl(net.name),
      'socket',
      f.name,
    ));

    print('Connect: $uri');

    //try {
    _channelSub?.cancel();
    _streamSub?.cancel();

    _channel = WebSocketChannel.connect(uri);
    _channelSub = _channel?.stream.listen(receive);
    _channel!.ready.then((d) async {
      print('Connected with: ${f.name}');
      onSynch();
      connected();

      _streamSub = elements.stream.listen((m) {
        final request = jsonEncode(m);
        _channel?.sink.add(request);
      });
    });

    return true;

    //if (_channel != null) map[from.name] = _channel!;
    /*
    } catch (_) {
      _channel = null;
      _channelSub = null;
      print('cant connect to $uri');
    }
    */
  }

  @override
  sink(d) {
    if (!active.isTrue) return;
    super.sink(d);
    synched();
  }

  WebSocketChannel? _channel;

  //int get lastSynch => dbf['lastSynch ${from.name}'] ?? 0;

  toSynch() {
    if (!active.isTrue) return;
    final c = CatalogFractal(
      filter: {
        'sync_at': 0,
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

  Future<bool> synched() async {
    await DBF.main.setVar('lastSynch ${from.name}', unixSeconds);
    return true;
  }

  void checkIfClosed(Timer timer) {
    if (_channel == null || _channel!.closeCode != null) {
      disconnected();
      offSynch();
      connect();
    }

    //

    //map.remove(from.name);
  }
}
