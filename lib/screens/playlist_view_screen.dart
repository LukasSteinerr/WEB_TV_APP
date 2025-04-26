import 'package:flutter/material.dart';
import 'package:tvapp/m3u_nullsafe.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class PlaylistViewScreen extends StatefulWidget {
  final String title;
  final String url;
  final String? filePath;
  final String? fileContent;

  PlaylistViewScreen({
    required this.title,
    required this.url,
    this.filePath,
    this.fileContent,
  });

  @override
  _PlaylistViewScreenState createState() => _PlaylistViewScreenState();
}

class _PlaylistViewScreenState extends State<PlaylistViewScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<M3uGenericEntry> _channels = [];
  Set<String> _categories = {};
  String? _selectedCategory;

  // For video player
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isPlaying = false;
  String? _currentChannelTitle;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String content;

      // If we have file content directly
      if (widget.fileContent != null && widget.fileContent!.isNotEmpty) {
        content = widget.fileContent!;
      }
      // If it's a remote URL
      else if (widget.url.isNotEmpty) {
        final response = await http.get(Uri.parse(widget.url));
        if (response.statusCode != 200) {
          throw Exception(
              'Failed to load playlist: HTTP ${response.statusCode}');
        }
        content = response.body;
      } else {
        throw Exception('No content or URL provided');
      }

      // Parse the M3U content
      final channels = await parseFile(content);

      // Extract categories
      final categories = <String>{};
      for (var channel in channels) {
        final category = channel.attributes['group-title'];
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      setState(() {
        _channels = channels;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load playlist: $e';
        _isLoading = false;
      });
    }
  }

  List<M3uGenericEntry> _getFilteredChannels() {
    if (_selectedCategory == null) {
      return _channels;
    }

    return _channels.where((channel) {
      return channel.attributes['group-title'] == _selectedCategory;
    }).toList();
  }

  Future<void> _playChannel(M3uGenericEntry channel) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Dispose previous controllers
      _videoController?.dispose();
      _chewieController?.dispose();

      // Create new controllers
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(channel.link));

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error: $errorMessage',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );

      setState(() {
        _isPlaying = true;
        _currentChannelTitle = channel.title;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to play channel: $e';
        _isPlaying = false;
        _isLoading = false;
      });
    }
  }

  void _stopPlayback() {
    setState(() {
      _videoController?.pause();
      _isPlaying = false;
      _currentChannelTitle = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredChannels = _getFilteredChannels();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPlaylist,
            tooltip: 'Reload Playlist',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(8.0),
                    margin: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),

                // Video player
                if (_isPlaying && _chewieController != null)
                  Container(
                    height: 240,
                    child: Column(
                      children: [
                        Expanded(
                          child: Chewie(controller: _chewieController!),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _currentChannelTitle ?? 'Unknown Channel',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: _stopPlayback,
                                tooltip: 'Stop Playback',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Category filter
                if (_categories.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      hint: Text('All Categories'),
                      value: _selectedCategory,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ..._categories.map((category) {
                          return DropdownMenuItem<String?>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                // Channel list
                Expanded(
                  child: filteredChannels.isEmpty
                      ? Center(
                          child: Text('No channels found'),
                        )
                      : ListView.builder(
                          itemCount: filteredChannels.length,
                          itemBuilder: (context, index) {
                            final channel = filteredChannels[index];
                            final logoUrl = channel.attributes['tvg-logo'];

                            return ListTile(
                              leading: logoUrl != null && logoUrl.isNotEmpty
                                  ? Image.network(
                                      logoUrl,
                                      width: 40,
                                      height: 40,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(Icons.tv);
                                      },
                                    )
                                  : Icon(Icons.tv),
                              title: Text(channel.title),
                              subtitle:
                                  channel.attributes['group-title'] != null
                                      ? Text(channel.attributes['group-title']!)
                                      : null,
                              onTap: () => _playChannel(channel),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
