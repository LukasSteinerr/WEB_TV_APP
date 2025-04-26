import 'package:flutter/material.dart';
import 'package:tvapp/services/tmdb_service.dart';
import 'package:tvapp/screens/xtream_vod_player_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> movie;
  final String serverUrl;
  final String username;
  final String password;
  final String? tmdbId;

  MovieDetailsScreen({
    required this.movie,
    required this.serverUrl,
    required this.username,
    required this.password,
    this.tmdbId,
  });

  @override
  _MovieDetailsScreenState createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _tmdbDetails;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTMDBDetails();
  }

  Future<void> _loadTMDBDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try to get TMDB details
      if (widget.tmdbId != null && widget.tmdbId!.isNotEmpty && widget.tmdbId != '0') {
        // Use TMDB ID if available
        _tmdbDetails = await TMDBService.getMovieById(widget.tmdbId!);
      } else {
        // Fall back to search by title and year
        final title = widget.movie['name'] ?? '';
        final year = widget.movie['year']?.toString();
        final searchResult = await TMDBService.searchMovie(title, year: year);
        
        if (searchResult != null) {
          // Get full details using the ID from search result
          _tmdbDetails = await TMDBService.getMovieById(searchResult['id'].toString());
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load movie details: $e';
        _isLoading = false;
      });
    }
  }

  void _playMovie() {
    final streamId = widget.movie['stream_id']?.toString() ?? '';
    final baseUrl = widget.serverUrl.endsWith('/')
        ? widget.serverUrl.substring(0, widget.serverUrl.length - 1)
        : widget.serverUrl;
    
    final streamUrl = '$baseUrl/movie/${widget.username}/${widget.password}/$streamId.mp4';
    final title = widget.movie['name'] ?? 'Unknown';
    
    // Use TMDB poster if available, otherwise fall back to stream icon
    String posterUrl = widget.movie['stream_icon'] ?? '';
    if (_tmdbDetails != null && _tmdbDetails!['poster_path'] != null) {
      posterUrl = TMDBService.getPosterUrl(_tmdbDetails!['poster_path']);
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => XtreamVodPlayerScreen(
          title: title,
          streamUrl: streamUrl,
          posterUrl: posterUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.movie['name'] ?? 'Unknown Movie';
    final year = widget.movie['year']?.toString() ?? '';
    final duration = widget.movie['duration'] ?? '';
    final rating = widget.movie['rating'] ?? '';
    
    // Get poster URL (either from TMDB or from stream_icon)
    String posterUrl = widget.movie['stream_icon'] ?? '';
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
          : CustomScrollView(
              slivers: [
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
                                    Icons.movie,
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
                                Icons.movie,
                                size: 50,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                                              Icons.movie,
                                              size: 50,
                                              color: Colors.white54,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Colors.grey.shade800,
                                        child: Icon(
                                          Icons.movie,
                                          size: 50,
                                          color: Colors.white54,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(width: 16),
                            // Movie info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (year.isNotEmpty)
                                    Text(
                                      'Year: $year',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  if (duration.isNotEmpty)
                                    Text(
                                      'Duration: $duration',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  if (rating.isNotEmpty)
                                    Text(
                                      'Rating: $rating',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  if (_tmdbDetails != null && _tmdbDetails!['vote_average'] != null)
                                    Text(
                                      'TMDB Rating: ${_tmdbDetails!['vote_average']}/10',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _playMovie,
                                    icon: Icon(Icons.play_arrow),
                                    label: Text('Play Movie'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
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
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
