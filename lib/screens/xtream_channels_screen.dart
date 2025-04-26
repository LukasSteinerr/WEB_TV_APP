import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:tvapp/screens/xtream_vod_player_screen.dart';
import 'package:tvapp/services/tmdb_service.dart';
import 'package:tvapp/screens/movie_details_screen.dart';
import 'package:tvapp/screens/series_details_screen.dart';

class XtreamChannelsScreen extends StatefulWidget {
  final String categoryName;
  final String categoryId;
  final String serverUrl;
  final String username;
  final String password;
  final String type; // 'live', 'vod', or 'series'

  XtreamChannelsScreen({
    required this.categoryName,
    required this.categoryId,
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.type,
  });

  @override
  _XtreamChannelsScreenState createState() => _XtreamChannelsScreenState();
}

class _XtreamChannelsScreenState extends State<XtreamChannelsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _channels = [];

  // Cache for TMDB image URLs
  Map<String, String> _tmdbImageCache = {};

  // For video player (live TV)
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isPlaying = false;
  String? _currentChannelName;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final baseUrl = widget.serverUrl.endsWith('/')
          ? widget.serverUrl.substring(0, widget.serverUrl.length - 1)
          : widget.serverUrl;

      String url;

      // Construct URL based on content type
      if (widget.type == 'live') {
        url =
            '$baseUrl/player_api.php?username=${widget.username}&password=${widget.password}&action=get_live_streams&category_id=${widget.categoryId}';
      } else if (widget.type == 'vod') {
        url =
            '$baseUrl/player_api.php?username=${widget.username}&password=${widget.password}&action=get_vod_streams&category_id=${widget.categoryId}';
      } else if (widget.type == 'series') {
        url =
            '$baseUrl/player_api.php?username=${widget.username}&password=${widget.password}&action=get_series&category_id=${widget.categoryId}';
      } else {
        throw Exception('Invalid content type: ${widget.type}');
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to load channels: HTTP ${response.statusCode}');
      }

      setState(() {
        _channels = List<Map<String, dynamic>>.from(json.decode(response.body));

        // Debug log to check for TMDB IDs in the first few items
        if (_channels.isNotEmpty) {
          final sampleItem = _channels.first;
          print(
              'Sample ${widget.type} item structure: ${sampleItem.keys.join(', ')}');

          if (sampleItem.containsKey('tmdb_id')) {
            print(
                'TMDB ID found in ${widget.type} item: ${sampleItem['tmdb_id']}');
          } else {
            print('No TMDB ID found in ${widget.type} item');
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load channels: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _playLiveChannel(Map<String, dynamic> channel) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Dispose previous controllers
      _videoController?.dispose();
      _chewieController?.dispose();

      final baseUrl = widget.serverUrl.endsWith('/')
          ? widget.serverUrl.substring(0, widget.serverUrl.length - 1)
          : widget.serverUrl;

      final streamId = channel['stream_id']?.toString() ?? '';
      final streamUrl =
          '$baseUrl/live/${widget.username}/${widget.password}/$streamId.ts';

      // Create new controllers
      _videoController = VideoPlayerController.networkUrl(Uri.parse(streamUrl));

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
        _currentChannelName = channel['name'] ?? 'Unknown';
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

  void _playVodContent(Map<String, dynamic> content) {
    // Instead of playing directly, navigate to the movie details screen
    final tmdbId = content['tmdb_id']?.toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(
          movie: content,
          serverUrl: widget.serverUrl,
          username: widget.username,
          password: widget.password,
          tmdbId: tmdbId,
        ),
      ),
    );
  }

  void _viewSeriesDetails(Map<String, dynamic> series) {
    // Navigate to the series details screen
    final tmdbId = series['tmdb_id']?.toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeriesDetailsScreen(
          series: series,
          serverUrl: widget.serverUrl,
          username: widget.username,
          password: widget.password,
          tmdbId: tmdbId,
        ),
      ),
    );
  }

  // This is the old implementation that we're replacing
  void _oldViewSeriesDetails(Map<String, dynamic> series) {
    final baseUrl = widget.serverUrl.endsWith('/')
        ? widget.serverUrl.substring(0, widget.serverUrl.length - 1)
        : widget.serverUrl;

    final seriesId = series['series_id']?.toString() ?? '';
    final seriesName = series['name'] ?? 'Unknown Series';

    // Try multiple possible fields for series posters
    String posterUrl =
        series['cover'] ?? series['poster'] ?? series['stream_icon'] ?? '';

    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading series details...'),
          ],
        ),
      ),
    );

    // Fetch series info from Xtream API
    final infoUrl =
        '$baseUrl/player_api.php?username=${widget.username}&password=${widget.password}&action=get_series_info&series_id=$seriesId';

    // Check if we have a TMDB ID directly in the series data
    final tmdbId = series['tmdb_id']?.toString();

    // Use TMDB ID if available, otherwise fall back to search by name
    final tmdbFuture = tmdbId != null && tmdbId.isNotEmpty && tmdbId != '0'
        ? TMDBService.getTVShowById(tmdbId)
        : TMDBService.searchTVShow(seriesName);

    Future.wait([
      http.get(Uri.parse(infoUrl)),
      tmdbFuture,
    ]).then((results) {
      // Dismiss the loading dialog
      Navigator.pop(context);

      final response = results[0] as http.Response;
      final tmdbInfo = results[1] as Map<String, dynamic>?;

      if (response.statusCode != 200) {
        _showErrorDialog(
            'Failed to load series details: HTTP ${response.statusCode}');
        return;
      }

      try {
        final seriesInfo = json.decode(response.body);
        final info = seriesInfo['info'] ?? {};
        final episodes = seriesInfo['episodes'] ?? {};

        // Debug log to see if there's a TMDB ID in the series info
        if (info.containsKey('tmdb_id')) {
          print('Series info contains TMDB ID: ${info['tmdb_id']}');
        } else {
          print(
              'Series info does not contain TMDB ID. Available keys: ${info.keys.join(', ')}');
        }

        // If we have TMDB info, use it to enhance our data
        String? plot = info['plot'];
        String? genre = info['genre'];
        String? releaseDate = info['releaseDate'];
        String? rating = info['rating'];

        // If we have a TMDB poster, use it instead
        if (tmdbInfo != null && tmdbInfo['poster_path'] != null) {
          posterUrl = TMDBService.getPosterUrl(tmdbInfo['poster_path']);
        }

        // Use TMDB data if available and Xtream data is missing
        if (tmdbInfo != null) {
          if (plot == null || plot.isEmpty) {
            plot = tmdbInfo['overview'];
          }

          if (genre == null || genre.isEmpty) {
            if (tmdbInfo['genres'] != null &&
                (tmdbInfo['genres'] as List).isNotEmpty) {
              genre =
                  (tmdbInfo['genres'] as List).map((g) => g['name']).join(', ');
            }
          }

          if (releaseDate == null || releaseDate.isEmpty) {
            releaseDate = tmdbInfo['first_air_date'];
          }

          if (rating == null || rating.isEmpty) {
            rating = tmdbInfo['vote_average']?.toString();
          }
        }

        // Show series details dialog with more information
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(seriesName),
            content: Container(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (posterUrl.isNotEmpty)
                      Center(
                        child: Container(
                          height: 200,
                          child: Image.network(
                            posterUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.video_library, size: 100);
                            },
                          ),
                        ),
                      ),
                    SizedBox(height: 16),
                    if (plot != null && plot.isNotEmpty)
                      Text(
                        plot,
                        style: TextStyle(fontSize: 14),
                      ),
                    SizedBox(height: 8),
                    if (genre != null && genre.isNotEmpty)
                      Text(
                        'Genre: $genre',
                        style: TextStyle(
                            fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    if (releaseDate != null && releaseDate.isNotEmpty)
                      Text(
                        'Released: $releaseDate',
                        style: TextStyle(fontSize: 12),
                      ),
                    if (rating != null && rating.isNotEmpty)
                      Text(
                        'Rating: $rating',
                        style: TextStyle(fontSize: 12),
                      ),
                    if (tmdbInfo != null &&
                        tmdbInfo['number_of_seasons'] != null)
                      Text(
                        'Seasons: ${tmdbInfo['number_of_seasons']}',
                        style: TextStyle(fontSize: 12),
                      ),
                    SizedBox(height: 16),
                    Text(
                      'This series has ${episodes.length} seasons with episodes.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'To watch episodes, a full series browser would be implemented.',
                      style:
                          TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        );
      } catch (e) {
        _showErrorDialog('Failed to parse series details: $e');
      }
    }).catchError((error) {
      // Dismiss the loading dialog
      Navigator.pop(context);
      _showErrorDialog('Failed to load series details: $error');
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _stopPlayback() {
    setState(() {
      _videoController?.pause();
      _isPlaying = false;
      _currentChannelName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadChannels,
            tooltip: 'Reload',
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

                // Video player for live TV
                if (_isPlaying &&
                    _chewieController != null &&
                    widget.type == 'live')
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
                                  _currentChannelName ?? 'Unknown Channel',
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

                // Channel list
                Expanded(
                  child: _channels.isEmpty
                      ? Center(
                          child: Text('No content found in this category'),
                        )
                      : ListView.builder(
                          itemCount: _channels.length,
                          itemBuilder: (context, index) {
                            final item = _channels[index];
                            final name = item['name'] ?? 'Unknown';

                            // Try different image URL fields based on content type
                            String? imageUrl;
                            if (widget.type == 'live') {
                              imageUrl = item['stream_icon'] ?? '';
                            } else if (widget.type == 'vod') {
                              // Try multiple possible fields for movie posters
                              imageUrl = item['stream_icon'] ??
                                  item['cover'] ??
                                  item['movie_image'] ??
                                  item['poster'] ??
                                  '';
                            } else if (widget.type == 'series') {
                              // Try multiple possible fields for series posters
                              imageUrl = item['cover'] ??
                                  item['poster'] ??
                                  item['stream_icon'] ??
                                  '';
                            }

                            // Check if we already have a TMDB image for this item
                            final String itemKey =
                                '${widget.type}_${item['id'] ?? item['stream_id'] ?? index}';
                            final String? cachedTmdbUrl =
                                _tmdbImageCache[itemKey];

                            return ListTile(
                              leading: FutureBuilder<String?>(
                                // If we have a cached TMDB URL, use it immediately
                                future: cachedTmdbUrl != null
                                    ? Future.value(cachedTmdbUrl)
                                    : _getImageUrl(
                                        item, name, imageUrl, itemKey),
                                builder: (context, snapshot) {
                                  // While loading TMDB data, show the original image if available
                                  if (!snapshot.hasData &&
                                      imageUrl != null &&
                                      imageUrl.isNotEmpty) {
                                    return _buildImageContainer(
                                      imageUrl: imageUrl,
                                      name: name,
                                      showFallbackIcon: true,
                                    );
                                  }

                                  // If we have a TMDB image, use it
                                  if (snapshot.hasData &&
                                      snapshot.data != null &&
                                      snapshot.data!.isNotEmpty) {
                                    return _buildImageContainer(
                                      imageUrl: snapshot.data!,
                                      name: name,
                                      showFallbackIcon: true,
                                    );
                                  }

                                  // Fallback to default icon
                                  return Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade800,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(child: _getDefaultIcon()),
                                  );
                                },
                              ),
                              title: Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle:
                                  widget.type == 'vod' && item['year'] != null
                                      ? Text('${item['year']}')
                                      : null,
                              onTap: () {
                                if (widget.type == 'live') {
                                  _playLiveChannel(item);
                                } else if (widget.type == 'vod') {
                                  _playVodContent(item);
                                } else if (widget.type == 'series') {
                                  _viewSeriesDetails(item);
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _getDefaultIcon() {
    if (widget.type == 'live') {
      return Icon(Icons.tv);
    } else if (widget.type == 'vod') {
      return Icon(Icons.movie);
    } else {
      return Icon(Icons.video_library);
    }
  }

  // Helper method to build an image container
  Widget _buildImageContainer({
    required String? imageUrl,
    required String name,
    bool showFallbackIcon = true,
  }) {
    // If no image URL is provided, show the default icon
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(child: _getDefaultIcon()),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading image for $name: $error');
            return Container(
              color: Colors.grey.shade800,
              child: Center(child: _getDefaultIcon()),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper method to get an image URL, with TMDB fallback
  Future<String?> _getImageUrl(
    Map<String, dynamic> item,
    String name,
    String? originalUrl,
    String cacheKey,
  ) async {
    // Check if we already have a cached TMDB URL for this item
    if (_tmdbImageCache.containsKey(cacheKey)) {
      return _tmdbImageCache[cacheKey];
    }

    // Always try TMDB first since the Xtream images are failing
    try {
      if (widget.type == 'vod') {
        // Check if we have a TMDB ID directly in the item
        final tmdbId = item['tmdb_id']?.toString();

        if (tmdbId != null && tmdbId.isNotEmpty && tmdbId != '0') {
          print('Found TMDB ID in VOD item: $tmdbId for $name');

          // Get movie details directly by ID
          final movie = await TMDBService.getMovieById(tmdbId);

          if (movie != null && movie['poster_path'] != null) {
            final tmdbUrl = TMDBService.getPosterUrl(movie['poster_path']);
            // Cache the URL for future use
            _tmdbImageCache[cacheKey] = tmdbUrl;
            print('Found TMDB image by ID for movie: $name - $tmdbUrl');
            return tmdbUrl;
          }
        } else {
          // Fallback to search by title and year if no TMDB ID
          print('No TMDB ID found for $name, falling back to search');
          final year = item['year']?.toString();
          final movie = await TMDBService.searchMovie(name, year: year);

          if (movie != null && movie['poster_path'] != null) {
            final tmdbUrl = TMDBService.getPosterUrl(movie['poster_path']);
            // Cache the URL for future use
            _tmdbImageCache[cacheKey] = tmdbUrl;
            print('Found TMDB image by search for movie: $name - $tmdbUrl');
            return tmdbUrl;
          }
        }
      } else if (widget.type == 'series') {
        // Check if we have a TMDB ID directly in the item
        final tmdbId = item['tmdb_id']?.toString();

        if (tmdbId != null && tmdbId.isNotEmpty && tmdbId != '0') {
          print('Found TMDB ID in series item: $tmdbId for $name');

          // Get TV show details directly by ID
          final tvShow = await TMDBService.getTVShowById(tmdbId);

          if (tvShow != null && tvShow['poster_path'] != null) {
            final tmdbUrl = TMDBService.getPosterUrl(tvShow['poster_path']);
            // Cache the URL for future use
            _tmdbImageCache[cacheKey] = tmdbUrl;
            print('Found TMDB image by ID for series: $name - $tmdbUrl');
            return tmdbUrl;
          }
        } else {
          // Fallback to search by title if no TMDB ID
          print('No TMDB ID found for $name, falling back to search');
          final tvShow = await TMDBService.searchTVShow(name);

          if (tvShow != null && tvShow['poster_path'] != null) {
            final tmdbUrl = TMDBService.getPosterUrl(tvShow['poster_path']);
            // Cache the URL for future use
            _tmdbImageCache[cacheKey] = tmdbUrl;
            print('Found TMDB image by search for series: $name - $tmdbUrl');
            return tmdbUrl;
          }
        }
      }
    } catch (e) {
      print('Error fetching TMDB image: $e');
    }

    // If TMDB fails and we have an original URL, try to use it as a last resort
    if (originalUrl != null && originalUrl.isNotEmpty) {
      // Don't try to validate the URL, just return it and let the Image widget handle errors
      return originalUrl;
    }

    // If all else fails, return null to show the default icon
    return null;
  }
}
