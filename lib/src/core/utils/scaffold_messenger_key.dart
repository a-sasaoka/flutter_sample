import 'package:flutter/material.dart';

/// 🌐 アプリ全体の [ScaffoldMessenger] を操作するためのグローバルキー。
/// 画面遷移時などに、どの画面からでもスナックバーを消去（clearSnackBars）するために使用します。
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
