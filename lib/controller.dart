import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'dart:typed_data';
import 'dart:math';
import 'package:xml/xml.dart';
import 'package:provider/provider.dart';
import './states/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:io' show Platform, File;

extension ColorBrightness on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  Color lighten([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final hslLight =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }
}

int mutableCurrentPage = 0;

class ControllerPage extends StatelessWidget {
  ControllerPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*
      appBar: AppBar(
        title: Text(remotePDFpath
            .substring(remotePDFpath.lastIndexOf("/") + 1)
            .replaceAll("%20", " ")),
      ),
      */
      body: MidiControls(),
    );
  }
}

class MidiControls extends StatefulWidget {
  MidiControls();

  @override
  MidiControlsState createState() {
    return MidiControlsState();
  }
}

class MidiControlsState extends State<MidiControls> {
  final box = GetStorage();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _editMode = false;
  bool _editGroupsMode = false;
  late var boxGroupsListener;
//  int _totalNumber.length = 0;
  final List<int> _items = List<int>.generate(50, (int index) => index);
  String errorMessage = '';
  StreamSubscription<MidiPacket>? _rxSubscription;
  MidiCommand _midiCommand = MidiCommand();
  List _currentGroupPrograms = [];
  List _currentGroupOrders = [];
  var _tempNewColor = "";

  @override
  void initState() {
//   Provider.of<AppProvider>(context, listen: false).currentGroupOrders.length;
    print("FUNCTION CALLED: INITSTATE");
    super.initState();
  }

  MidiControlsState() {
    print("FUNCTION CALLED: CONSTRUCTOR");
    /*
    boxGroupsListener = box.listenKey("GROUPS", (newGroupsValue) {
      setState(() {
        var currentGroupFromProvider =
            Provider.of<AppProvider>(context, listen: false).currentGroup;
        _currentGroupOrders =
            box.read('GROUP:ORDERS:${currentGroupFromProvider}');
        _currentGroupPrograms =
            box.read('GROUP:PROGRAMS:${currentGroupFromProvider}');
      });
    });
      */
  }
  @override
  void dispose() {
    _rxSubscription?.cancel();
    //box.removeListen(boxGroupsListener);
    boxGroupsListener = null;
    super.dispose();
  }

  void sendMidi(listOfData) {
    Uint8List data = Uint8List(listOfData.length);
    for (var i = 0; i < listOfData.length; i++) {
      data[i] = listOfData[i];
    }
    _midiCommand.sendData(data);
  }

