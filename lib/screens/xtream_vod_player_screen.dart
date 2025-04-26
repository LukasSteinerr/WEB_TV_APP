import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class XtreamVodPlayerScreen extends StatefulWidget {
  final String title;
  final String streamUrl;
  final String posterUrl;

  XtreamVodPlayerScreen({
    required this.title,
    required this.streamUrl,
    required this.posterUrl,
  });

  @override
  _XtreamVodPlayerScreenState createState() => _XtreamVodPlayerScreenState();
}

class _XtreamVodPlayerScreenState extends State<XtreamVodPlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.streamUrl));

      await _videoController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController.value.aspectRatio,
        placeholder: widget.posterUrl.isNotEmpty
            ? Image.network(
                widget.posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.black);
                },
              )
            : Container(color: Colors.black),
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize player: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initializePlayer,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: _chewieController != null
                      ? Chewie(controller: _chewieController!)
                      : Container(),
                ),
    );
  }
}
