import 'dart:async';
import 'package:drag_and_drop_gridview/devdrag.dart';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'dart:typed_data';
import 'package:flutter_midi_command/flutter_midi_command_messages.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:math';
import 'dart:io' show Platform, File;

int mutableCurrentPage = 0;

class ControllerPage extends StatelessWidget {
  String remotePDFpath;
  Function changeSong;

  ControllerPage(this.remotePDFpath, this.changeSong);

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
      key: ValueKey<String>(remotePDFpath),
      body: MidiControls(remotePDFpath, changeSong),
    );
  }
}

class MidiControls extends StatefulWidget {
  String remotePDFpath;
  Function changeSong;

  MidiControls(this.remotePDFpath, this.changeSong);

  @override
  MidiControlsState createState() {
    return new MidiControlsState();
  }
}

class MidiControlsState extends State<MidiControls> {
  var _channel = 0;
  var _controller = 0;
  var _value = 0;
  bool _editMode = false;
  int? pages = 0;
  int _totalNumberOfPages = 1;
  int _totalNumberOfPads = 10;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';
  late PDFViewController _pdfViewController;
  late PdfViewerController _pdfViewerController;
  StreamSubscription<MidiPacket>? _rxSubscription;
  MidiCommand _midiCommand = MidiCommand();

  @override
  void initState() {
    _pdfViewerController = PdfViewerController();
    //_rxSubscription =
    //    _midiCommand.onMidiDataReceived?.listen(handleMidiPackets);

    super.initState();
  }

  void handleMidiData(data) async {
    //print('handleMidiData: ${data}');
    if (data[0] == 192 && data.length > 1) {
      if (Platform.isMacOS) {
        _pdfViewerController.jumpToPage(data[1] + 1);
      } else {
        _pdfViewController.setPage(data[1]);
      }
      int newState = data[1]; //Platform.isMacOS ? data[1] + 1 : data[1];
      mutableCurrentPage = Platform.isMacOS ? data[1] + 1 : data[1];
      ;
      setState(() {
        currentPage = newState;
      });
    }
    if (data[0] == 176 && data[1] == 0 && data.length > 2) {
      widget.changeSong(data[2]);
    }
  }

  void handleMidiPackets(packet) {
    var data = packet.data;
    //var timestamp = packet.timestamp;
    //var device = packet.device;
    //print(
    //    "data $data @ time $timestamp from device ${device.name}:${device.id}");
    //var status = data[0];

    List<int> midiPacket = <int>[...data];
    var i = 0;

    var bufferOfGroups = [];
    var buffer = [];
    while (i < midiPacket.length) {
      if (midiPacket[i] == 176 || midiPacket[i] == 192) {
        //check to see how big buffer is currently
        while (buffer.length < 3) {
          buffer.add(0);
        }
        bufferOfGroups.add(buffer);
        buffer = [];
        buffer.add(midiPacket[i]);
      } else {
        buffer.add(midiPacket[i]);
        if (buffer.length == 3) {
          bufferOfGroups.add(buffer);
          buffer = [];
        }
      }
      i++;
    }
    if (buffer.length != 0) {
      while (buffer.length < 3) {
        buffer.add(0);
      }
      bufferOfGroups.add(buffer);
      buffer = [];
    }
    bufferOfGroups.forEach((message) {
      handleMidiData(message);
    });
  }

  void sendMidi(listOfData) {
    Uint8List data = Uint8List(listOfData.length);
    for (var i = 0; i < listOfData.length; i++) {
      data[i] = listOfData[i];
    }
    MidiCommand().sendData(data);
  }

  void dispose() {
    // _setupSubscription?.cancel();
    _rxSubscription?.cancel();
    super.dispose();
  }

  Future<void> _editPad(BuildContext context, index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit the Pad!'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('This is a demo alert dialog.'),
                Text('Would you like to approve of this message?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Approve'),
              onPressed: () {
                setState(() {
                  _totalNumberOfPads = index;
                });
                Navigator.of(context).pop();
              },
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
      title: !_editMode
          ? Text("Ballad of the Goddess")
          : TextFormField(
              initialValue: "Ballad of the Goddess",
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                hintText: 'Group Name',
              )),
      backgroundColor: Theme.of(context).primaryColor,
      actions: [
        if (!_editMode)
          IconButton(
              onPressed: () {
                setState(() {
                  _editMode = !_editMode;
                });
              },
              icon: Icon(Icons.edit)),
        if (_editMode) ...[
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
    return Scaffold(
        appBar: appBar,
        backgroundColor: Colors.black,
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
                        children: <Widget>[
                          Positioned(
                              child: _editMode
                                  ? Text("editing")
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
                                ))
                        ],
                      ),
                    ),
                  ));
        })));
  }

  _onChannelChanged(int newValue) {
    setState(() {
      _channel = newValue - 1;
    });
  }

  _onControllerChanged(int newValue) {
    setState(() {
      _controller = newValue;
    });
  }

  _onValueChanged(int newValue) {
    setState(() {
      _value = newValue;
      CCMessage(channel: _channel, controller: _controller, value: _value)
          .send();
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
