// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_env.dart';

// **************************************************************************
// EnviedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// generated_from: .env.local
final class _AppEnv {
  static const List<int> _enviedkeybaseUrl = <int>[
    749481593,
    2271915355,
    2763391630,
    1044777732,
    4273526001,
    428074164,
    2249492511,
    399564095,
    2334813742,
    1346746574,
    2608741818,
    3734758991,
    789644615,
    3164771337,
    2025629554,
    3508777850,
    1922111601,
    2067506813,
    1673102460,
    4207709607,
    125065729,
    1673716788,
    1829421390,
    544648426,
    328563044,
    4050066686,
    4200132899,
    3652881370,
    4025284673,
    3752285143,
    2950037325,
    4251831824,
    3288490230,
    2209113333,
    3919885994,
    507189358,
  ];

  static const List<int> _envieddatabaseUrl = <int>[
    749481489,
    2271915311,
    2763391738,
    1044777844,
    4273525890,
    428074126,
    2249492528,
    399564048,
    2334813764,
    1346746557,
    2608741845,
    3734758945,
    789644599,
    3164771429,
    2025629459,
    3508777753,
    1922111508,
    2067506709,
    1673102355,
    4207709643,
    125065829,
    1673716817,
    1829421372,
    544648388,
    328562960,
    4050066567,
    4200132947,
    3652881331,
    4025284642,
    3752285112,
    2950037289,
    4251831925,
    3288490200,
    2209113238,
    3919886021,
    507189251,
  ];

  static final String baseUrl = String.fromCharCodes(
    List<int>.generate(
      _envieddatabaseUrl.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddatabaseUrl[i] ^ _enviedkeybaseUrl[i]),
  );

  static final int _enviedkeyconnectTimeout = 3677334773;

  static final int connectTimeout = _enviedkeyconnectTimeout ^ 3677334783;

  static final int _enviedkeyreceiveTimeout = 3811478607;

  static final int receiveTimeout = _enviedkeyreceiveTimeout ^ 3811478592;

  static final int _enviedkeysendTimeout = 3212159536;

  static final int sendTimeout = _enviedkeysendTimeout ^ 3212159546;
}
