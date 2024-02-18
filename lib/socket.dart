import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:signed_fractal/signed_fractal.dart';
import 'session.dart';

/*
mixin FSocket on FSocketMix {
  //late final String name;
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

  /*
  FSocket({
    required this.name,
  }) {
    FSocketMix.sockets[name] = this;
  }
  */
}

*/

mixin FSocketMix {
  /*
  SessionF? _session;

  set session(SessionF? session) {
    if (session == null) {
      _session = null;
      return;
    }

    _session = session;
  }
  */

  //SessionF? get session => _session;
  final elements = StreamController.broadcast();
  //Stream<dynamic> get stream => elements.stream;

  distribute(EventFractal f) {
    if (f.syncAt == 0 && active.isTrue && f.createdAt != 2) {
      sink(f);
      f.setSynched();
    }
  }

  sink(d) {
    print(d);
    switch (d) {
      case EventFractal evf:
        if (evf.createdAt != 3) {
          elements.sink.add(
            [evf.toMap()],
          );
        }
      case Iterable list:
        final forSink = [];
        for (final f in list) {
          switch (f) {
            case EventFractal evf:
              if (evf.createdAt != 3) {
                forSink.add(evf.hash);
              }
            case MP m:
              forSink.add(m);
          }
        }
        if (forSink.isNotEmpty) elements.sink.add(forSink);
      case MP m:
        elements.sink.add(m);
    }
  }

  final ht = 34355;

  readPath(List<int> b) => utf8.decode(b.sublist(2, b[1] + 2));

  respond() {}

  static List<EventsCtrl> get ctrls =>
      FractalCtrl.map.values.whereType<EventsCtrl>().toList();

  bool filter(EventFractal f) {
    return true;
  }

  /*>
  //final syncTime = StoredFrac('$name', 0);
  List<MP> find(MP m) {
    /*if (m case {'type': String t}) {
      return switch (FractalCtrl.map[t]) {
        (EventsCtrl ctrl) => toMaps(ctrl.find(m)),
        _ => throw Exception('wrong type')
      };
    } else */

    final rows = EventFractal.controller.select(
      where: m,
      includeSubTypes: true,
    );

    connect().then((t) {
      
    });
    return rows;
    /*
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
    */
  }

  Iterable<String> search(MP m) {
    final ctrl = FractalCtrl.map[m['type']];
    if (ctrl == null) return [];
    return ctrl.select(
      fields: ['hash'],
      where: m['where'],
    ).map((f) => f['hash']);
  }

  static List<MP> toMaps(List<Fractal> fractals) =>
      fractals.map((f) => f.toMap()).toList();
  */

  void handle(MP m) async {
    List h = switch (m['hash']) {
      List h => h,
      String h => [h],
      _ => [],
    };
    if (h.isEmpty) return;

    switch (m) {
      case ({'cmd': String cmd}):
        switch (cmd) {
          //'find' => find(m['filter']),
          //'search' => search(m),
          case 'pick':
            for (final hash in h) {
              CatalogFractal.pick(hash).then(sink);
            }
          case 'subscribe':
            for (final hash in h) {
              _subscribe(hash);
            }
          case _:
            throw Exception('wrong cmd');
        }
      case _:
        Exception('wrong item');
    }
  }

  void _subscribe(String hash) async {
    final f = await CatalogFractal.pick(hash, pick);
    switch (f) {
      case CatalogFractal catalog:
        final list = catalog.listen(sink).whereType<EventFractal>();
        if (list.isNotEmpty) sink(list);
    }
  }

  final picked = <String>[];
  final picking = <String>[];

  static final pickTimer = TimedF();
  void pick(String h) async {
    if (h.isEmpty) return;

    picking.add(h);
    pickTimer.hold(() async {
      sink({
        'cmd': 'pick',
        'hash': [...picking],
      });
      picking.clear();
    }, 90);
  }

  final subscribing = <String>[];
  void subscribe(String h) {
    if (subscribing.contains(h)) return;

    sink({
      'cmd': 'subscribe',
      'hash': h,
    });
    subscribing.add(h);
  }

  void handleList(List list) async {
    print(list);
    for (final d in list) {
      switch (d) {
        case Map m:
          final String hash = m['hash'] ?? '';
          if (hash.isEmpty || received.contains(hash)) continue;

          received.add(hash);
          prepare(m as MP);
        case String s:
          CatalogFractal.pick(s, pick);
        /*
          if (!EventFractal.map.containsKey(s)) {
            missing.add(s);
          }
          */
      }
    }
    /*
    if (missing.isNotEmpty) {
      final found = <EventFractal>[];
      for (var hash in missing) {
        final f = EventFractal.map[hash];
        if (f != null) {
          found.add(f);
        }
      }
      sink(found.map(
        (f) => f.toMap(),
      ));
    }
    */
  }

  Future<EventFractal?> prepare(MP item) async {
    final hash = item['hash'];
    item.remove('id');
    //item.remove('hash');
    item.remove('sync_at');
    final map = EventFractal.map;
    if (hash == null || map.containsKey(hash)) return null;
    return Rewritable.ext(item, () async {
      final ctrl = FractalCtrl.map[item['type']];
      if (ctrl is! EventsCtrl) return null;
      final fractal = await ctrl.make(item);
      //if(fractal is FilterFractal)
      return fractal;
    });
    // fractal.hash = '';
  }

  final received = <String>[];

  /*

  */

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
import 'package:path/path.dart';

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
        handle(m);
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
    print('disconnected');
    active.value = false;
    //sockets.remove(socket.name);
    //Communication.catalog.unListen(distributor);
  }

  connected() {
    print('connected');
    active.value = true;
    //sockets.remove(socket.name);
    //Communication.catalog.unListen(distributor);
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
