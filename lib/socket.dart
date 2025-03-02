import 'dart:convert';
import 'package:frac/index.dart';
import 'package:fractal_socket/client.dart';
import 'package:signed_fractal/models/interaction.dart';
import 'package:signed_fractal/signed_fractal.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

mixin SocketF {
  static Future init() async {
    await ClientFractal.controller.init();
  }

  final delayed = <String>[];
  put(m) {
    print('out: $m');
    try {
      final msg = jsonEncode(m);
      out(msg);
      if (active.isTrue) {
      } else {
        delayed.add(msg);
        return true;
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  late Function(Object) out;
  WebSocketChannel? channel;

  connect(Uri uri) {
    print('Connect: $uri');

    //try {
    //_streamSub.cancel();

    channel?.sink.close();
    channel = WebSocketChannel.connect(uri)
      //..ready.whenComplete(connected)
      ..stream.listen(receive);

    out = (m) {
      channel!.sink.add(m);
    };

    //if (_channel != null) map[from.name] = _channel!;
    /*
    } catch (_) {
      _channel = null;
      _channelSub = null;
      print('cant connect to $uri');
    }
    */
  }

  receive(d) async {
    print('receive: $d');
  }

  final active = Frac<bool>(false);

  /*
  bool checkState() {
    if (channel != null && channel!.closeCode == null) {
      connected();
      return true;
    } else {
      disconnected();
      return false;
    }
  }
  */

  disconnected() {
    print('disconnected');
    active.value = false;
    //sockets.remove(socket.name);
    //Communication.catalog.unListen(distributor);
  }

  connected() {
    print('connected');
    active.value = true;
    delayed
      ..forEach(out)
      ..clear();
    //sockets.remove(socket.name);
    //Communication.catalog.unListen(distributor);
  }
}
