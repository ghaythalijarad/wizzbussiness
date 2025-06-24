import 'package:flutter/material.dart';

class Auth with ChangeNotifier {
  bool _isAuth = false;

  bool get isAuth {
    return _isAuth;
  }

  void login() {
    _isAuth = true;
    notifyListeners();
  }

  void logout() {
    _isAuth = false;
    notifyListeners();
  }
}
