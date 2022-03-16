import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class AppProvider extends ChangeNotifier {
  final box = GetStorage();
  String screen = "pads";
  void changeScreen(String newScreen) {
    screen = newScreen;
    notifyListeners();
  }
}
