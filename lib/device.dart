/*
import 'dart:convert';
import 'package:parchment/parchment.dart';
import 'package:signed_fractal/signed_fractal.dart';

enum Audience {
  all,
  authenticated,
  notAuthenticated,
}

class DeviceCtrl<T extends DeviceFractal> extends NodeCtrl<T> {
  DeviceCtrl({
    super.name = 'device',
    required super.make,
    required super.extend,
    super.attributes = const [
      Attr(
        'audience',
        int,
      ),
    ],
  });

  final icon = IconF(0xe1f2);
}

class DeviceFractal extends NodeFractal implements Rewritable {
  static final controller = DeviceCtrl(
    extend: NodeFractal.controller,
    make: (d) => switch (d) {
      MP() => DeviceFractal.fromMap(d),
      String s => DeviceFractal(name: s),
      _ => throw (),
    },
  );

  @override
  DeviceCtrl get ctrl => controller;

  var audience = Audience.all;

  ParchmentDocument? document;

  DeviceFractal({
    this.audience = Audience.all,
    super.extend,
    required super.name,
    super.to,
    //required this.icon,
  }) : super() {
    //this.title.value = (title.isEmpty) ? name.split('/')[0] : title;
  }

  @override
  get hashData => [...super.hashData, audience.index];

  DeviceFractal.fromMap(MP d)
      : audience = Audience.values[d['audience'] ?? 0],
        /*(
          publicKey: d['public_key'],
          privateKey: d['private_key'],
        )*/

        super.fromMap(d);

  @override
  consume(EventFractal event) {
    //document.insert(0, event.content);
    return super.consume(event);
  }

  final doc = Writable();

  @override
  onWrite(f) {
    switch (f.attr) {
      case 'doc':
        document = ParchmentDocument.fromJson(
          jsonDecode(f.content),
        );
        notifyListeners();
    }
    super.onWrite(f);
  }

  @override
  MP toMap() => {
        ...super.toMap(),
        'audience': audience.index,
      };
}

*/