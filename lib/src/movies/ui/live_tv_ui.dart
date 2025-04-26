import 'package:flutter/material.dart';
import 'package:tvapp/m3u_nullsafe.dart';
import 'package:tvapp/src/movies/movies.dart';
import 'package:tvapp/widgets/create_Drawer.dart';

class LiveTVUI extends StatefulWidget {
  final List<M3uGenericEntry> list;

  LiveTVUI({required this.list});

  @override
  _LiveTVUIState createState() => _LiveTVUIState();
}

class _LiveTVUIState extends State<LiveTVUI> {
  Set<String> groupList = {};

  @override
  void initState() {
    for (var element in widget.list) {
      if (element.attributes['group-title'] != null) {
        groupList.add(element.attributes['group-title']!);
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live TV'),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepOrange,
              ),
              child: Center(
                child: Text(
                  'IPTV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            CreateDrawerBody(
              icon: Icons.home,
              text: 'Home',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            CreateDrawerBody(
              icon: Icons.tv,
              text: 'TV Shows',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Movies(mode: 'tv'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'IPTV Channels',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Found ${widget.list.length} channels',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Categories: ${groupList.length}',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
