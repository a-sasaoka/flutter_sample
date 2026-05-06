import 'package:flutter_sample/main.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';

Future<void> main() async {
  await mainCommon(Flavor.prod);
}
