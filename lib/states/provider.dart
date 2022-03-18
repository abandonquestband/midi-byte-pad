import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class AppProvider extends ChangeNotifier {
  final box = GetStorage();
  String _screen = "pads";
  List _boxGroups = [];
  String _currentGroup = "";
  int _currentGroupIndex = 0;
  List _currentGroupPrograms = [];
  List _currentGroupOrders = [];
  List _currentGroupColors = [];
  List _currentGroupPressMessages = [];
  List _currentGroupReleaseMessages = [];

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
  set currentGroup(String newGroupName) {
    print("setCurrentGroup called! ${newGroupName}");
    box.write("GROUP:PROGRAMS:${newGroupName}",
        box.read("GROUP:PROGRAMS:${_currentGroup}"));
    box.write("GROUP:ORDERS:${newGroupName}",
        box.read("GROUP:ORDERS:${_currentGroup}"));
    box.write("GROUP:COLORS:${newGroupName}",
        box.read("GROUP:COLORS:${_currentGroup}"));
    box.write("GROUP:PRESSMESSAGES:${newGroupName}",
        box.read("GROUP:PRESSMESSAGES:${_currentGroup}"));
    box.write("GROUP:RELEASEMESSAGES:${newGroupName}",
        box.read("GROUP:RELEASEMESSAGES:${_currentGroup}"));
    box.remove("GROUP:PROGRAMS:${_currentGroup}");
    box.remove("GROUP:ORDERS:${_currentGroup}");
    box.remove("GROUP:COLORS:${_currentGroup}");
    box.remove("GROUP:PRESSMESSAGES:${_currentGroup}");
    box.remove("GROUP:RELEASEMESSAGES:${_currentGroup}");
    _currentGroup = newGroupName;
    notifyListeners();
  }

  List get currentGroupPrograms => _currentGroupPrograms;
  List get currentGroupOrders => _currentGroupOrders;
  List get currentGroupColors => _currentGroupColors;
  List get currentGroupPressMessages => _currentGroupPressMessages;
  List get currentGroupReleaseMessages => _currentGroupReleaseMessages;
  int get currentGroupIndex => _currentGroupIndex;

  void updateGroup(group) {
    print("Ummm");
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

  void removeGroup(index) {
    String boxName = boxGroups[index];
    _boxGroups.removeAt(index);
    if (currentGroupIndex >= boxGroups.length) {
      _currentGroupIndex = boxGroups.length - 1;
    }
    box.remove("GROUP:PROGRAMS:${boxName}");
    box.remove("GROUP:ORDERS:${boxName}");
    box.remove("GROUP:COLORS:${boxName}");
    box.remove("GROUP:PRESSMESSAGES:${boxName}");
    box.remove("GROUP:RELEASEMESSAGES:${boxName}");

    _currentGroupPrograms = [];
    _currentGroupOrders = [];
    _currentGroupColors = [];
    _currentGroupPressMessages = [];
    _currentGroupReleaseMessages = [];
    _currentGroup = "";
    notifyListeners();
  }

  void changeGroup(groupIndex) {
    print("boxlread: ${box.getKeys()}");
    var group = box.read("GROUPS")[groupIndex];
    print("what is the goruporder: ${box.read("GROUP:ORDERS:${group}")}");
    _currentGroup = group;
    print(
        "debug:: ${_currentGroupOrders} ${box.read('GROUP:ORDERS:${group}')} ${group}");
    _currentGroupOrders = box.read('GROUP:ORDERS:${group}');
    _currentGroupPrograms = box.read('GROUP:PROGRAMS:${group}');
    _currentGroupColors = box.read('GROUP:COLORS:${group}');
    _currentGroupPressMessages = box.read('GROUP:PRESSMESSAGES:${group}');
    _currentGroupReleaseMessages = box.read('GROUP:RELEASEMESSAGES:${group}');
    _currentGroupIndex = groupIndex;
    notifyListeners();
  }

  void removeProgram(programIndex) {
    List oldGroupPrograms = box.read('GROUP:PROGRAMS:${_currentGroup}');
    List oldGroupOrders = box.read('GROUP:ORDERS:${_currentGroup}');
    List oldGroupColors = box.read('GROUP:COLORS:${_currentGroup}');
    List oldGroupPressMessages =
        box.read('GROUP:PRESSMESSAGES:${_currentGroup}');
    List oldGroupReleaseMessages =
        box.read('GROUP:RELEASEMESSAGES:${_currentGroup}');
    List newGroupPrograms = oldGroupPrograms;
    newGroupPrograms.removeLast();
    List newGroupOrders = oldGroupOrders;
    newGroupOrders.removeLast();
    List newGroupColors = oldGroupColors;
    newGroupColors.removeLast();
    List newGroupPressMessages = oldGroupPressMessages;
    newGroupPressMessages.removeLast();
    List newGroupReleaseMessages = oldGroupReleaseMessages;
    newGroupReleaseMessages.removeLast();
    box.write('GROUP:PROGRAMS:${_currentGroup}', newGroupPrograms);
    box.write('GROUP:ORDERS:${_currentGroup}', newGroupOrders);
    box.write('GROUP:COLORS:${_currentGroup}', newGroupColors);
    box.write('GROUP:PRESSMESSAGES:${_currentGroup}', newGroupPressMessages);
    box.write(
        'GROUP:RELEASEMESSAGES:${_currentGroup}', newGroupReleaseMessages);
    notifyListeners();
  }

  void addProgram() {
    List oldGroupPrograms = box.read('GROUP:PROGRAMS:${_currentGroup}');
    List oldGroupOrders = box.read('GROUP:ORDERS:${_currentGroup}');
    List oldGroupColors = box.read('GROUP:COLORS:${_currentGroup}');
    List oldGroupPressMessages =
        box.read('GROUP:PRESSMESSAGES:${_currentGroup}');
    List oldGroupReleaseMessages =
        box.read('GROUP:RELEASEMESSAGES:${_currentGroup}');
    oldGroupPrograms.add("");
    oldGroupOrders.add('${oldGroupOrders.length}');
    oldGroupColors.add(Color.fromRGBO(255, 255, 255, 1).toString());
    oldGroupPressMessages.add(
        "C0 ${('${oldGroupPressMessages.length.toRadixString(16)}').padLeft(2, "0")}");
    oldGroupReleaseMessages.add("");
    box.write('GROUP:PROGRAMS:${_currentGroup}', oldGroupPrograms);
    box.write('GROUP:ORDERS:${_currentGroup}', oldGroupOrders);
    box.write('GROUP:COLORS:${_currentGroup}', oldGroupColors);
    box.write('GROUP:PRESSMESSAGES:${_currentGroup}', oldGroupPressMessages);
    box.write(
        'GROUP:RELEASEMESSAGES:${_currentGroup}', oldGroupReleaseMessages);
    _currentGroupPrograms = oldGroupPrograms;
    _currentGroupOrders = oldGroupOrders;
    _currentGroupColors = oldGroupColors;
    _currentGroupPressMessages = oldGroupPressMessages;
    _currentGroupReleaseMessages = oldGroupReleaseMessages;
    notifyListeners();
  }

  void updateProgram(index) {
    print("currentGroup is ${_currentGroup}");
    _currentGroupPrograms = box.read('GROUP:PROGRAMS:${_currentGroup}');
    _currentGroupOrders = box.read('GROUP:ORDERS:${_currentGroup}');
    _currentGroupColors = box.read('GROUP:COLORS:${_currentGroup}');
    _currentGroupPressMessages =
        box.read('GROUP:PRESSMESSAGES:${_currentGroup}');
    _currentGroupReleaseMessages =
        box.read('GROUP:RELEASEMESSAGES:${_currentGroup}');
    notifyListeners();
  }

  void changeScreen(String newScreen) {
    _screen = newScreen;
    notifyListeners();
  }
}
