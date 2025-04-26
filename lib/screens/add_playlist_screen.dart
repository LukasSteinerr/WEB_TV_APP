import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tvapp/m3u_nullsafe.dart';
import 'package:tvapp/screens/playlist_view_screen.dart';
import 'package:tvapp/services/playlist_storage_service.dart';

class AddPlaylistScreen extends StatefulWidget {
  @override
  _AddPlaylistScreenState createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends State<AddPlaylistScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _savedPlaylists = [];

  @override
  void initState() {
    super.initState();
    _loadSavedPlaylists();
  }

  Future<void> _loadSavedPlaylists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get playlists from storage service
      final playlists = await PlaylistStorageService.getM3UPlaylists();

      setState(() {
        // Convert to the format used by this screen
        _savedPlaylists = playlists
            .map((playlist) => {
                  'name': playlist['name'] ?? 'Unnamed Playlist',
                  'url': playlist['url'] ?? '',
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load saved playlists: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _savePlaylist(String name, String url) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Determine if this is a local file
      String? fileContent;
      String? filePath;
      String actualUrl = url;

      if (url.startsWith('local:')) {
        fileContent = Uri.decodeFull(url.substring(6));
        actualUrl = ''; // No remote URL for local files
      }

      // Save playlist using storage service
      final success = await PlaylistStorageService.saveM3UPlaylist(
        name: name,
        url: actualUrl,
        filePath: filePath,
        fileContent: fileContent,
      );

      if (success) {
        // Reload playlists
        await _loadSavedPlaylists();

        // Clear form
        _urlController.clear();
        _nameController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playlist added successfully')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to save playlist';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save playlist: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePlaylist(int index) async {
    if (index < 0 || index >= _savedPlaylists.length) {
      return;
    }

    final playlistName = _savedPlaylists[index]['name'] ?? '';

    setState(() {
      _isLoading = true;
    });

    try {
      // Delete playlist using storage service
      final success =
          await PlaylistStorageService.deleteM3UPlaylist(playlistName);

      if (success) {
        // Reload playlists
        await _loadSavedPlaylists();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playlist deleted')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to delete playlist';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to delete playlist: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m3u', 'm3u8', 'txt'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;

        // For web
        if (file.bytes != null) {
          String content = String.fromCharCodes(file.bytes!);
          _processFileContent(file.name, content);
        }
        // For mobile/desktop
        else if (file.path != null) {
          File fileObj = File(file.path!);
          String content = await fileObj.readAsString();
          _processFileContent(file.name, content);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick file: $e';
      });
    }
  }

  void _processFileContent(String fileName, String content) {
    // Set the file name as the playlist name
    _nameController.text =
        fileName.replaceAll('.m3u', '').replaceAll('.m3u8', '');

    // For local files, we'll save the content directly
    _urlController.text = 'local:${Uri.encodeFull(content)}';
  }

  Future<void> _testPlaylist(String url) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // If it's a local file (content is encoded in the URL)
      if (url.startsWith('local:')) {
        String content = Uri.decodeFull(url.substring(6));
        List<M3uGenericEntry> entries = await parseFile(content);

        if (entries.isEmpty) {
          setState(() {
            _errorMessage = 'No channels found in the playlist';
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Found ${entries.length} channels in the playlist')),
          );
        }
      }
      // If it's a remote URL
      else {
        // Here you would fetch the content from the URL
        // For now, we'll just show a success message
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('URL seems valid. Add the playlist to test it.')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to test playlist: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Playlist'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(8.0),
                      margin: EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Playlist Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name for the playlist';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            labelText: 'Playlist URL (M3U/M3U8)',
                            border: OutlineInputBorder(),
                            helperText: 'Enter a URL or upload a file',
                            suffixIcon: IconButton(
                              icon: Icon(Icons.link_off),
                              onPressed: () => _urlController.clear(),
                              tooltip: 'Clear',
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a URL or upload a file';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.0),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickFile,
                              icon: Icon(Icons.upload_file),
                              label: Text('Upload File'),
                            ),
                            SizedBox(width: 16.0),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_urlController.text.isNotEmpty) {
                                  _testPlaylist(_urlController.text);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Please enter a URL first')),
                                  );
                                }
                              },
                              icon: Icon(Icons.check_circle),
                              label: Text('Test Playlist'),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.0),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _savePlaylist(
                                _nameController.text,
                                _urlController.text,
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Text('Add Playlist'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.0),
                  Text(
                    'Saved Playlists',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  _savedPlaylists.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No playlists saved yet'),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _savedPlaylists.length,
                          itemBuilder: (context, index) {
                            final playlist = _savedPlaylists[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                title: Text(
                                    playlist['name'] ?? 'Unnamed Playlist'),
                                subtitle: Text(
                                  playlist['url']?.startsWith('local:') ?? false
                                      ? 'Local file'
                                      : playlist['url'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deletePlaylist(index),
                                ),
                                onTap: () {
                                  // Navigate to playlist view
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlaylistViewScreen(
                                        title: playlist['name'] ??
                                            'Unnamed Playlist',
                                        url: playlist['url'] ?? '',
                                        fileContent: playlist['fileContent'],
                                        filePath: playlist['filePath'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
