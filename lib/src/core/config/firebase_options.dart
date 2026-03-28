import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_sample/firebase_options_dev.dart' as dev;
import 'package:flutter_sample/firebase_options_local.dart' as local;
import 'package:flutter_sample/firebase_options_prod.dart' as prod;
import 'package:flutter_sample/firebase_options_stg.dart' as stg;
import 'package:flutter_sample/src/core/config/flavor_provider.dart';

/// 環境毎のFirebaseOptionsを返す
FirebaseOptions firebaseOptionsWithFlavor(Flavor env) => switch (env) {
  Flavor.dev => dev.DefaultFirebaseOptions.currentPlatform,
  Flavor.local => local.DefaultFirebaseOptions.currentPlatform,
  Flavor.stg => stg.DefaultFirebaseOptions.currentPlatform,
  Flavor.prod => prod.DefaultFirebaseOptions.currentPlatform,
};
