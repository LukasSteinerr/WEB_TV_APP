import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tvapp/m3u_nullsafe.dart';
import 'package:tvapp/src/movies/ui/live_tv_ui.dart';
import 'package:tvapp/const.dart';

class LiveTV extends StatefulWidget {
  final VoidCallback load;
  final Stream bloc;

  LiveTV({required this.load, required this.bloc});

  @override
  _LiveTVState createState() => _LiveTVState();
}

class _LiveTVState extends State<LiveTV> {
  String url = M3U_URL;

  Widget play = Text("Loading TV...");

  String? link;

  List<M3uGenericEntry> _list = [];

  @override
  void initState() {
    // SystemChrome.setPreferredOrientations(
    //     [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    widget.load();
    super.initState();
  }

  @override
  void dispose() {
    // SystemChrome.setPreferredOrientations(
    //     [DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('entered');
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent()
      },
      child: StreamBuilder<List<M3uGenericEntry>>(
          stream: widget.bloc,
          builder: (context, AsyncSnapshot<List<M3uGenericEntry>> snapshot) {
            print('second');
            if (snapshot.hasData) {
              print("has Data");
              if (snapshot.data!.isEmpty) {
                return Scaffold(
                  body: Center(
                    child: Text("No Data"),
                  ),
                );
              } else {
                _list.addAll(snapshot.data!);
                print(_list);
                return LiveTVUI(list: _list);
              }
            } else {
              print('third');
              return Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          }),
    );
  }

  // user defined function
}
