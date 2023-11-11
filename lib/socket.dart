import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:frac/frac.dart';
import 'package:fractal/lib.dart';
import 'package:signed_fractal/signed_fractal.dart';
import 'session.dart';

class FSocket with FSocketMix {
  final String name;
  /*
  Function(
    Map<String, dynamic>, [
    List<String>,
  ])? spread;
*/

  @override
  filter(f) {
    final contains = f.sharedWith.contains(name);
    if (!contains) f.sharedWith.add(name);
    return !contains;
  }

  @override
  disconnected() {
    EventFractal.map.unListen(spread);
    super.disconnected();
  }

  @override
  connected() {
    EventFractal.map.listen(spread);
    super.connected();
  }

  @override
  prepare(MP item) async {
    final f = await super.prepare(item);
    if (f == null) return null;
    f.sharedWith.add(name);

    f.synch();

    return f;
  }

  void spread(EventFractal event) {
    if (!event.sharable || event.state == StateF.removed) return;
    if (!active.isTrue) return;
    if (event.sharedWith.contains(name)) return;
    print(active);
    // event.ownerC.future.then((_) {
    final m = event.toMap();
    m.remove('id');
    sink([m]);
    //});
    return;
  }

  FSocket({
    required this.name,
  }) {
    FSocketMix.sockets[name] = this;
  }
}

mixin FSocketMix {
  SessionF? _session;

  set session(SessionF? session) {
    if (session == null) {
      _session = null;
      return;
    }

    _session = session;
  }

  SessionF? get session => _session;
  final elements = StreamController.broadcast();
  //Stream<dynamic> get stream => elements.stream;
  sink(m) {
    if (m == null || (m is List && m.isEmpty)) return;

    elements.sink.add(m);
  }

  final ht = 34355;

  readPath(List<int> b) => utf8.decode(b.sublist(2, b[1] + 2));

  respond() {}

  static List<EventsCtrl> get ctrls =>
      FractalCtrl.map.values.whereType<EventsCtrl>().toList();

  bool filter(EventFractal f) {
    return true;
  }

  //final syncTime = StoredFrac('$name', 0);
  List<MP> find(MP m) {
    /*if (m case {'type': String t}) {
      return switch (FractalCtrl.map[t]) {
        (EventsCtrl ctrl) => toMaps(ctrl.find(m)),
        _ => throw Exception('wrong type')
      };
    } else */
    if (m case {'since': int time}) {
      final list = <EventFractal>[];
      EventFractal.map.list
          .where((f) => f.syncAt > time)
          .where(filter)
          .forEach(list.add);

      final listMap = toMaps(list);
      return listMap;
    }
    return [];
  }

  static List<MP> toMaps(List<Fractal> fractals) =>
      fractals.map((f) => f.toMap()).toList();

  FutureOr<Object?> handle(MP m) async => switch (m) {
        ({'cmd': String cmd}) => switch (cmd) {
            'find' => find(m),
            _ => throw Exception('wrong cmd')
          },
        _ => throw Exception('wrong item'),
      };

  void handleList(List list) async {
    for (final d in list) {
      final String hash = d['hash'] ?? '';
      if (hash.isEmpty || received.contains(hash)) continue;

      received.add(hash);
      prepare(d as MP);
    }
  }

  Future<EventFractal?> prepare(MP item) async {
    final hash = item['hash'];
    item.remove('id');
    item.remove('hash');
    item.remove('sync_at');
    final map = EventFractal.map;
    if (hash == null || map.containsKey(hash)) return null;
    return Rewritable.ext(item, () async {
      final ctrl = FractalCtrl.map[item['type']];
      if (ctrl is! EventsCtrl) return null;
      ctrl as EventsCtrl;
      return (await ctrl.make(item));
    });
    // fractal.hash = '';
  }

  final received = <String>[];

  static final Map<String, FSocket> sockets = {};
  List<FSocket> get otherSockets =>
      sockets.values.where((s) => s != this).toList();

  static initiate() {
    /*
    for (final ctrl in ctrls) {
      ctrl.listen(
        (f) => spread(
          [f.toMap()],
        ),
      );
    }
    */
  }

  /*
  static yspread(msg) {
    final msgs = (msg is List) ? msg : [msg];

    final last = [];

    for (final m in msgs) {
      if (m is! Map) {
        _spread(m);
        continue;
      }

      String hash = m['file'] ?? '';
      final f = FileF(hash);
      if (hash.isNotEmpty && !f.uploaded.isCompleted) {
        f.uploaded.future.then((_) {
          _spread([m]);
        });
        continue;
      }

      if (m['hash'].isNotEmpty) {
        last.add(m);
      }
    }

    if (last.isNotEmpty) _spread(last);
  }

  // filter out thosae items that was already shared by socket
  static _spread(msg) {
    for (final s in sockets.values) {
      final list = (msg is List ? msg : [msg]).toList();
      s.sink(list);
    }
  }

  
  bool filterReceived(m) {
    if (m is! Map) return true;
    final hash = m['hash'] ?? '';
    if (hash == '') return true;
    if (received.contains(hash)) return false;
    received.add(m['hash']);
    return true;
  }
  */

  receive(d) async {
    try {
      if (d is String && d.startsWith('{') && d.endsWith('}')) {
        final m = jsonDecode(d);
        final r = await handle(m);
        if (r != null) {
          sink(r);
        }
        return;
      } else if (d is String && d.startsWith('[') && d.endsWith(']')) {
        //print(d);
        final m = jsonDecode(d);
        handleList(m);
        return;
      }
      final b = d as Uint8List;

      final v = ByteData.view(b.buffer, 0, 2);
      final type = v.getUint16(0);
    } catch (e) {
      print(e);
    }
    return null;
  }

  final active = Frac<bool>(false);
  disconnected() {
    active.value = false;
    //sockets.remove(socket.name);
    //Communication.catalog.unListen(distributor);
  }

  connected() {
    active.value = true;
    //sockets.remove(socket.name);
    //Communication.catalog.unListen(distributor);
  }

  static final _onConnectedCBs = <Function(FSocket socket)>[];
  static onConnected(Function(FSocket socket) cb) {
    _onConnectedCBs.add(cb);
  }

  /*
  ready(FServer server) {
    sink(server);
    for (final cb in _onConnectedCBs) {
      cb(this);
    }
  }
  */
}
