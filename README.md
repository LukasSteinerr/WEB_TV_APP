# WEB TV APP

A Flutter-based web application for streaming IPTV content, movies, and TV shows.

## Features

- **M3U Playlist Support**: Load and view channels from M3U playlists
- **Xtream API Integration**: Connect to Xtream IPTV providers
- **TMDB Integration**: Fetch high-quality movie and TV show metadata and images
- **Persistent Storage**: Save playlists and connections between app restarts
- **Responsive Design**: Works on web browsers and mobile devices
- **Video Playback**: Stream live TV, movies, and TV show episodes

## Key Components

### M3U Playlist Support
- Add playlists via URL
- Browse channels by category
- Stream content directly in the app

### Xtream API Integration
- Connect to Xtream providers with server URL, username, and password
- Browse Live TV, Movies, and Series categories
- View detailed information about content

### TMDB Integration
- Automatic fallback to TMDB for broken images
- Direct TMDB ID lookup for accurate metadata
- High-quality posters and backdrop images
- Detailed movie and TV show information

## Getting Started

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Add your TMDB API key in `lib/config.dart`
4. Run the app with `flutter run -d chrome`

## Requirements

- Flutter SDK
- TMDB API key (get one at https://www.themoviedb.org/settings/api)
- Web browser or mobile device

## License

This project is licensed under the MIT License - see the LICENSE file for details.
