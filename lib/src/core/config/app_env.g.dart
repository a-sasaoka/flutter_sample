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
    2962406320,
    3016947958,
    526046087,
    2005444369,
    1386839651,
    3025543269,
    3776028032,
    3462565682,
    4059980848,
    2268928302,
    2512689628,
    3569575220,
    3363086363,
    481472964,
    856652079,
    1905994735,
    2424727290,
    1297402340,
    2504405858,
    3759084782,
    3470294646,
    3839258679,
    60464182,
    2262016218,
    940138033,
    2894091715,
    135582949,
    789742432,
    3298914966,
    1932981494,
    1594622920,
    172220091,
    2572844595,
    1152425206,
    3664484178,
    639639402,
  ];

  static const List<int> _envieddatabaseUrl = <int>[
    2962406360,
    3016947842,
    526046195,
    2005444449,
    1386839568,
    3025543263,
    3776028079,
    3462565661,
    4059980890,
    2268928349,
    2512689587,
    3569575258,
    3363086443,
    481472936,
    856652110,
    1905994636,
    2424727199,
    1297402252,
    2504405773,
    3759084674,
    3470294546,
    3839258706,
    60464196,
    2262016244,
    940138053,
    2894091706,
    135582869,
    789742345,
    3298915061,
    1932981401,
    1594622892,
    172220126,
    2572844573,
    1152425109,
    3664484157,
    639639303,
  ];

  static final String baseUrl = String.fromCharCodes(
    List<int>.generate(
      _envieddatabaseUrl.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddatabaseUrl[i] ^ _enviedkeybaseUrl[i]),
  );

  static final int _enviedkeyconnectTimeout = 326010998;

  static final int connectTimeout = _enviedkeyconnectTimeout ^ 326011004;

  static final int _enviedkeyreceiveTimeout = 2479824665;

  static final int receiveTimeout = _enviedkeyreceiveTimeout ^ 2479824662;

  static final int _enviedkeysendTimeout = 3166708319;

  static final int sendTimeout = _enviedkeysendTimeout ^ 3166708309;
}
