import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_sample/firebase_options_dev.dart' as dev;
import 'package:flutter_sample/firebase_options_local.dart' as local;
import 'package:flutter_sample/firebase_options_prod.dart' as prod;
import 'package:flutter_sample/firebase_options_stg.dart' as stg;
import 'package:flutter_sample/src/core/config/flavor_provider.dart';

/// 環境毎のFirebaseOptionsを返す
FirebaseOptions firebaseOptionsWithFlavor(Flavor env) {
  switch (env) {
    case Flavor.dev:
      return dev.DefaultFirebaseOptions.currentPlatform;
    case Flavor.local:
      return local.DefaultFirebaseOptions.currentPlatform;
    case Flavor.stg:
      return stg.DefaultFirebaseOptions.currentPlatform;
    case Flavor.prod:
      return prod.DefaultFirebaseOptions.currentPlatform;
  }
}