  Future<void> _editPad(BuildContext context, index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        var tempNewLabel = Provider.of<AppProvider>(context, listen: false)
            .currentGroupPrograms[index];
        var tempNewPressMessage =
            Provider.of<AppProvider>(context, listen: false)
                .currentGroupPressMessages[index];
        var tempNewReleaseMessage =
            Provider.of<AppProvider>(context, listen: false)
                .currentGroupReleaseMessages[index];
        var _tempNewColor = Provider.of<AppProvider>(context, listen: false)
            .currentGroupColors[index];
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit Pad #${index}'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  /*
                Text('This is a demo alert dialog.'),
                Text('Would you like to approve of this message?'),
                SizedBox(height: 20),
                */
                  TextFormField(
                      initialValue: tempNewLabel,
                      onChanged: (newText) {
                        tempNewLabel = newText;
                      },
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          labelText: 'Pad Label')),
                  SizedBox(height: 20),
                  TextFormField(
                      initialValue: tempNewPressMessage,
                      onChanged: (newText) {
                        tempNewPressMessage = newText;
                      },
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          labelText: 'MIDI Message (in hex)')),
                  SizedBox(height: 20),
                  TextFormField(
                      initialValue: tempNewReleaseMessage,
                      onChanged: (newText) {
                        tempNewReleaseMessage = newText;
                      },
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          labelText:
                              'Release MIDI Message (leave blank if want none)')),
                  SizedBox(height: 20),
                  Wrap(
                    children: [
                      ...[
                        Color.fromRGBO(26, 19, 49, 1),
                        Color.fromRGBO(39, 41, 71, 1),
                        Color.fromRGBO(35, 82, 88, 1),
                        Color.fromRGBO(51, 113, 85, 1),
                        Color.fromRGBO(91, 191, 139, 1),
                        Color.fromRGBO(181, 215, 123, 1),
                        Color.fromRGBO(243, 193, 103, 1),
                        Color.fromRGBO(223, 114, 72, 1),
                        Color.fromRGBO(217, 50, 76, 1),
                        Color.fromRGBO(148, 53, 92, 1),
                        Color.fromARGB(255, 174, 82, 120),
                        Color.fromRGBO(102, 19, 93, 1),
                        Color.fromRGBO(16, 43, 118, 1),
                        Color.fromARGB(255, 186, 186, 186),
                        Color.fromARGB(255, 255, 255, 255),
                        Color.fromARGB(255, 33, 33, 33)
                      ].map(
                        (color) {
                          print(
                              "are we redoing this ${_tempNewColor} ${color}");
                          var currentColor = _tempNewColor;
                          bool colorsMatch =
                              color.toString() == currentColor ? true : false;
                          return RawMaterialButton(
                            onPressed: () {
                              if (!colorsMatch) {
                                print("colors don't match");
                                setState(() {
                                  _tempNewColor = color.toString();
                                });
                                /*
                              var existingColorsBox = box.read(
                                  "GROUP:COLORS:${Provider.of<AppProvider>(context, listen: false).currentGroup}");
                              existingColorsBox[index] = color.toString();
                              box.write(
                                  "GROUP:COLORS:${Provider.of<AppProvider>(context, listen: false).currentGroup}",
                                  existingColorsBox);
                                  */
                              }
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                  color: !colorsMatch ? color : color),
                              child: Icon(
                                Icons.check_box,
                                color: colorsMatch ? Colors.white : color,
                              ),
                            ),
                          );
                        },
                      )
                    ],
                  )
                ],
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.black),
                onPressed: () {
                  var theCurrentProgram =
                      Provider.of<AppProvider>(context, listen: false)
                          .currentGroup;
                  print("the current program: ${theCurrentProgram}");
                  print("what is this: ${tempNewLabel}");
                  print(
                      "the things: ${Provider.of<AppProvider>(context, listen: false).box.read('GROUP:PROGRAMS:${Provider.of<AppProvider>(context, listen: false).currentGroup}')} ${index} ${tempNewLabel}");

                  var oldProgramNames = [
                    ...Provider.of<AppProvider>(context, listen: false).box.read(
                        'GROUP:PROGRAMS:${Provider.of<AppProvider>(context, listen: false).currentGroup}')
                  ];
                  oldProgramNames[index] = tempNewLabel;
                  Provider.of<AppProvider>(context, listen: false).box.write(
                      'GROUP:PROGRAMS:${Provider.of<AppProvider>(context, listen: false).currentGroup}',
                      oldProgramNames);

                  var oldPressMessages = [
                    ...Provider.of<AppProvider>(context, listen: false).box.read(
                        'GROUP:PRESSMESSAGES:${Provider.of<AppProvider>(context, listen: false).currentGroup}')
                  ];
                  oldPressMessages[index] = tempNewPressMessage;
                  Provider.of<AppProvider>(context, listen: false).box.write(
                      'GROUP:PRESSMESSAGES:${Provider.of<AppProvider>(context, listen: false).currentGroup}',
                      oldPressMessages);

                  var oldReleaseMessages = [
                    ...Provider.of<AppProvider>(context, listen: false).box.read(
                        'GROUP:RELEASEMESSAGES:${Provider.of<AppProvider>(context, listen: false).currentGroup}')
                  ];
                  oldReleaseMessages[index] = tempNewReleaseMessage;
                  Provider.of<AppProvider>(context, listen: false).box.write(
                      'GROUP:RELEASEMESSAGES:${Provider.of<AppProvider>(context, listen: false).currentGroup}',
                      oldReleaseMessages);

                  var oldColors = [
                    ...Provider.of<AppProvider>(context, listen: false).box.read(
                        'GROUP:COLORS:${Provider.of<AppProvider>(context, listen: false).currentGroup}')
                  ];
                  oldColors[index] = _tempNewColor.toString();
                  Provider.of<AppProvider>(context, listen: false).box.write(
                      'GROUP:COLORS:${Provider.of<AppProvider>(context, listen: false).currentGroup}',
                      oldColors);

                  /*
                  Provider.of<AppProvider>(context, listen: false)
                      .currentGroupPrograms[index] = tempNewLabel;
                  Provider.of<AppProvider>(context, listen: false)
                      .currentGroupPressMessages[index] = tempNewPressMessage;
                  Provider.of<AppProvider>(context, listen: false)
                          .currentGroupReleaseMessages[index] =
                      tempNewReleaseMessage;
                  Provider.of<AppProvider>(context, listen: false)
                      .updateProgram(index);
                      */
                  Provider.of<AppProvider>(context, listen: false)
                      .updateProgram(index);

                  setState(() {});
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      var tempNewGroupName = appProvider.currentGroup;
      AppBar appBar = AppBar(
        automaticallyImplyLeading: false,
        title: !_editMode
            ? Text(appProvider.currentGroup)
            : TextFormField(
                initialValue: tempNewGroupName,
                onChanged: (newName) {
                  tempNewGroupName = newName;
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  hintText: 'Group Name',
                )),
        backgroundColor: Colors.black,
        actions: [
          if (!_editMode)
            IconButton(
                tooltip: "Open list of groups",
                onPressed: () {
                  _scaffoldKey.currentState!.openEndDrawer();
                },
                icon: Icon(Icons.music_note)),
          if (!_editMode)
            IconButton(
                tooltip: "Go to previous group",
                onPressed: () {
                  if (appProvider.boxGroups.length > 0 &&
                      appProvider.currentGroupIndex > 0)
                    appProvider.changeGroup(appProvider.currentGroupIndex - 1);
                },
                icon: Icon(Icons.keyboard_arrow_left)),
          if (!_editMode)
            IconButton(
                tooltip: "Go to next group",
                onPressed: () {
                  if (appProvider.boxGroups.length > 0 &&
                      appProvider.currentGroupIndex <
                          appProvider.boxGroups.length - 1)
                    appProvider.changeGroup(appProvider.currentGroupIndex + 1);
                },
                icon: Icon(Icons.keyboard_arrow_right)),
          if (!_editMode)
            IconButton(
                tooltip: "Edit current group of pads",
                onPressed: () {
                  setState(() {
                    _editMode = !_editMode;
                  });
                },
                icon: Icon(Icons.edit)),
          if (!_editMode)
            Consumer<AppProvider>(
                builder: (context, appProvider, child) => IconButton(
                    tooltip: "Go to MIDI connection screen",
                    onPressed: () {
                      appProvider.changeScreen("midi");
                    },
                    icon: Icon(Icons.settings))),
          if (_editMode) ...[
            Divider(color: Colors.black, thickness: 10),
            IconButton(
                tooltip: "Add a pad",
                onPressed: () {
                  appProvider.addProgram();
                },
                icon: Icon(Icons.add)),
            IconButton(
                tooltip: "Remove last pad",
                onPressed: () {
                  setState(() {
                    appProvider.removeProgram(_currentGroupPrograms.length - 1);
                  });
                },
                icon: Icon(Icons.remove)),
            IconButton(
                tooltip: "Finish editing group of pads",
                onPressed: () {
                  var oldGroupNames =
                      Provider.of<AppProvider>(context, listen: false)
                          .box
                          .read("GROUPS");
                  oldGroupNames[appProvider.currentGroupIndex] =
                      tempNewGroupName;
                  Provider.of<AppProvider>(context, listen: false)
                      .box
                      .write("GROUPS", oldGroupNames);
                  setState(() {
                    if (appProvider.currentGroup != tempNewGroupName) {
                      appProvider.currentGroup = tempNewGroupName;
                    }
                    _editMode = false;
                  });
                },
                icon: Icon(Icons.check_box)),
          ]
        ],
      );
      var heightOfAppBar = appBar.preferredSize.height;

      var drawerItems = Consumer<AppProvider>(
          builder: (context, appProvider, child) => ListView(
                //scrollController: ScrollController(),
                controller: ScrollController(),
                //padding: const EdgeInsets.symmetric(horizontal: 40),
                children: <Widget>[
                  for (int index = 0;
                      index < appProvider.boxGroups.length;
                      index += 1)
                    Card(
                        child: InkWell(
                      child: ListTile(
                          key: Key('$index: ${appProvider.boxGroups[index]}'),
                          //tileColor: _items[index].isOdd ? oddItemColor : evenItemColor,
                          title:
                              Text('$index: ${appProvider.boxGroups[index]}'),
                          trailing: _editGroupsMode
                              ? IconButton(
                                  tooltip: "Delete group",
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    Provider.of<AppProvider>(context,
                                            listen: false)
                                        .removeGroup(index);
                                  },
                                )
                              : null),
                      onTap: () {
                        Provider.of<AppProvider>(context, listen: false)
                            .changeGroup(index);
                      },
                    )),
                ],
                /*
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final int item = _items.removeAt(oldIndex);
            _items.insert(newIndex, item);
          });
        }*/
              ));
      return Scaffold(
          appBar: appBar,
          backgroundColor: Colors.black,
          key: _scaffoldKey,
          endDrawer: Drawer(
            child: Scaffold(
                appBar: AppBar(
                  title: Text("Groups"),
                  backgroundColor: Color.fromRGBO(152, 56, 148, 1),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      tooltip: "Add blank group",
                      icon: Icon(Icons.add_box),
                      onPressed: () {
                        final bank =
                            "New Group ${appProvider.boxGroups.length}";
                        final programs = [];
                        final orders = [];
                        print("bank is: ${bank}");
                        print("programs are: ${programs}");
                        print("orders are: ${orders}");
                        //just to make sure they're exactly the same
                        if (orders.length == programs.length) {
                          Provider.of<AppProvider>(context, listen: false)
                              .box
                              .write("GROUP:ORDERS:${bank}", orders);
                          Provider.of<AppProvider>(context, listen: false)
                              .box
                              .write("GROUP:PROGRAMS:${bank}", programs);
                          Provider.of<AppProvider>(context, listen: false)
                              .box
                              .write(
                                  "GROUP:COLORS:${bank}",
                                  programs
                                      .map((p) => Color.fromRGBO(16, 43, 118, 1)
                                          .toString())
                                      .toList());
                          Provider.of<AppProvider>(context, listen: false)
                              .box
                              .write(
                                  "GROUP:PRESSMESSAGES:${bank}",
                                  orders
                                      .map((o) =>
                                          'C0 ${o!.toRadixString(16).padLeft(2, "0")}')
                                      .toList());
                          Provider.of<AppProvider>(context, listen: false)
                              .box
                              .write("GROUP:RELEASEMESSAGES:${bank}",
                                  programs.map((p) => "").toList());
                          Provider.of<AppProvider>(context, listen: false)
                              .updateGroup(bank);
                        }
                      },
                    ),
                    IconButton(
                      tooltip: "Add from EMU XML bank file",
                      icon: Icon(Icons.file_open),
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles();

                        if (result != null) {
                          print(result);
                          File file = File(result.files.single.path!);
                          final document =
                              XmlDocument.parse(file.readAsStringSync());
                          final bank =
                              document.getElement("Bank")!.getAttribute("Name");
                          final programs = document
                              .getElement("Bank")!
                              .firstElementChild!
                              .children
                              .map((program) {
                                return program.getAttribute("Name");
                              })
                              .toList()
                              .where(
                                (element) {
                                  return element != null;
                                },
                              )
                              .toList();
                          final orders = document
                                  .getElement("Bank")!
                                  .firstElementChild!
                                  .children
                                  .asMap()
                                  .entries
                                  .map((program) {
                            //return program.val.getAttribute("Order");
                            return '${program.key.toRadixString(16)}';
                          }).toList() /*
                              .where(
                                (element) {
                                  return element != null;
                                },
                              )
                              .toList()*/
                              ;
                          print("bank is: ${bank}");
                          print("programs are: ${programs}");
                          print("orders are: ${orders}");
                          //just to make sure they're exactly the same
                          if (orders.length == programs.length || true) {
                            var oldBoxGroup =
                                Provider.of<AppProvider>(context, listen: false)
                                        .box
                                        .read(bank!) ??
                                    {};
                            var newBoxGroup = {
                              "bank": bank,
                              "programs": programs,
                              "orders": orders
                            };
                            print("newboxgroup: ${newBoxGroup["programs"]}");
                            print(
                                "is the box an empty array ${Provider.of<AppProvider>(context, listen: false).box.read("GROUPS")}");
                            Provider.of<AppProvider>(context, listen: false)
                                .box
                                .write("GROUP:ORDERS:${bank}", orders);
                            Provider.of<AppProvider>(context, listen: false)
                                .box
                                .write("GROUP:PROGRAMS:${bank}", programs);
                            Provider.of<AppProvider>(context, listen: false)
                                .box
                                .write(
                                    "GROUP:COLORS:${bank}",
                                    programs
                                        .map((p) =>
                                            Color.fromRGBO(16, 43, 118, 1)
                                                .toString())
                                        .toList());
                            Provider.of<AppProvider>(context, listen: false)
                                .box
                                .write(
                                    "GROUP:PRESSMESSAGES:${bank}",
                                    orders
                                        .map((o) => 'C0 ${o.padLeft(2, "0")}')
                                        .toList());
                            Provider.of<AppProvider>(context, listen: false)
                                .box
                                .write("GROUP:RELEASEMESSAGES:${bank}",
                                    programs.map((p) => "").toList());
                            Provider.of<AppProvider>(context, listen: false)
                                .updateGroup(bank);

                            print("Ummm1");
                            print(
                                "what is this? ${Provider.of<AppProvider>(context, listen: false).box.read("GROUPS")}");
                          }
                        } else {
                          // User canceled the picker
                        }
                      },
                    ),
                    if (!_editGroupsMode)
                      IconButton(
                        tooltip: "Edit Existing Groups",
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            _editGroupsMode = true;
                          });
                        },
                      ),
                    if (_editGroupsMode)
                      IconButton(
                        tooltip: "Finished Editing Existing Groups",
                        icon: Icon(Icons.check_box),
                        onPressed: () {
                          setState(() {
                            _editGroupsMode = false;
                          });
                        },
                      ),
                  ],
                ),
                body: drawerItems),
          ),
          body: Provider.of<AppProvider>(context, listen: false).currentGroup ==
                  ""
              ? Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset("assets/images/appIcon/byte-pad-logo.png"),
                    Text(
                      "Use the menu above to get started!",
                      style: TextStyle(fontSize: 25, color: Colors.white),
                      textAlign: TextAlign.center,
                    )
                  ],
                ))
              : Center(child: Builder(builder: (BuildContext context) {
                  var size = MediaQuery.of(context).size;
                  final height = size.height - heightOfAppBar;
                  final width = size.width;
                  double squareRootOfPads = sqrt(
                      Provider.of<AppProvider>(context, listen: false)
                          .currentGroupPrograms
                          .length);
                  int nextPerfectSquare = pow(
                      (sqrt(Provider.of<AppProvider>(context, listen: false)
                                  .currentGroupPrograms
                                  .length) +
                              1)
                          .floor(),
                      2) as int;
                  int previousPerfectSquare = pow(
                      (sqrt(Provider.of<AppProvider>(context, listen: false)
                              .currentGroupPrograms
                              .length))
                          .floor(),
                      2) as int;
                  int roundedSqrt = (squareRootOfPads.round());
                  print("${previousPerfectSquare}.....${nextPerfectSquare}");
                  int differenceFromSquareRoots =
                      nextPerfectSquare - previousPerfectSquare;
                  bool positionIsLessThanHalfOfDistanceToNextSquareRoot =
                      roundedSqrt < differenceFromSquareRoots / 2;
                  //if the difference is less than half the total distance
                  final double itemHeight = height;
                  final double itemWidth = width;
                  if (Provider.of<AppProvider>(context, listen: false)
                          .currentGroupPrograms
                          .length <=
                      0) {
                    return SizedBox.shrink();
                  }
                  return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: squareRootOfPads.ceil(),
                        childAspectRatio: height < width
                            ? max(
                                itemHeight / itemWidth, itemWidth / itemHeight)
                            : min(
                                itemHeight / itemWidth, itemWidth / itemHeight),
                        //childAspectRatio: 3 / 4.5,
                      ),
                      //padding: EdgeInsets.all(20),
                      itemCount: appProvider.currentGroupPrograms.length,
                      itemBuilder: (context, index) {
                        var _pushed = false;
                        return StatefulBuilder(builder: (context, setState) {
                          var currentColor = Color(int.parse(
                              appProvider.currentGroupColors[index].substring(
                                  8,
                                  appProvider.currentGroupColors[index].length -
                                      1),
                              radix: 16));
                          return GestureDetector(
                            //onSecondaryTap: ,
                            onTapDown: (td) {
                              if (appProvider
                                      .currentGroupPressMessages[index] !=
                                  "") {
                                var midiMessage = appProvider
                                    .currentGroupPressMessages[index]
                                    .toString()
                                    .split(" ")
                                    .map((hex) => int.parse(hex, radix: 16))
                                    .toList();
                                sendMidi(midiMessage);
                              }
                              setState(() {
                                _pushed = true;
                              });
                            },
                            onTapCancel: () {
                              if (appProvider
                                      .currentGroupReleaseMessages[index] !=
                                  "") {
                                var midiMessage = appProvider
                                    .currentGroupReleaseMessages[index]
                                    .toString()
                                    .split(" ")
                                    .map((hex) => int.parse(hex, radix: 16))
                                    .toList();
                                sendMidi(midiMessage);
                              }
                              setState(() {
                                _pushed = false;
                              });
                            },
                            onTapUp: (tu) {
                              if (appProvider
                                      .currentGroupReleaseMessages[index] !=
                                  "") {
                                var midiMessage = appProvider
                                    .currentGroupReleaseMessages[index]
                                    .toString()
                                    .split(" ")
                                    .map((hex) => int.parse(hex, radix: 16))
                                    .toList();
                                sendMidi(midiMessage);
                              }
                              setState(() {
                                _pushed = false;
                              });
                            },
                            child: Card(
                              elevation: 2,
                              color: _pushed
                                  ? currentColor.lighten(.1)
                                  : currentColor,
                              child: Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  Positioned(
                                      child: Text(
                                          "${appProvider.currentGroupPressMessages[index]}",
                                          style: TextStyle(
                                              color: Color(int.parse(
                                                              appProvider
                                                                  .currentGroupColors[
                                                                      index]
                                                                  .substring(
                                                                      8,
                                                                      appProvider
                                                                              .currentGroupColors[index]
                                                                              .length -
                                                                          1),
                                                              radix: 16))
                                                          .computeLuminance() >
                                                      0.5
                                                  ? Colors.black
                                                  : Colors.white)),
                                      top: 10,
                                      left: 10),
                                  Positioned(
                                      child: Text(
                                          "${appProvider.currentGroupReleaseMessages[index]}",
                                          style: TextStyle(
                                              color: Color(int.parse(
                                                              appProvider
                                                                  .currentGroupColors[
                                                                      index]
                                                                  .substring(
                                                                      8,
                                                                      appProvider
                                                                              .currentGroupColors[index]
                                                                              .length -
                                                                          1),
                                                              radix: 16))
                                                          .computeLuminance() >
                                                      0.5
                                                  ? Colors.black
                                                  : Colors.white)),
                                      bottom: 10,
                                      left: 10),
                                  if (_editMode)
                                    Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton(
                                          tooltip: "Edit pad",
                                          //iconSize: 10,
                                          color: Color(int.parse(
                                                          appProvider
                                                              .currentGroupColors[
                                                                  index]
                                                              .substring(
                                                                  8,
                                                                  appProvider
                                                                          .currentGroupColors[
                                                                              index]
                                                                          .length -
                                                                      1),
                                                          radix: 16))
                                                      .computeLuminance() >
                                                  0.5
                                              ? Colors.black
                                              : Colors.white,
                                          padding: EdgeInsets.all(0),
                                          icon: Icon(Icons.edit),
                                          onPressed: () async {
                                            _tempNewColor =
                                                Provider.of<AppProvider>(
                                                        context,
                                                        listen: false)
                                                    .currentGroupColors[index];
                                            await _editPad(context, index);
                                          },
                                        )),
                                  Text(appProvider.currentGroupPrograms[index],
                                      style: TextStyle(
                                          color: Color(int.parse(
                                                          appProvider
                                                              .currentGroupColors[
                                                                  index]
                                                              .substring(
                                                                  8,
                                                                  appProvider
                                                                          .currentGroupColors[
                                                                              index]
                                                                          .length -
                                                                      1),
                                                          radix: 16))
                                                      .computeLuminance() >
                                                  0.5
                                              ? Colors.black
                                              : Colors.white))
                                ],
                              ),
                            ),
                          );
                        });
                      });
                })));
    });
  }
}

class SteppedSelector extends StatelessWidget {
  final String label;
  final int minValue;
  final int maxValue;
  final int value;
  final Function(int) callback;

  SteppedSelector(
      this.label, this.value, this.minValue, this.maxValue, this.callback);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(label),
        IconButton(
            icon: Icon(Icons.remove_circle),
            onPressed: (value > minValue)
                ? () {
                    callback(value - 1);
                  }
                : null),
        Text(value.toString()),
        IconButton(
            icon: Icon(Icons.add_circle),
            onPressed: (value < maxValue)
                ? () {
                    callback(value + 1);
                  }
                : null)
      ],
    );
  }
}

class SlidingSelector extends StatelessWidget {
  final String label;
  final int minValue;
  final int maxValue;
  final int value;
  final Function(int) callback;

  SlidingSelector(
      this.label, this.value, this.minValue, this.maxValue, this.callback);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(label),
        Slider(
          value: value.toDouble(),
          divisions: maxValue,
          min: minValue.toDouble(),
          max: maxValue.toDouble(),
          onChanged: (v) {
            callback(v.toInt());
          },
        ),
        Text(value.toString()),
      ],
    );
  }
}
