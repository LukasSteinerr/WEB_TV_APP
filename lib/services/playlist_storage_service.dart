import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlaylistStorageService {
  static const String _m3uPlaylistsKey = 'saved_m3u_playlists';
  static const String _xtreamConnectionsKey = 'saved_xtream_connections';

  // Save an M3U playlist
  static Future<bool> saveM3UPlaylist({
    required String name,
    required String url,
    String? filePath,
    String? fileContent,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing playlists
      final List<String> playlistsJson = prefs.getStringList(_m3uPlaylistsKey) ?? [];
      final List<Map<String, dynamic>> playlists = playlistsJson
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList();
      
      // Check if a playlist with this name already exists
      final existingIndex = playlists.indexWhere((p) => p['name'] == name);
      
      // Create the playlist data
      final playlistData = {
        'name': name,
        'url': url,
        'filePath': filePath,
        'fileContent': fileContent,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Update or add the playlist
      if (existingIndex >= 0) {
        playlists[existingIndex] = playlistData;
      } else {
        playlists.add(playlistData);
      }
      
      // Save back to shared preferences
      final updatedPlaylistsJson = playlists
          .map((playlist) => jsonEncode(playlist))
          .toList();
      
      return await prefs.setStringList(_m3uPlaylistsKey, updatedPlaylistsJson);
    } catch (e) {
      print('Error saving M3U playlist: $e');
      return false;
    }
  }

  // Get all saved M3U playlists
  static Future<List<Map<String, dynamic>>> getM3UPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing playlists
      final List<String> playlistsJson = prefs.getStringList(_m3uPlaylistsKey) ?? [];
      
      // Convert to list of maps
      final List<Map<String, dynamic>> playlists = playlistsJson
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList();
      
      // Sort by timestamp (newest first)
      playlists.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      
      return playlists;
    } catch (e) {
      print('Error getting M3U playlists: $e');
      return [];
    }
  }

  // Delete an M3U playlist by name
  static Future<bool> deleteM3UPlaylist(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing playlists
      final List<String> playlistsJson = prefs.getStringList(_m3uPlaylistsKey) ?? [];
      final List<Map<String, dynamic>> playlists = playlistsJson
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList();
      
      // Remove the playlist with the given name
      playlists.removeWhere((p) => p['name'] == name);
      
      // Save back to shared preferences
      final updatedPlaylistsJson = playlists
          .map((playlist) => jsonEncode(playlist))
          .toList();
      
      return await prefs.setStringList(_m3uPlaylistsKey, updatedPlaylistsJson);
    } catch (e) {
      print('Error deleting M3U playlist: $e');
      return false;
    }
  }

  // Save an Xtream connection
  static Future<bool> saveXtreamConnection({
    required String name,
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing connections
      final List<String> connectionsJson = prefs.getStringList(_xtreamConnectionsKey) ?? [];
      final List<Map<String, dynamic>> connections = connectionsJson
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList();
      
      // Check if a connection with this name already exists
      final existingIndex = connections.indexWhere((c) => c['name'] == name);
      
      // Create the connection data
      final connectionData = {
        'name': name,
        'serverUrl': serverUrl,
        'username': username,
        'password': password,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Update or add the connection
      if (existingIndex >= 0) {
        connections[existingIndex] = connectionData;
      } else {
        connections.add(connectionData);
      }
      
      // Save back to shared preferences
      final updatedConnectionsJson = connections
          .map((connection) => jsonEncode(connection))
          .toList();
      
      return await prefs.setStringList(_xtreamConnectionsKey, updatedConnectionsJson);
    } catch (e) {
      print('Error saving Xtream connection: $e');
      return false;
    }
  }

  // Get all saved Xtream connections
  static Future<List<Map<String, dynamic>>> getXtreamConnections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing connections
      final List<String> connectionsJson = prefs.getStringList(_xtreamConnectionsKey) ?? [];
      
      // Convert to list of maps
      final List<Map<String, dynamic>> connections = connectionsJson
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList();
      
      // Sort by timestamp (newest first)
      connections.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      
      return connections;
    } catch (e) {
      print('Error getting Xtream connections: $e');
      return [];
    }
  }

  // Delete an Xtream connection by name
  static Future<bool> deleteXtreamConnection(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing connections
      final List<String> connectionsJson = prefs.getStringList(_xtreamConnectionsKey) ?? [];
      final List<Map<String, dynamic>> connections = connectionsJson
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList();
      
      // Remove the connection with the given name
      connections.removeWhere((c) => c['name'] == name);
      
      // Save back to shared preferences
      final updatedConnectionsJson = connections
          .map((connection) => jsonEncode(connection))
          .toList();
      
      return await prefs.setStringList(_xtreamConnectionsKey, updatedConnectionsJson);
    } catch (e) {
      print('Error deleting Xtream connection: $e');
      return false;
    }
  }
}
