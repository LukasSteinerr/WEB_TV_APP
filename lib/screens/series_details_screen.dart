import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tvapp/services/tmdb_service.dart';

class SeriesDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> series;
  final String serverUrl;
  final String username;
  final String password;
  final String? tmdbId;

  SeriesDetailsScreen({
    required this.series,
    required this.serverUrl,
    required this.username,
    required this.password,
    this.tmdbId,
  });

  @override
  _SeriesDetailsScreenState createState() => _SeriesDetailsScreenState();
}

class _SeriesDetailsScreenState extends State<SeriesDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _tmdbDetails;
  Map<String, dynamic>? _seriesInfo;
  Map<String, dynamic>? _episodes;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load series info from Xtream API
      final baseUrl = widget.serverUrl.endsWith('/')
          ? widget.serverUrl.substring(0, widget.serverUrl.length - 1)
          : widget.serverUrl;
      
      final seriesId = widget.series['series_id']?.toString() ?? '';
      final infoUrl = '$baseUrl/player_api.php?username=${widget.username}&password=${widget.password}&action=get_series_info&series_id=$seriesId';
      
      // Try to get TMDB details
      final tmdbFuture = widget.tmdbId != null && widget.tmdbId!.isNotEmpty && widget.tmdbId != '0'
          ? TMDBService.getTVShowById(widget.tmdbId!)
          : TMDBService.searchTVShow(widget.series['name'] ?? '');
      
      // Wait for both API calls to complete
      final results = await Future.wait([
        http.get(Uri.parse(infoUrl)),
        tmdbFuture,
      ]);
      
      final response = results[0] as http.Response;
      _tmdbDetails = results[1] as Map<String, dynamic>?;
      
      if (response.statusCode == 200) {
        final seriesData = json.decode(response.body);
        _seriesInfo = seriesData['info'] ?? {};
        _episodes = seriesData['episodes'] ?? {};
      } else {
        throw Exception('Failed to load series info: HTTP ${response.statusCode}');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load series details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.series['name'] ?? 'Unknown Series';
    
    // Get poster URL (either from TMDB or from stream_icon)
    String posterUrl = widget.series['cover'] ?? 
                      widget.series['poster'] ?? 
                      widget.series['stream_icon'] ?? '';
    if (_tmdbDetails != null && _tmdbDetails!['poster_path'] != null) {
      posterUrl = TMDBService.getPosterUrl(_tmdbDetails!['poster_path']);
    }
    
    // Get backdrop URL from TMDB
    String? backdropUrl;
    if (_tmdbDetails != null && _tmdbDetails!['backdrop_path'] != null) {
      backdropUrl = TMDBService.getBackdropUrl(_tmdbDetails!['backdrop_path']);
    }
    
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                          onPressed: _loadDetails,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight: 200.0,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          title: Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black,
                                  offset: Offset(0.0, 0.0),
                                ),
                              ],
                            ),
                          ),
                          background: backdropUrl != null
                              ? Image.network(
                                  backdropUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade900,
                                      child: Center(
                                        child: Icon(
                                          Icons.video_library,
                                          size: 50,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey.shade900,
                                  child: Center(
                                    child: Icon(
                                      Icons.video_library,
                                      size: 50,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                        ),
                        bottom: TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(text: 'Info'),
                            Tab(text: 'Episodes'),
                          ],
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      // Info Tab
                      SingleChildScrollView(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Poster
                                Container(
                                  width: 120,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: posterUrl.isNotEmpty
                                        ? Image.network(
                                            posterUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey.shade800,
                                                child: Icon(
                                                  Icons.video_library,
                                                  size: 50,
                                                  color: Colors.white54,
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: Colors.grey.shade800,
                                            child: Icon(
                                              Icons.video_library,
                                              size: 50,
                                              color: Colors.white54,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                // Series info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_seriesInfo != null && _seriesInfo!['releaseDate'] != null)
                                        Text(
                                          'Released: ${_seriesInfo!['releaseDate']}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      if (_seriesInfo != null && _seriesInfo!['rating'] != null)
                                        Text(
                                          'Rating: ${_seriesInfo!['rating']}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      if (_tmdbDetails != null && _tmdbDetails!['vote_average'] != null)
                                        Text(
                                          'TMDB Rating: ${_tmdbDetails!['vote_average']}/10',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      if (_tmdbDetails != null && _tmdbDetails!['number_of_seasons'] != null)
                                        Text(
                                          'Seasons: ${_tmdbDetails!['number_of_seasons']}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      if (_episodes != null)
                                        Text(
                                          'Available Seasons: ${_episodes!.keys.length}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            // Overview
                            if (_tmdbDetails != null && _tmdbDetails!['overview'] != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Overview',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _tmdbDetails!['overview'],
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              )
                            else if (_seriesInfo != null && _seriesInfo!['plot'] != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Plot',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _seriesInfo!['plot'],
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            SizedBox(height: 16),
                            // Genres
                            if (_tmdbDetails != null && _tmdbDetails!['genres'] != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Genres',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: (_tmdbDetails!['genres'] as List)
                                        .map((genre) => Chip(
                                              label: Text(genre['name']),
                                              backgroundColor: Colors.deepOrange.withOpacity(0.2),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              )
                            else if (_seriesInfo != null && _seriesInfo!['genre'] != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Genre',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _seriesInfo!['genre'],
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      
                      // Episodes Tab
                      _episodes == null || _episodes!.isEmpty
                          ? Center(child: Text('No episodes available'))
                          : ListView.builder(
                              itemCount: _episodes!.length,
                              itemBuilder: (context, index) {
                                final seasonNumber = _episodes!.keys.elementAt(index);
                                final seasonEpisodes = _episodes![seasonNumber] as List;
                                
                                return ExpansionTile(
                                  title: Text('Season $seasonNumber'),
                                  children: [
                                    ...seasonEpisodes.map((episode) {
                                      final episodeNum = episode['episode_num'];
                                      final episodeTitle = episode['title'] ?? 'Episode $episodeNum';
                                      final episodeInfo = episode['info'] ?? {};
                                      final episodePlot = episodeInfo['plot'] ?? '';
                                      final episodeDuration = episodeInfo['duration'] ?? '';
                                      
                                      return ListTile(
                                        title: Text('$episodeNum. $episodeTitle'),
                                        subtitle: episodePlot.isNotEmpty
                                            ? Text(
                                                episodePlot,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              )
                                            : null,
                                        trailing: episodeDuration.isNotEmpty
                                            ? Text(episodeDuration)
                                            : null,
                                        onTap: () {
                                          // Show episode details or play episode
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Play episode functionality would be implemented here'),
                                            ),
                                          );
                                        },
                                      );
                                    }).toList(),
                                  ],
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}
