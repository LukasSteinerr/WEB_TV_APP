import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tvapp/config.dart';

class TMDBService {
  // Get TMDB API key from config file
  static final String apiKey = "9e92699e050cb40728b59728c3115455";
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  // Search for a movie by title
  static Future<Map<String, dynamic>?> searchMovie(String title,
      {String? year}) async {
    try {
      // Clean up the title by removing any non-alphanumeric characters
      final cleanTitle = _cleanTitle(title);

      // Build the query URL
      String url = '$baseUrl/search/movie?api_key=$apiKey&query=$cleanTitle';

      // Add year parameter if provided
      if (year != null && year.isNotEmpty) {
        url += '&year=$year';
      }

      print(
          'Searching TMDB for movie: $title (cleaned: $cleanTitle), year: $year');

      // Make the request
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          // If we have multiple results, try to find the best match
          if (results.length > 1 && year != null && year.isNotEmpty) {
            // Try to find a movie with the matching year first
            for (var movie in results) {
              final releaseDate = movie['release_date'] as String?;
              if (releaseDate != null && releaseDate.startsWith(year)) {
                print(
                    'Found exact year match for $title: ${movie['title']} (${movie['release_date']})');
                return movie;
              }
            }
          }

          // If no exact year match or no year provided, return the first result
          final firstResult = results.first;
          print(
              'Using first TMDB result for $title: ${firstResult['title']} (${firstResult['release_date']})');
          return firstResult;
        } else {
          print('No TMDB results found for movie: $title');
        }
      } else {
        print('TMDB API error: ${response.statusCode} - ${response.body}');
      }

      return null;
    } catch (e) {
      print('Error searching for movie: $e');
      return null;
    }
  }

  // Search for a TV show by title
  static Future<Map<String, dynamic>?> searchTVShow(String title) async {
    try {
      // Clean up the title by removing any non-alphanumeric characters
      final cleanTitle = _cleanTitle(title);

      // Build the query URL
      final url = '$baseUrl/search/tv?api_key=$apiKey&query=$cleanTitle';

      print('Searching TMDB for TV show: $title (cleaned: $cleanTitle)');

      // Make the request
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          // Return the first result
          final firstResult = results.first;
          print(
              'Using first TMDB result for $title: ${firstResult['name']} (${firstResult['first_air_date']})');
          return firstResult;
        } else {
          print('No TMDB results found for TV show: $title');
        }
      } else {
        print('TMDB API error: ${response.statusCode} - ${response.body}');
      }

      return null;
    } catch (e) {
      print('Error searching for TV show: $e');
      return null;
    }
  }

  // Get movie details directly by TMDB ID
  static Future<Map<String, dynamic>?> getMovieById(String tmdbId) async {
    try {
      print('Getting movie details by TMDB ID: $tmdbId');

      // Build the query URL for direct movie lookup
      final url = '$baseUrl/movie/$tmdbId?api_key=$apiKey';

      // Make the request
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Successfully retrieved movie details for TMDB ID: $tmdbId');
        return data;
      } else {
        print(
            'TMDB API error for movie ID $tmdbId: ${response.statusCode} - ${response.body}');
      }

      return null;
    } catch (e) {
      print('Error getting movie by ID: $e');
      return null;
    }
  }

  // Get TV show details directly by TMDB ID
  static Future<Map<String, dynamic>?> getTVShowById(String tmdbId) async {
    try {
      print('Getting TV show details by TMDB ID: $tmdbId');

      // Build the query URL for direct TV show lookup
      final url = '$baseUrl/tv/$tmdbId?api_key=$apiKey';

      // Make the request
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Successfully retrieved TV show details for TMDB ID: $tmdbId');
        return data;
      } else {
        print(
            'TMDB API error for TV show ID $tmdbId: ${response.statusCode} - ${response.body}');
      }

      return null;
    } catch (e) {
      print('Error getting TV show by ID: $e');
      return null;
    }
  }

  // Get the full poster URL for a poster path
  static String getPosterUrl(String posterPath) {
    if (posterPath.startsWith('/')) {
      return '$imageBaseUrl$posterPath';
    } else {
      return '$imageBaseUrl/$posterPath';
    }
  }

  // Get the full backdrop URL for a backdrop path
  static String getBackdropUrl(String backdropPath) {
    // Use a larger size for backdrops
    const String backdropBaseUrl = 'https://image.tmdb.org/t/p/w1280';

    if (backdropPath.startsWith('/')) {
      return '$backdropBaseUrl$backdropPath';
    } else {
      return '$backdropBaseUrl/$backdropPath';
    }
  }

  // Clean up a title for search
  static String _cleanTitle(String title) {
    // Remove any text in brackets or parentheses
    String cleaned = title.replaceAll(RegExp(r'\([^)]*\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\[[^\]]*\]'), '');

    // Remove common suffixes that might interfere with search
    cleaned = cleaned.replaceAll('Multi-Subs', '');
    cleaned = cleaned.replaceAll('MULTI-AUDIO', '');
    cleaned = cleaned.replaceAll('4K', '');

    // Remove any text after a colon or dash
    if (cleaned.contains(':')) {
      cleaned = cleaned.split(':').first;
    }

    if (cleaned.contains(' - ')) {
      cleaned = cleaned.split(' - ').first;
    }

    // Remove any special characters and trim
    cleaned = cleaned.replaceAll(RegExp(r'[^\w\s]'), '').trim();

    // Remove extra spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    print('Cleaned title for search: "$title" -> "$cleaned"');

    // Encode for URL
    return Uri.encodeComponent(cleaned);
  }
}
