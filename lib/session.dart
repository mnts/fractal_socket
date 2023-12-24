/*
import 'dart:async';

import 'package:frac/frac.dart';

import 'socket.dart';

class SessionF implements FractalSocketAbs {
  static final elements = StreamController<SessionF>.broadcast();
  static Stream<SessionF> get stream => elements.stream;

  construct() {
    elements.sink.add(this);
  }

  final sockets = <FSocket>{};

  spread(Map<String, dynamic> f) {
    for (final socket in sockets) {
      if (socket.active.isTrue) socket.sink(f);
    }
  }

  @override
  handle(FSocket socket) {}

  @override
  gets(FSocket socket) {
    if (!sockets.contains(socket)) {
      socket.session = this;
      sockets.add(socket);
    }

    /*
    if (account != null) {
      spread(account!);
    }
    */
  }
}

abstract class FractalSocketAbs {
  handle(FSocket socket);
}

abstract class FractalSessionAbs {
  handle(SessionF session);
}

*/