import 'dart:async';
import 'package:drag_and_drop_gridview/devdrag.dart';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'dart:typed_data';
import 'package:flutter_midi_command/flutter_midi_command_messages.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import './states/provider.dart';
import 'dart:io' show Platform, File;

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
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _editMode = false;
  int _totalNumberOfPads = 10;
  final List<int> _items = List<int>.generate(50, (int index) => index);
  String errorMessage = '';
  StreamSubscription<MidiPacket>? _rxSubscription;
  MidiCommand _midiCommand = MidiCommand();

  @override
  void initState() {
    super.initState();
  }

  void sendMidi(listOfData) {
    Uint8List data = Uint8List(listOfData.length);
    for (var i = 0; i < listOfData.length; i++) {
      data[i] = listOfData[i];
    }
    _midiCommand.sendData(data);
  }

  void dispose() {
    // _setupSubscription?.cancel();
    _rxSubscription?.cancel();
    super.dispose();
  }

  Future<void> _editPad(BuildContext context, index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
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
                    initialValue: "C0 ${index}",
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        labelText: 'Pad Label')),
                SizedBox(height: 20),
                TextFormField(
                    initialValue: "C0 ${index}",
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        labelText: 'MIDI Message (in hex)')),
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
                      Color.fromRGBO(102, 19, 93, 1),
                      Color.fromRGBO(16, 43, 118, 1)
                    ].map(
                      (color) => SizedBox(
                        width: 42.0,
                        height: 42.0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: color),
                          child: Icon(
                            Icons.check_box,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _totalNumberOfPads = index;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Enabled'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
//    int crossAxisCount 6;
    AppBar appBar = AppBar(
      automaticallyImplyLeading: false,
      title: !_editMode
          ? Text("Ballad of the Goddess")
          : TextFormField(
              initialValue: "Ballad of them Goddess",
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
              onPressed: () {
                _scaffoldKey.currentState!.openEndDrawer();
              },
              icon: Icon(Icons.music_note)),
        if (!_editMode)
          IconButton(onPressed: () {}, icon: Icon(Icons.keyboard_arrow_left)),
        if (!_editMode)
          IconButton(onPressed: () {}, icon: Icon(Icons.keyboard_arrow_right)),
        if (!_editMode)
          IconButton(
              onPressed: () {
                setState(() {
                  _editMode = !_editMode;
                });
              },
              icon: Icon(Icons.edit)),
        if (!_editMode)
          Consumer<AppProvider>(
              builder: (context, appProvider, child) => IconButton(
                  onPressed: () {
                    appProvider.changeScreen("midi");
                  },
                  icon: Icon(Icons.settings))),
        if (_editMode) ...[
          Divider(color: Colors.black, thickness: 10),
          IconButton(
              onPressed: () {
                setState(() {
                  _totalNumberOfPads = _totalNumberOfPads + 1;
                });
              },
              icon: Icon(Icons.add)),
          IconButton(
              onPressed: () {
                setState(() {
                  _totalNumberOfPads =
                      _totalNumberOfPads - 1 < 0 ? 0 : _totalNumberOfPads - 1;
                });
              },
              icon: Icon(Icons.remove)),
          IconButton(
              onPressed: () {
                setState(() {
                  _editMode = false;
                });
              },
              icon: Icon(Icons.check_box)),
        ]
      ],
    );
    var heightOfAppBar = appBar.preferredSize.height;

    var drawerItems = ReorderableListView(
        scrollController: ScrollController(),
        padding: const EdgeInsets.symmetric(horizontal: 40),
        children: <Widget>[
          for (int index = 0; index < _items.length; index += 1)
            ListTile(
              key: Key('$index'),
              //tileColor: _items[index].isOdd ? oddItemColor : evenItemColor,
              title: Text('Item ${_items[index]}'),
              //trailing: Icon(Icons.delete)
            ),
        ],
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final int item = _items.removeAt(oldIndex);
            _items.insert(newIndex, item);
          });
        });
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
                    tooltip: "Add from file",
                    icon: Icon(Icons.file_open),
                    onPressed: () {},
                  ),
                  IconButton(
                    tooltip: "Add blank group",
                    icon: Icon(Icons.add_box),
                    onPressed: () {},
                  ),
                ],
              ),
              body: drawerItems),
        ),
        body: Center(child: Builder(builder: (BuildContext context) {
          var size = MediaQuery.of(context).size;
          final height = size.height - heightOfAppBar;
          final width = size.width;
          double squareRootOfPads = sqrt(_totalNumberOfPads);
          int nextPerfectSquare =
              pow((sqrt(_totalNumberOfPads) + 1).floor(), 2) as int;
          int previousPerfectSquare =
              pow((sqrt(_totalNumberOfPads)).floor(), 2) as int;
          int roundedSqrt = (squareRootOfPads.round());
          print("${previousPerfectSquare}.....${nextPerfectSquare}");
          int differenceFromSquareRoots =
              nextPerfectSquare - previousPerfectSquare;
          bool positionIsLessThanHalfOfDistanceToNextSquareRoot =
              roundedSqrt < differenceFromSquareRoots / 2;
          //if the difference is less than half the total distance
          final double itemHeight = height;
          final double itemWidth = width;
          if (_totalNumberOfPads <= 0) {
            return SizedBox.shrink();
          }
          return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: squareRootOfPads.ceil(),
                childAspectRatio: height < width
                    ? max(itemHeight / itemWidth, itemWidth / itemHeight)
                    : min(itemHeight / itemWidth, itemWidth / itemHeight),
                //childAspectRatio: 3 / 4.5,
              ),
              //padding: EdgeInsets.all(20),
              itemCount: _totalNumberOfPads,
              itemBuilder: (context, index) => GestureDetector(
                    //onSecondaryTap: ,
                    onTapDown: (sf) {
                      sendMidi([0xC0, index]);
                      //sendMidi([0x90, 0x40 + index, 0x64]);
                    },
                    onTapCancel: () {
                      //sendMidi([0x80, 0x40 + index, 0x0]);
                    },
                    onTapUp: (sd) {
                      sendMidi([0xC0, 0]);
                      // sendMidi([0x80, 0x40 + index, 0x0]);
                    },
                    child: Card(
                      elevation: 2,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Positioned(
                              child: _editMode
                                  ? Text("C0 ${index}")
                                  : Text("${index}"),
                              top: 10,
                              left: 10),
                          if (_editMode)
                            Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  //iconSize: 10,
                                  padding: EdgeInsets.all(0),
                                  icon: Icon(Icons.edit),
                                  onPressed: () async {
                                    await _editPad(context, index);
                                  },
                                )),
                          Text("hej")
                        ],
                      ),
                    ),
                  ));
        })));
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
