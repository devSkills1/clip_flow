import 'package:flutter_test/flutter_test.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';

/// 测试媒体类型（video/audio）的 ClipItem 功能
void main() {
  group('ClipType.video 测试', () {
    test('创建视频类型的 ClipItem', () {
      final videoClip = ClipItem(
        type: ClipType.video,
        metadata: {
          'fileName': 'test_video.mp4',
          'fileSize': 1024000,
          'duration': 120, // 秒
          'resolution': '1920x1080',
          'codec': 'H.264',
          'mimeType': 'video/mp4',
        },
        filePath: 'media/video/2024/01/15/test-uuid.mp4',
        content: null, // 视频类型通常不存储文本内容
      );

      expect(videoClip.type, equals(ClipType.video));
      expect(
        videoClip.filePath,
        equals('media/video/2024/01/15/test-uuid.mp4'),
      );
      expect(videoClip.content, isNull);
      expect(videoClip.metadata['fileName'], equals('test_video.mp4'));
      expect(videoClip.metadata['duration'], equals(120));
      expect(videoClip.metadata['resolution'], equals('1920x1080'));
    });

    test('视频 ClipItem 的 JSON 序列化和反序列化', () {
      final originalClip = ClipItem(
        type: ClipType.video,
        metadata: {
          'fileName': 'sample.mov',
          'fileSize': 2048000,
          'duration': 300,
          'codec': 'HEVC',
          'mimeType': 'video/quicktime',
        },
        filePath: 'media/video/2024/01/15/sample-uuid.mov',
        thumbnail: [255, 216, 255, 224], // JPEG 头部字节示例
      );

      // 序列化
      final json = originalClip.toJson();
      expect(json['type'], equals('video'));
      expect(
        json['filePath'],
        equals('media/video/2024/01/15/sample-uuid.mov'),
      );
      expect(json['metadata']['fileName'], equals('sample.mov'));

      // 反序列化
      final deserializedClip = ClipItem.fromJson(json);
      expect(deserializedClip.type, equals(ClipType.video));
      expect(deserializedClip.filePath, equals(originalClip.filePath));
      expect(deserializedClip.metadata['fileName'], equals('sample.mov'));
      expect(deserializedClip.thumbnail, equals([255, 216, 255, 224]));
    });

    test('视频 ClipItem 的 copyWith 功能', () {
      final originalClip = ClipItem(
        type: ClipType.video,
        metadata: {'fileName': 'original.mp4'},
        filePath: 'media/video/original.mp4',
      );

      final updatedClip = originalClip.copyWith(
        metadata: {'fileName': 'updated.mp4', 'processed': true},
        isFavorite: true,
      );

      expect(updatedClip.type, equals(ClipType.video));
      expect(updatedClip.metadata['fileName'], equals('updated.mp4'));
      expect(updatedClip.metadata['processed'], equals(true));
      expect(updatedClip.isFavorite, equals(true));
      expect(updatedClip.id, equals(originalClip.id)); // ID 应该保持不变
    });
  });

  group('ClipType.audio 测试', () {
    test('创建音频类型的 ClipItem', () {
      final audioClip = ClipItem(
        type: ClipType.audio,
        metadata: {
          'fileName': 'test_audio.mp3',
          'fileSize': 512000,
          'duration': 180, // 秒
          'bitrate': 320, // kbps
          'sampleRate': 44100, // Hz
          'codec': 'MP3',
          'mimeType': 'audio/mpeg',
          'artist': 'Test Artist',
          'title': 'Test Song',
        },
        filePath: 'media/audio/2024/01/15/test-uuid.mp3',
        content: null, // 音频类型通常不存储文本内容
      );

      expect(audioClip.type, equals(ClipType.audio));
      expect(
        audioClip.filePath,
        equals('media/audio/2024/01/15/test-uuid.mp3'),
      );
      expect(audioClip.content, isNull);
      expect(audioClip.metadata['fileName'], equals('test_audio.mp3'));
      expect(audioClip.metadata['duration'], equals(180));
      expect(audioClip.metadata['bitrate'], equals(320));
      expect(audioClip.metadata['artist'], equals('Test Artist'));
    });

    test('音频 ClipItem 的 JSON 序列化和反序列化', () {
      final originalClip = ClipItem(
        type: ClipType.audio,
        metadata: {
          'fileName': 'podcast.wav',
          'fileSize': 10240000,
          'duration': 3600, // 1小时
          'codec': 'PCM',
          'mimeType': 'audio/wav',
          'channels': 2,
          'sampleRate': 48000,
        },
        filePath: 'media/audio/2024/01/15/podcast-uuid.wav',
      );

      // 序列化
      final json = originalClip.toJson();
      expect(json['type'], equals('audio'));
      expect(
        json['filePath'],
        equals('media/audio/2024/01/15/podcast-uuid.wav'),
      );
      expect(json['metadata']['fileName'], equals('podcast.wav'));

      // 反序列化
      final deserializedClip = ClipItem.fromJson(json);
      expect(deserializedClip.type, equals(ClipType.audio));
      expect(deserializedClip.filePath, equals(originalClip.filePath));
      expect(deserializedClip.metadata['fileName'], equals('podcast.wav'));
      expect(deserializedClip.metadata['channels'], equals(2));
    });

    test('音频 ClipItem 的 copyWith 功能', () {
      final originalClip = ClipItem(
        type: ClipType.audio,
        metadata: {'fileName': 'original.mp3', 'processed': false},
        filePath: 'media/audio/original.mp3',
      );

      final updatedClip = originalClip.copyWith(
        metadata: {
          'fileName': 'original.mp3',
          'processed': true,
          'transcription': '这是音频转录文本',
        },
        isFavorite: true,
      );

      expect(updatedClip.type, equals(ClipType.audio));
      expect(updatedClip.metadata['processed'], equals(true));
      expect(updatedClip.metadata['transcription'], equals('这是音频转录文本'));
      expect(updatedClip.isFavorite, equals(true));
      expect(updatedClip.id, equals(originalClip.id)); // ID 应该保持不变
    });
  });

  group('媒体类型通用测试', () {
    test('视频和音频类型的区分', () {
      final videoClip = ClipItem(
        type: ClipType.video,
        metadata: {'fileName': 'video.mp4'},
      );

      final audioClip = ClipItem(
        type: ClipType.audio,
        metadata: {'fileName': 'audio.mp3'},
      );

      expect(videoClip.type, equals(ClipType.video));
      expect(audioClip.type, equals(ClipType.audio));
      expect(videoClip.type, isNot(equals(audioClip.type)));
    });

    test('媒体文件路径格式验证', () {
      final videoClip = ClipItem(
        type: ClipType.video,
        metadata: {'fileName': 'test.mp4'},
        filePath: 'media/video/2024/01/15/uuid.mp4',
      );

      final audioClip = ClipItem(
        type: ClipType.audio,
        metadata: {'fileName': 'test.mp3'},
        filePath: 'media/audio/2024/01/15/uuid.mp3',
      );

      // 验证路径格式
      expect(videoClip.filePath, contains('media/video/'));
      expect(audioClip.filePath, contains('media/audio/'));
      expect(videoClip.filePath, contains('2024/01/15/'));
      expect(audioClip.filePath, contains('2024/01/15/'));
    });

    test('媒体类型的元数据结构', () {
      final videoClip = ClipItem(
        type: ClipType.video,
        metadata: {
          'fileName': 'video.mp4',
          'fileSize': 1024000,
          'duration': 120,
          'mimeType': 'video/mp4',
        },
      );

      final audioClip = ClipItem(
        type: ClipType.audio,
        metadata: {
          'fileName': 'audio.mp3',
          'fileSize': 512000,
          'duration': 180,
          'mimeType': 'audio/mpeg',
        },
      );

      // 验证共同的元数据字段
      expect(videoClip.metadata.containsKey('fileName'), isTrue);
      expect(videoClip.metadata.containsKey('fileSize'), isTrue);
      expect(videoClip.metadata.containsKey('duration'), isTrue);
      expect(videoClip.metadata.containsKey('mimeType'), isTrue);

      expect(audioClip.metadata.containsKey('fileName'), isTrue);
      expect(audioClip.metadata.containsKey('fileSize'), isTrue);
      expect(audioClip.metadata.containsKey('duration'), isTrue);
      expect(audioClip.metadata.containsKey('mimeType'), isTrue);

      // 验证 MIME 类型
      expect(videoClip.metadata['mimeType'], startsWith('video/'));
      expect(audioClip.metadata['mimeType'], startsWith('audio/'));
    });

    test('媒体类型的缩略图支持', () {
      // 视频通常有缩略图
      final videoClip = ClipItem(
        type: ClipType.video,
        metadata: {'fileName': 'video.mp4'},
        thumbnail: [255, 216, 255, 224], // JPEG 头部字节
      );

      // 音频可能有专辑封面作为缩略图
      final audioClip = ClipItem(
        type: ClipType.audio,
        metadata: {'fileName': 'audio.mp3'},
        thumbnail: [137, 80, 78, 71], // PNG 头部字节
      );

      expect(videoClip.thumbnail, isNotNull);
      expect(audioClip.thumbnail, isNotNull);
      expect(videoClip.thumbnail!.length, greaterThan(0));
      expect(audioClip.thumbnail!.length, greaterThan(0));
    });
  });

  group('边界情况和错误处理', () {
    test('空元数据的媒体类型', () {
      final videoClip = ClipItem(
        type: ClipType.video,
        metadata: {},
      );

      final audioClip = ClipItem(
        type: ClipType.audio,
        metadata: {},
      );

      expect(videoClip.metadata, isEmpty);
      expect(audioClip.metadata, isEmpty);
      expect(videoClip.type, equals(ClipType.video));
      expect(audioClip.type, equals(ClipType.audio));
    });

    test('无效 JSON 反序列化时的默认行为', () {
      final invalidJson = {
        'type': 'invalid_type',
        'metadata': {},
      };

      final clip = ClipItem.fromJson(invalidJson);
      // 应该回退到默认的 text 类型
      expect(clip.type, equals(ClipType.text));
    });

    test('媒体类型的 toString 输出', () {
      final videoClip = ClipItem(
        type: ClipType.video,
        metadata: {'fileName': 'test.mp4'},
      );

      final audioClip = ClipItem(
        type: ClipType.audio,
        metadata: {'fileName': 'test.mp3'},
      );

      final videoString = videoClip.toString();
      final audioString = audioClip.toString();

      expect(videoString, contains('video'));
      expect(audioString, contains('audio'));
      expect(videoString, contains(videoClip.id));
      expect(audioString, contains(audioClip.id));
    });
  });
}
