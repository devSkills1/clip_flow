import 'package:clip_flow_pro/core/models/clip_item.dart';

/// 媒体类型演示程序
/// 展示 ClipType.video 和 ClipType.audio 的实际使用场景
void main() {
  print('=== ClipType.video 和 ClipType.audio 演示 ===\n');

  // 1. 创建视频类型的 ClipItem
  print('1. 创建视频类型的 ClipItem:');
  final videoClip = ClipItem(
    id: 'video_001',
    content: '/Users/ryan/Movies/sample_video.mp4',
    type: ClipType.video,
    metadata: {
      'duration': '00:02:30',
      'resolution': '1920x1080',
      'format': 'mp4',
      'size': '15.2 MB',
      'codec': 'H.264',
      'fps': '30',
      'thumbnail': '/Users/ryan/Movies/thumbnails/sample_video_thumb.jpg',
    },
  );

  print('   ID: ${videoClip.id}');
  print('   类型: ${videoClip.type}');
  print('   文件路径: ${videoClip.content}');
  print('   时长: ${videoClip.metadata?['duration']}');
  print('   分辨率: ${videoClip.metadata?['resolution']}');
  print('   文件大小: ${videoClip.metadata?['size']}');
  print('   缩略图: ${videoClip.metadata?['thumbnail']}');
  print('');

  // 2. 创建音频类型的 ClipItem
  print('2. 创建音频类型的 ClipItem:');
  final audioClip = ClipItem(
    id: 'audio_001',
    content: '/Users/ryan/Music/sample_audio.mp3',
    type: ClipType.audio,
    metadata: {
      'duration': '00:03:45',
      'bitrate': '320 kbps',
      'format': 'mp3',
      'size': '8.9 MB',
      'artist': 'Sample Artist',
      'title': 'Sample Song',
      'album': 'Sample Album',
      'genre': 'Electronic',
      'sampleRate': '44.1 kHz',
    },
  );

  print('   ID: ${audioClip.id}');
  print('   类型: ${audioClip.type}');
  print('   文件路径: ${audioClip.content}');
  print('   时长: ${audioClip.metadata?['duration']}');
  print('   比特率: ${audioClip.metadata?['bitrate']}');
  print('   艺术家: ${audioClip.metadata?['artist']}');
  print('   歌曲名: ${audioClip.metadata?['title']}');
  print('   专辑: ${audioClip.metadata?['album']}');
  print('   文件大小: ${audioClip.metadata?['size']}');
  print('');

  // 3. JSON 序列化演示
  print('3. JSON 序列化演示:');
  final videoJson = videoClip.toJson();
  final audioJson = audioClip.toJson();

  print('   视频 JSON: ${videoJson.toString()}');
  print('   音频 JSON: ${audioJson.toString()}');
  print('');

  // 4. JSON 反序列化演示
  print('4. JSON 反序列化演示:');
  final videoFromJson = ClipItem.fromJson(videoJson);
  final audioFromJson = ClipItem.fromJson(audioJson);

  print('   从 JSON 恢复的视频类型: ${videoFromJson.type}');
  print('   从 JSON 恢复的音频类型: ${audioFromJson.type}');
  print('   视频内容匹配: ${videoFromJson.content == videoClip.content}');
  print('   音频内容匹配: ${audioFromJson.content == audioClip.content}');
  print('');

  // 5. copyWith 功能演示
  print('5. copyWith 功能演示:');
  final videoMetadata = Map<String, dynamic>.from(videoClip.metadata ?? {});
  videoMetadata['quality'] = 'HD';
  videoMetadata['lastPlayed'] = DateTime.now().toIso8601String();

  final updatedVideoClip = videoClip.copyWith(
    metadata: videoMetadata,
  );

  final audioMetadata = Map<String, dynamic>.from(audioClip.metadata ?? {});
  audioMetadata['playCount'] = '15';
  audioMetadata['lastPlayed'] = DateTime.now().toIso8601String();

  final updatedAudioClip = audioClip.copyWith(
    metadata: audioMetadata,
  );

  print('   更新后的视频质量: ${updatedVideoClip.metadata?['quality']}');
  print('   更新后的音频播放次数: ${updatedAudioClip.metadata?['playCount']}');
  print('');

  // 6. 类型检查演示
  print('6. 类型检查演示:');
  final clips = [videoClip, audioClip];

  for (final clip in clips) {
    switch (clip.type) {
      case ClipType.video:
        print('   检测到视频文件: ${clip.content}');
        print('     - 分辨率: ${clip.metadata?['resolution']}');
        print('     - 编解码器: ${clip.metadata?['codec']}');
        break;
      case ClipType.audio:
        print('   检测到音频文件: ${clip.content}');
        print('     - 艺术家: ${clip.metadata?['artist']}');
        print('     - 比特率: ${clip.metadata?['bitrate']}');
        break;
      default:
        print('   其他类型: ${clip.type}');
    }
  }
  print('');

  // 7. 媒体文件路径验证演示
  print('7. 媒体文件路径验证演示:');
  final mediaExtensions = {
    ClipType.video: ['.mp4', '.avi', '.mov', '.mkv', '.webm'],
    ClipType.audio: ['.mp3', '.wav', '.flac', '.aac', '.ogg'],
  };

  for (final clip in clips) {
    final extensions = mediaExtensions[clip.type] ?? [];
    final hasValidExtension = extensions.any(
      (ext) => clip.content?.toLowerCase().endsWith(ext) ?? false,
    );

    print('   ${clip.type} 文件扩展名验证: ${hasValidExtension ? '✓' : '✗'}');
    print('     文件: ${clip.content}');
    print('     支持的扩展名: ${extensions.join(', ')}');
  }

  print('\n=== 演示完成 ===');
}
