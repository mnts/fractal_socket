import 'dart:async';
import 'package:fractal_base/access/abstract.dart';
import 'package:fractal_base/fractals/device.dart';
import 'package:signed_fractal/signed_fractal.dart';
import 'package:path/path.dart';
import 'api.dart';
import 'index.dart';

class ClientCtrl<T extends ClientFractal> extends ConnectionCtrl<T> {
  ClientCtrl({
    super.name = 'client',
    required super.make,
    required super.extend,
    super.attributes = const <Attr>[],
  });
}

class ClientFractal extends ConnectionFractal with SocketF, FSocketAPI {
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
  filter(f) {strea
    final contains = f.sharedWith.contains(from.name);
    if (!contains) f.sharedWith.add(from.name);
    return !contains;
  }
  */

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

  //static ClientFractal? main;

  Timer? pinger;
  //StreamSubscription? _channelSub;
  late final Uri uri;
  void establish() {
    final net = to as NetworkFractal;
    final f = from;
    String host = net.name;
    if (!host.contains('localhost') && host.split('.').length < 2) {
      host = 'api.$host';
    }

    uri = Uri.parse(join(
      FileF.wsUrl(host),
      'socket',
      f.name,
    ));
    
    connect(uri);

    Timer.periodic(
      Duration(seconds: 30),
      reconnect,
    );
  }

  reconnect(t) {
    if (!active.isTrue) connect(uri);
  }

  //int get lastSynch => dbf['lastSynch ${from.name}'] ?? 0;

  /*
  Future<bool> synched() async {
    //await DBF.main.setVar('lastSynch ${from.name}', unixSeconds);
    return true;
  }
  */
}
