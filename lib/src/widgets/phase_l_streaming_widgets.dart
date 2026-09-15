import 'package:flutter/material.dart';
import '../services/streaming_service.dart';

class LiveStreamCard extends StatelessWidget {
  final LiveStream stream;
  final VoidCallback? onTap;

  const LiveStreamCard({required this.stream, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 60,
          height: 60,
          color: Colors.red,
          child: Center(child: Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
        title: Text(stream.title),
        subtitle: Text('${stream.viewerCount} viewers'),
      ),
    );
  }
}

class VideoTutorialCard extends StatelessWidget {
  final VideoContent video;
  final VoidCallback? onPlay;

  const VideoTutorialCard({required this.video, this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(video.thumbnailUrl, height: 200, fit: BoxFit.cover),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(video.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ElevatedButton(onPressed: onPlay, child: Text('Watch')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
