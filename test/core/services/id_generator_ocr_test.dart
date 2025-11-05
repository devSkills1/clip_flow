import 'package:flutter_test/flutter_test.dart';
import 'package:clip_flow_pro/core/services/id_generator.dart';

void main() {
  group('IdGenerator OCR Tests', () {
    const parentImageId = 'a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef1234567890';

    test('generateOcrTextId should generate consistent IDs for same content', () {
      const ocrText = 'Hello World';

      final id1 = IdGenerator.generateOcrTextId(ocrText, parentImageId);
      final id2 = IdGenerator.generateOcrTextId(ocrText, parentImageId);

      expect(id1, equals(id2));
      expect(id1.length, equals(64)); // SHA256 hash length
    });

    test('generateOcrTextId should generate different IDs for different content', () {
      const ocrText1 = 'Hello World';
      const ocrText2 = 'Hello Flutter';

      final id1 = IdGenerator.generateOcrTextId(ocrText1, parentImageId);
      final id2 = IdGenerator.generateOcrTextId(ocrText2, parentImageId);

      expect(id1, isNot(equals(id2)));
    });

    test('generateOcrTextId should generate different IDs for different parent images', () {
      const ocrText = 'Hello World';
      const parentImageId2 = 'f6e5d4c3b2a1098765432109876543210fedcba09876543210fedcba0987654321';

      final id1 = IdGenerator.generateOcrTextId(ocrText, parentImageId);
      final id2 = IdGenerator.generateOcrTextId(ocrText, parentImageId2);

      expect(id1, isNot(equals(id2)));
    });

    test('generateOcrTextId should normalize whitespace', () {
      const ocrText1 = 'Hello   World';
      const ocrText2 = 'Hello World';
      const ocrText3 = 'Hello \n\t World';

      final id1 = IdGenerator.generateOcrTextId(ocrText1, parentImageId);
      final id2 = IdGenerator.generateOcrTextId(ocrText2, parentImageId);
      final id3 = IdGenerator.generateOcrTextId(ocrText3, parentImageId);

      expect(id1, equals(id2));
      expect(id2, equals(id3));
    });

    test('generateOcrTextId should trim whitespace', () {
      const ocrText1 = 'Hello World';
      const ocrText2 = '  Hello World  ';
      const ocrText3 = '\nHello World\n';

      final id1 = IdGenerator.generateOcrTextId(ocrText1, parentImageId);
      final id2 = IdGenerator.generateOcrTextId(ocrText2, parentImageId);
      final id3 = IdGenerator.generateOcrTextId(ocrText3, parentImageId);

      expect(id1, equals(id2));
      expect(id2, equals(id3));
    });

    test('generateOcrTextId should handle empty text', () {
      const ocrText = '';

      final id = IdGenerator.generateOcrTextId(ocrText, parentImageId);

      expect(id, isNotEmpty);
      expect(id.length, equals(64));
    });

    test('generateOcrTextId should truncate very long text', () {
      // 创建超过10000字符的文本
      final longText = 'A' * 15000;
      final truncatedText = 'A' * 10000 + '...';

      final id1 = IdGenerator.generateOcrTextId(longText, parentImageId);
      final id2 = IdGenerator.generateOcrTextId(truncatedText, parentImageId);

      expect(id1, equals(id2));
    });

    test('generateOcrContentSignature should generate consistent signatures', () {
      const ocrText = 'Hello World';

      final signature1 = IdGenerator.generateOcrContentSignature(ocrText);
      final signature2 = IdGenerator.generateOcrContentSignature(ocrText);

      expect(signature1, equals(signature2));
      expect(signature1.length, equals(64));
    });

    test('generateOcrContentSignature should be different from OCR text IDs', () {
      const ocrText = 'Hello World';

      final ocrId = IdGenerator.generateOcrTextId(ocrText, parentImageId);
      final signature = IdGenerator.generateOcrContentSignature(ocrText);

      expect(ocrId, isNot(equals(signature)));
    });

    test('generateOcrContentSignature should normalize text same as OCR ID generation', () {
      const ocrText1 = 'Hello   World';
      const ocrText2 = 'Hello World';

      final signature1 = IdGenerator.generateOcrContentSignature(ocrText1);
      final signature2 = IdGenerator.generateOcrContentSignature(ocrText2);

      expect(signature1, equals(signature2));
    });

    test('OCR ID generation should handle Unicode characters', () {
      const ocrText = '你好世界 🌍 Hello World';

      final id1 = IdGenerator.generateOcrTextId(ocrText, parentImageId);
      final id2 = IdGenerator.generateOcrTextId(ocrText, parentImageId);

      expect(id1, equals(id2));
      expect(id1.length, equals(64));
    });

    test('OCR ID generation should handle special characters', () {
      const ocrText = 'Hello @#\$%^&*() World! 123';

      final id1 = IdGenerator.generateOcrTextId(ocrText, parentImageId);
      final id2 = IdGenerator.generateOcrTextId(ocrText, parentImageId);

      expect(id1, equals(id2));
      expect(id1.length, equals(64));
    });
  });
}