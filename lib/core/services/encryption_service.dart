import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  factory EncryptionService() => _instance;
  EncryptionService._internal();
  static final EncryptionService _instance = EncryptionService._internal();

  static EncryptionService get instance => _instance;

  Encrypter? _encrypter;
  IV? _iv;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    var keyString = prefs.getString('encryption_key');
    var ivString = prefs.getString('encryption_iv');

    if (keyString == null || ivString == null) {
      final key = Key.fromSecureRandom(32);
      final iv = IV.fromSecureRandom(16);
      keyString = base64Encode(key.bytes);
      ivString = base64Encode(iv.bytes);
      await prefs.setString('encryption_key', keyString);
      await prefs.setString('encryption_iv', ivString);
    }

    final key = Key.fromBase64(keyString);
    _iv = IV.fromBase64(ivString);
    _encrypter = Encrypter(AES(key, mode: AESMode.gcm));

    _isInitialized = true;
  }

  Future<Uint8List> encrypt(Uint8List data) async {
    if (!_isInitialized) await initialize();
    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption not initialized');
    }
    final enc = _encrypter!.encryptBytes(data, iv: _iv);
    return Uint8List.fromList(enc.bytes);
  }

  Future<Uint8List> decrypt(Uint8List encryptedData) async {
    if (!_isInitialized) await initialize();
    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption not initialized');
    }
    final dec = _encrypter!.decryptBytes(Encrypted(encryptedData), iv: _iv);
    return Uint8List.fromList(dec);
  }

  Future<String> encryptString(String text) async {
    if (!_isInitialized) await initialize();
    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption not initialized');
    }
    return _encrypter!.encrypt(text, iv: _iv).base64;
  }

  Future<String> decryptString(String encryptedText) async {
    if (!_isInitialized) await initialize();
    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption not initialized');
    }
    return _encrypter!.decrypt(Encrypted.fromBase64(encryptedText), iv: _iv);
  }

  Future<Map<String, dynamic>> encryptMap(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    final encryptedString = await encryptString(jsonString);
    return {
      'encrypted': true,
      'data': encryptedString,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> decryptMap(
    Map<String, dynamic> encryptedData,
  ) async {
    if (encryptedData['encrypted'] != true) {
      return Map<String, dynamic>.from(encryptedData);
    }
    final encryptedString = encryptedData['data'] as String?;
    if (encryptedString == null) return <String, dynamic>{};
    final decryptedString = await decryptString(encryptedString);
    final decoded = jsonDecode(decryptedString);
    return decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
  }

  Future<void> changeEncryptionKey() async {
    final prefs = await SharedPreferences.getInstance();
    final newKey = Key.fromSecureRandom(32);
    final newIv = IV.fromSecureRandom(16);
    await prefs.setString('encryption_key', base64Encode(newKey.bytes));
    await prefs.setString('encryption_iv', base64Encode(newIv.bytes));
    _iv = newIv;
    _encrypter = Encrypter(AES(newKey, mode: AESMode.gcm));
  }

  Future<void> clearEncryptionKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('encryption_key');
    await prefs.remove('encryption_iv');
    _encrypter = null;
    _iv = null;
    _isInitialized = false;
  }

  bool get isEncryptionEnabled => _isInitialized && _encrypter != null;

  static String generateRandomKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  static bool isKeyStrong(String key) {
    if (key.length < 32) return false;
    final bytes = base64Decode(key);
    return bytes.toSet().length >= 20;
  }

  Future<Map<String, dynamic>> getKeyInfo() async {
    if (!_isInitialized) await initialize();
    final prefs = await SharedPreferences.getInstance();
    final keyString = prefs.getString('encryption_key');
    if (keyString == null) {
      return {'hasKey': false, 'keyLength': 0, 'isStrong': false};
    }
    return {
      'hasKey': true,
      'keyLength': keyString.length,
      'isStrong': isKeyStrong(keyString),
      'algorithm': 'AES-256-GCM',
    };
  }
}
