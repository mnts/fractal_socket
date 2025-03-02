import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:frac/index.dart';
import 'package:fractal/utils/random.dart';
import 'package:signed_fractal/signed_fractal.dart';
import 'socket.dart';

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
typedef FComp = Completer<MP>;

mixin FSocketAPI on SocketF implements SinkF {
  bool pass(EventFractal f) {
    return f.kind != FKind.system;
  }

  final missTimer = TimedF();
  final missing = <String>[];
  void miss(String h) async {
    if (h.isEmpty || picking.contains(h) || picks.contains(h)) return;

    missing.add(h);
    pickTimer.hold(() async {
      sink({'cmd': 'miss', 'list': missing});
    });
  }

  distribute(EventFractal f) {
    if (f.syncAt == 1 &&
        active.isTrue &&
        ![
          FKind.system,
        ].contains(f.kind)) {
      sink(f);
      f.setSynched();
    }
  }

  toSynch() async {
    if (!active.isTrue) return;
    final c = await CatalogFractal.controller.put({
      'kind': FKind.system.index,
      'filter': {
        'sync_at': 1,
        'kind': {
          'nin': [FKind.system.index],
        },
      },
      'source': EventFractal.controller,
    });
    c.doHash();
    await c.refresh();
    if (!active.isTrue) return;

    sink([
      ...c.list.map(
        (f) => f.toMap(),
      )
    ]);

    for (var f in c.list) {
      f.setSynched();
    }
  }

  onSynch() {
    EventFractal.map.listen(distribute);
  }

  offSynch() {
    EventFractal.map.unListen(distribute);
  }

  @override
  sink(d) async {
    print('sink($d)');
    switch (d) {
      case EventFractal evf:
        if (pass(evf)) {
          final m = evf.toMap();
          m.removeWhere((k, v) => v == null || v == 0 || v == '');
          put([m]);
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
        if (forSink.isNotEmpty) put(forSink);
      case MP m:
        put(m);
    }
    return true;
  }

  final res = <String, FComp>{};
  @override
  rx(m) async {
    final rx = m['rx'] = getRandomString(5);
    final re = res[rx] = FComp();
    sink(m);
    return re.future;
  }

  final ht = 34355;

  readPath(List<int> b) => utf8.decode(b.sublist(2, b[1] + 2));

  respond() {}

  static List<EventsCtrl> get ctrls =>
      FractalCtrl.map.values.whereType<EventsCtrl>().toList();

  void handle(MP m) async {
    if (m['cmd'] case String cmdName) {
      final cmd = FractalAPI.cmds[cmdName];
      if (cmd != null) {
        final r = await cmd(m, this);
        if (r is Map) {
          if (r['cmd'] is String) {
            sink(r);
          } else if (m['rx'] case String rx) {
            r['re'] = rx;
            sink(r);
          }
        }
        print('re sink');
      } else {
        print('wrong cmd: $cmd');
      }
    } else if (m['re'] case String re) {
      if (res[re] case FComp comp) comp.complete(m);
      res.remove(re);
    }
  }

  static final maps = <String, Frac<Map<String, MP>>>{
    'notification': Frac<Map<String, MP>>({}),
  };

  void handleList(List list) async {
    for (final d in list) {
      switch (d) {
        case Map m:
          /*
          final String hash = m['hash'] ?? '';
          if (hash.isEmpty || received.contains(hash)) continue;

          received.add(hash);
          */
          if (m['type'] case String type) {
            final ctrl = FractalCtrl.map[type];
            if (ctrl != null) {
              try {
                prepare({...m});
              } catch (e) {}
            } else {
              (maps[type] ??= Frac({}))
                ..value[m['hash']] = {...m}
                ..notifyListeners();
            }
          }
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

  final picks = <String>[];
  final picking = <String>[];

  final pickTimer = TimedF();

  @override
  void pick(String h) async {
    print('pick($h)');
    if (h.isEmpty || picking.contains(h) || picks.contains(h)) return;

    picking.add(h);
    pickTimer.hold(() async {
      sink({
        'cmd': 'pick',
        'hash': [...picking],
      });
      picks.addAll(picking);
      picking.clear();
    }, 90);
  }

  void prepare(MP item) async {
    item.remove('id');
    //item.remove('hash');
    item['sync_at'] = unixSeconds;

    final ctrl = FractalCtrl.map[item['type']];
    if (ctrl is! EventsCtrl) {
      throw Exception('Controller $ctrl is not supported');
    }

    ctrl
        .put(MakeF(item,
            by: switch (this) {
              Fractal fb => fb,
              _ => null,
            }))
        .then((f) {
      f.syncAt = unixSeconds;

      f.synch();

      picking.remove(item['hash']);
    }, onError: (e) {
      print('client failed to prepare: $e');
    });
    //return f;
    /*

    final map = EventFractal.map;
    if (hash == null || map.containsKey(hash)) return null;
    return Rewritable.ext(item, () async {
      final ctrl = FractalCtrl.map[item['type']];
      if (ctrl is! EventsCtrl) {
        throw Exception('Controller $ctrl is not supported');
      }
      final fractal = await ctrl.make(item);
      //if(fractal is FilterFractal)
      return fractal;
    });
    // fractal.hash = '';
    */
  }

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
  final timerPing = TimedF();
  @override
  receive(d) async {
    print('receive: $d');
    try {
      if (d case String s) {
        if (s.startsWith('{') && s.endsWith('}')) {
          final m = jsonDecode(s);
          handle(m);
        } else if (s.startsWith('[') && s.endsWith(']')) {
          //print(d);
          final m = jsonDecode(s);
          handleList(m);
        } else if (s.startsWith('ping')) {
          if (!active.isTrue) connected();
          timerPing.hold(() {
            //disconnected();
          }, 16000);
        }
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

  @override
  connected() {
    super.connected();
    if (channel != null) {
      onSynch();
      toSynch();
    }
  }

  @override
  disconnected() {
    super.disconnected();

    if (channel != null) {
      offSynch();
    }
  }

  void unSubscribeAll() {
    NodeFractal.controller.controllers.map((c) {
      if (c case FlowF sink) {
        sink.list.where((c) {
          c.unLook(this);
          //if (c.noInterest) EventFractal.map.remove(c.hash);
          //c.dispose();
          return c.noInterest;
        });
      }
    });
  }

  //final received = <String>[];

  /*
  final subscribing = <String>[];
  void subscribe(String h) {
    if (subscribing.contains(h)) return;

    sink({
      'cmd': 'subscribe',
      'hash': h,
    });
    subscribing.add(h);
  }
  */

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
  //final elements = StreamController.broadcast();
  //Stream<dynamic> get stream => elements.stream;

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
establish
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

  //List<CatalogFractal> subscribed = [];

  /*


  ready(FServer server) {
    sink(server);
    for (final cb in _onConnectedCBs) {
      cb(this);
    }
  }
  */
}
