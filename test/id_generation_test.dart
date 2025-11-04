import 'package:flutter_test/flutter_test.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/id_generator.dart';
import 'package:clip_flow_pro/core/services/deduplication_service.dart';
import 'package:clip_flow_pro/core/utils/color_utils.dart';

void main() {
  group('ID Generation and Deduplication Tests', () {
    test('IDs should be consistent for same content', () {
      // Test text content
      const textContent = 'Hello, World!';
      final id1 = IdGenerator.generateId(
        ClipType.text,
        textContent,
        null,
        {},
      );
      final id2 = IdGenerator.generateId(
        ClipType.text,
        textContent,
        null,
        {},
      );
      expect(id1, equals(id2));
      expect(id1.length, equals(64)); // SHA256 hash length

      // Test color content with different formats
      const color1 = '#FF0000';
      const color2 = '#ff0000';

      final colorId1 = IdGenerator.generateId(
        ClipType.color,
        color1,
        null,
        {},
      );
      final colorId2 = IdGenerator.generateId(
        ClipType.color,
        color2,
        null,
        {},
      );

      // Colors should normalize to same ID
      expect(colorId1, equals(colorId2));
      expect(colorId1.length, equals(64));
    });

    test('File identifier extraction should work correctly', () {
      // Test file path with timestamp
      const filePath1 = 'media/files/image_1704067200000_abc123.jpg';
      const filePath2 = 'media/files/image_1704067201000_abc123.jpg';
      const filePath3 = 'media/files/abc123.jpg';

      final id1 = IdGenerator.generateId(
        ClipType.image,
        null,
        filePath1,
        {},
      );
      final id2 = IdGenerator.generateId(
        ClipType.image,
        null,
        filePath2,
        {},
      );
      final id3 = IdGenerator.generateId(
        ClipType.image,
        null,
        filePath3,
        {},
      );

      // Should extract same identifier (abc123.jpg) from files with same name but different timestamps
      expect(id1, equals(id2));
      expect(id1, equals(id3));
    });

    test('Color normalization should produce consistent IDs', () {
      // Test various hex color formats
      const colors = [
        '#FF0000',
        '#ff0000',
        '#F00',
        '#f00',
      ];

      // Generate IDs
      final ids = colors.map((c) => IdGenerator.generateId(
        ClipType.color,
        c,
        null,
        {},
      )).toList();

      // All hex formats should produce same ID
      expect(ids[0], equals(ids[1]));
      expect(ids[1], equals(ids[2]));
      expect(ids[2], equals(ids[3]));

      // All IDs should be 64 characters
      for (final id in ids) {
        expect(id.length, equals(64));
        expect(IdGenerator.isValidId(id), isTrue);
      }
    });

    test('Different content types should produce different IDs', () {
      const content = 'test';

      final textId = IdGenerator.generateId(ClipType.text, content, null, {});
      final codeId = IdGenerator.generateId(ClipType.code, content, null, {});
      final urlId = IdGenerator.generateId(ClipType.url, content, null, {});

      // Same content with different types should have different IDs
      expect(textId, isNot(equals(codeId)));
      expect(codeId, isNot(equals(urlId)));
      expect(textId, isNot(equals(urlId)));
    });

    test('DeduplicationService validates IDs correctly', () {
      final service = DeduplicationService.instance;

      // Valid SHA256 hash
      expect(service.isValidId('a' * 64), isTrue);

      // Invalid IDs
      expect(service.isValidId(null), isFalse);
      expect(service.isValidId(''), isFalse);
      expect(service.isValidId('short'), isFalse);
      expect(service.isValidId('g' * 64), isFalse); // Invalid hex character
    });

    test('Batch deduplication works correctly', () async {
      final items = [
        ClipItem(
          id: 'id1',
          type: ClipType.text,
          content: 'Content 1',
          metadata: {},
        ),
        ClipItem(
          id: 'id2',
          type: ClipType.text,
          content: 'Content 2',
          metadata: {},
        ),
        ClipItem(
          id: 'id1', // Duplicate
          type: ClipType.text,
          content: 'Content 1',
          metadata: {},
        ),
        ClipItem(
          id: '', // Invalid ID
          type: ClipType.text,
          content: 'Content 3',
          metadata: {},
        ),
      ];

      final uniqueItems = await DeduplicationService.instance.batchDeduplicate(items);

      expect(uniqueItems.length, equals(3)); // Should remove one duplicate
      expect(uniqueItems[0].id, equals('id1'));
      expect(uniqueItems[1].id, equals('id2'));
      expect(uniqueItems[2].id, equals('')); // Invalid ID should be kept
    });

    test('ClipItem constructor uses IdGenerator when no ID provided', () {
      final item1 = ClipItem(
        type: ClipType.text,
        content: 'Test content',
        metadata: {},
      );

      final item2 = ClipItem(
        type: ClipType.text,
        content: 'Test content',
        metadata: {},
      );

      // Should generate same ID for identical content
      expect(item1.id, equals(item2.id));
      expect(item1.id.length, equals(64));
    });

    test('Content normalization works for colors', () {
      // Test that the IdGenerator properly normalizes colors
      const color1 = '#RGB';
      const color2 = '#RRGGBB';
      const color3 = 'rgb(255, 0, 0)';

      final id1 = IdGenerator.generateId(ClipType.color, color1, null, {});
      final id2 = IdGenerator.generateId(ClipType.color, color2, null, {});
      final id3 = IdGenerator.generateId(ClipType.color, color3, null, {});

      // All should be valid 64-character hashes
      expect(id1.length, equals(64));
      expect(id2.length, equals(64));
      expect(id3.length, equals(64));

      // First two should be the same (hex formats)
      expect(id1, equals(id2));
    });
  });
}