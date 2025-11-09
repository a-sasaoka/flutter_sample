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
    3525308447,
    3687913358,
    470657978,
    4115030496,
    3478132341,
    616773121,
    1068254066,
    1791120620,
    1039110678,
    2497194635,
    3468366046,
    3008536746,
    1268953576,
    1475739697,
    3080605270,
    3513470947,
    2448098062,
    345078179,
    472057388,
    189745073,
    1785958730,
    2400896511,
    3118262532,
    705217071,
    3582652936,
    4022499961,
    1115083505,
    2940102907,
    3918469332,
    3008083082,
    3107639432,
    1662666431,
    4022083314,
    594146776,
    227017090,
    1457838594,
  ];

  static const List<int> _envieddatabaseUrl = <int>[
    3525308535,
    3687913466,
    470657998,
    4115030416,
    3478132230,
    616773179,
    1068254045,
    1791120579,
    1039110780,
    2497194744,
    3468366001,
    3008536772,
    1268953496,
    1475739741,
    3080605239,
    3513470848,
    2448098155,
    345078219,
    472057411,
    189745117,
    1785958702,
    2400896410,
    3118262646,
    705217025,
    3582653052,
    4022499840,
    1115083393,
    2940102802,
    3918469303,
    3008083173,
    3107639532,
    1662666458,
    4022083292,
    594146747,
    227017197,
    1457838703,
  ];

  static final String baseUrl = String.fromCharCodes(
    List<int>.generate(
      _envieddatabaseUrl.length,
      (int i) => i,
      growable: false,
    ).map((int i) => _envieddatabaseUrl[i] ^ _enviedkeybaseUrl[i]),
  );

  static final int _enviedkeyconnectTimeout = 1427279176;

  static final int connectTimeout = _enviedkeyconnectTimeout ^ 1427279170;

  static final int _enviedkeyreceiveTimeout = 513530075;

  static final int receiveTimeout = _enviedkeyreceiveTimeout ^ 513530068;

  static final int _enviedkeysendTimeout = 3171782154;

  static final int sendTimeout = _enviedkeysendTimeout ^ 3171782144;
}
