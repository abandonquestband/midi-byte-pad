import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class AppProvider extends ChangeNotifier {
  final box = GetStorage();
  String _screen = "pads";
  List _boxGroups = [];
  String _currentGroup = "";
  List _currentGroupPrograms = [];
  List _currentGroupOrders = [];

  AppProvider() {
    if (box.read("GROUPS") == null) {
      box.write("GROUPS", []);
    }
    _boxGroups = box.read("GROUPS");
    box.listenKey("GROUPS", (value) {
      _boxGroups = value;
    });
  }

  String get screen => _screen;
  List get boxGroups => _boxGroups;
  String get currentGroup => _currentGroup;
  List get currentGroupPrograms => _currentGroupPrograms;
  List get currentGroupOrders => _currentGroupOrders;

  void updateGroup(group) {
    //gets the data from local storage
    if (_boxGroups.contains(group)) {
      var existingIndex = _boxGroups.indexOf(group);
      _boxGroups[existingIndex] = group;
      print('about to write groups: ${_boxGroups}');
      box.write("GROUPS", _boxGroups);
    } else {
      _boxGroups.add(group);
      print('about to write groups: ${_boxGroups}');
      box.write("GROUPS", _boxGroups);
    }
    notifyListeners();
  }

  void changeGroup(groupIndex) {
    var group = _boxGroups[groupIndex];
    _currentGroup = group;
    _currentGroupOrders = box.read('GROUP:ORDERS:${group}');
    _currentGroupPrograms = box.read('GROUP:PROGRAMS:${group}');
    notifyListeners();
  }

  void changeScreen(String newScreen) {
    _screen = newScreen;
    notifyListeners();
  }
}
