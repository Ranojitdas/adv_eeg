import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class SafeYoutubePlayer extends StatefulWidget {
  final String videoUrl;
  final String title;

  const SafeYoutubePlayer({
    Key? key,
    required this.videoUrl,
    required this.title,
  }) : super(key: key);

  @override
  State<SafeYoutubePlayer> createState() => _SafeYoutubePlayerState();
}

class _SafeYoutubePlayerState extends State<SafeYoutubePlayer> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _embedUrl;

  @override
  void initState() {
    super.initState();
    _prepareEmbedUrl();
  }

  void _prepareEmbedUrl() {
    try {
      // Clean and validate the video URL
      String cleanUrl = widget.videoUrl.trim();
      
      // Extract video ID from different YouTube URL formats
      String? videoId;
      
      if (cleanUrl.contains('youtube.com/watch?v=')) {
        videoId = cleanUrl.split('v=')[1].split('&')[0];
      } else if (cleanUrl.contains('youtu.be/')) {
        videoId = cleanUrl.split('youtu.be/')[1].split('?')[0];
      } else if (cleanUrl.contains('youtube.com/embed/')) {
        videoId = cleanUrl.split('embed/')[1].split('?')[0];
      }

      print('🎥 [SAFE_YOUTUBE] Processing URL: $cleanUrl');
      print('🎥 [SAFE_YOUTUBE] Extracted Video ID: $videoId');

      if (videoId != null && videoId.isNotEmpty && videoId.length == 11) {
        // Create YouTube embed URL
        _embedUrl = 'https://www.youtube.com/embed/$videoId?autoplay=0&controls=1&showinfo=0&rel=0&iv_load_policy=3&modestbranding=1';
        
        setState(() {
          _hasError = false;
          _errorMessage = null;
        });
      } else {
        throw Exception('Invalid video ID: $videoId');
      }
    } catch (e) {
      print('❌ [SAFE_YOUTUBE] Error preparing embed URL: $e');
      // Use fallback video
      _embedUrl = 'https://www.youtube.com/embed/1ZYbU82GVz4?autoplay=0&controls=1&showinfo=0&rel=0&iv_load_policy=3&modestbranding=1';
      setState(() {
        _hasError = false;
        _errorMessage = 'Loading fallback video...';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _embedUrl == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Video unavailable',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _prepareEmbedUrl,
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_embedUrl!)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                useHybridComposition: true,
                transparentBackground: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                print('🎥 [SAFE_YOUTUBE] WebView created for: ${widget.title}');
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _isLoading = true;
                });
              },
              onLoadStop: (controller, url) {
                setState(() {
                  _isLoading = false;
                });
                print('✅ [SAFE_YOUTUBE] Video loaded for: ${widget.title}');
              },
              onReceivedError: (controller, request, error) {
                print('❌ [SAFE_YOUTUBE] WebView error: ${error.description}');
                setState(() {
                  _hasError = true;
                  _errorMessage = 'Failed to load video';
                  _isLoading = false;
                });
              },
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
