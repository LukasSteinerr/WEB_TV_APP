import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tvapp/size_config.dart';
import 'package:tvapp/screens/add_playlist_screen.dart';
import 'package:tvapp/screens/add_xtream_screen.dart';
import 'package:tvapp/screens/playlist_view_screen.dart';
import 'package:tvapp/screens/xtream_categories_screen.dart';
import 'package:tvapp/services/playlist_storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(LayoutBuilder(builder: (context, constraints) {
    return OrientationBuilder(builder: (context, orientation) {
      SizeConfig().init(constraints, orientation);
      return Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent()
          },
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: Colors.deepOrange,
              primaryColorDark: Colors.deepOrange,
              primarySwatch: Colors.deepOrange,
              colorScheme: ColorScheme.light(
                secondary: Colors.deepOrangeAccent,
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: Colors.deepOrange,
              primaryColorDark: Colors.deepOrange,
              primarySwatch: Colors.deepOrange,
              colorScheme: ColorScheme.dark(
                secondary: Colors.deepOrangeAccent,
              ),
            ),
            themeMode: ThemeMode.dark,
            home: HomeScreen(),
          ));
    });
  }));
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _m3uPlaylists = [];
  List<Map<String, dynamic>> _xtreamConnections = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedContent();
  }

  Future<void> _loadSavedContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load saved M3U playlists and Xtream connections
      final m3uPlaylists = await PlaylistStorageService.getM3UPlaylists();
      final xtreamConnections =
          await PlaylistStorageService.getXtreamConnections();

      setState(() {
        _m3uPlaylists = m3uPlaylists;
        _xtreamConnections = xtreamConnections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load saved content: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteM3UPlaylist(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await PlaylistStorageService.deleteM3UPlaylist(name);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playlist deleted')),
        );
        _loadSavedContent();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete playlist')),
        );
      }
    }
  }

  Future<void> _deleteXtreamConnection(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Connection'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await PlaylistStorageService.deleteXtreamConnection(name);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection deleted')),
        );
        _loadSavedContent();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete connection')),
        );
      }
    }
  }

  void _openM3UPlaylist(Map<String, dynamic> playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistViewScreen(
          title: playlist['name'] ?? 'Unnamed Playlist',
          url: playlist['url'] ?? '',
          filePath: playlist['filePath'],
          fileContent: playlist['fileContent'],
        ),
      ),
    ).then((_) => _loadSavedContent());
  }

  void _openXtreamConnection(Map<String, dynamic> connection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => XtreamCategoriesScreen(
          serverUrl: connection['serverUrl'],
          username: connection['username'],
          password: connection['password'],
          connectionName: connection['name'],
        ),
      ),
    ).then((_) => _loadSavedContent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IPTV and Movie App'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSavedContent,
            tooltip: 'Refresh',
          ),
        ],
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
                  'IPTV and Movie App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.movie),
              title: Text('Movies'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MoviesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.tv),
              title: Text('TV Shows'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TVShowsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.live_tv),
              title: Text('Live TV'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveTVScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.playlist_add),
              title: Text('Add M3U Playlist'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPlaylistScreen(),
                  ),
                ).then((_) => _loadSavedContent());
              },
            ),
            ListTile(
              leading: Icon(Icons.api),
              title: Text('Add Xtream Connection'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddXtreamScreen(),
                  ),
                ).then((_) => _loadSavedContent());
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSavedContent,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _m3uPlaylists.isEmpty && _xtreamConnections.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Welcome to IPTV and Movie App',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Add a playlist or Xtream connection to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddPlaylistScreen(),
                                    ),
                                  ).then((_) => _loadSavedContent());
                                },
                                icon: Icon(Icons.playlist_add),
                                label: Text('Add M3U Playlist'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddXtreamScreen(),
                                    ),
                                  ).then((_) => _loadSavedContent());
                                },
                                icon: Icon(Icons.api),
                                label: Text('Add Xtream'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Your Content',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.playlist_add),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AddPlaylistScreen(),
                                        ),
                                      ).then((_) => _loadSavedContent());
                                    },
                                    tooltip: 'Add M3U Playlist',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.api),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AddXtreamScreen(),
                                        ),
                                      ).then((_) => _loadSavedContent());
                                    },
                                    tooltip: 'Add Xtream Connection',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // M3U Playlists Section
                          if (_m3uPlaylists.isNotEmpty) ...[
                            Text(
                              'M3U Playlists',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _m3uPlaylists.length,
                              itemBuilder: (context, index) {
                                final playlist = _m3uPlaylists[index];
                                return Card(
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Icon(Icons.playlist_play),
                                    title: Text(
                                        playlist['name'] ?? 'Unnamed Playlist'),
                                    subtitle: Text(playlist['url'] ?? ''),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () => _deleteM3UPlaylist(
                                              playlist['name']),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                    onTap: () => _openM3UPlaylist(playlist),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 24),
                          ],

                          // Xtream Connections Section
                          if (_xtreamConnections.isNotEmpty) ...[
                            Text(
                              'Xtream Connections',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _xtreamConnections.length,
                              itemBuilder: (context, index) {
                                final connection = _xtreamConnections[index];
                                return Card(
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Icon(Icons.connected_tv),
                                    title: Text(connection['name'] ??
                                        'Unnamed Connection'),
                                    subtitle:
                                        Text(connection['serverUrl'] ?? ''),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () =>
                                              _deleteXtreamConnection(
                                                  connection['name']),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                    onTap: () =>
                                        _openXtreamConnection(connection),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}

class MoviesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movies'),
      ),
      body: Center(
        child: Text('Movies Screen - Coming Soon'),
      ),
    );
  }
}

class TVShowsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TV Shows'),
      ),
      body: Center(
        child: Text('TV Shows Screen - Coming Soon'),
      ),
    );
  }
}

class LiveTVScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live TV'),
      ),
      body: Center(
        child: Text('Live TV Screen - Coming Soon'),
      ),
    );
  }
}
