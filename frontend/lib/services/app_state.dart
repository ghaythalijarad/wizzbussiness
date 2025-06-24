import 'package:flutter/foundation.dart';

class AppState with ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void setOnline(bool isOnline) {
    _isOnline = isOnline;
    notifyListeners();
  }

  void logout() {
    // Reset app state on logout
    _isOnline = true;
    notifyListeners();
  }
}
