import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static EncryptionService get instance => _instance;

  Encrypter? _encrypter;
  IV? _iv;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    String? keyString = prefs.getString('encryption_key');
    String? ivString = prefs.getString('encryption_iv');

    // 如果没有密钥，生成新的
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
      throw Exception('Encryption service not initialized');
    }

    final encrypted = _encrypter!.encrypt(data, iv: _iv!);
    return Uint8List.fromList(encrypted.bytes);
  }

  Future<Uint8List> decrypt(Uint8List encryptedData) async {
    if (!_isInitialized) await initialize();

    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }

    final encrypted = Encrypted(encryptedData);
    final decrypted = _encrypter!.decrypt(encrypted, iv: _iv!);
    return Uint8List.fromList(utf8.encode(decrypted));
  }

  Future<String> encryptString(String text) async {
    if (!_isInitialized) await initialize();

    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }

    final encrypted = _encrypter!.encrypt(text, iv: _iv!);
    return encrypted.base64;
  }

  Future<String> decryptString(String encryptedText) async {
    if (!_isInitialized) await initialize();

    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }

    final encrypted = Encrypted.fromBase64(encryptedText);
    return _encrypter!.decrypt(encrypted, iv: _iv!);
  }

  Future<Map<String, dynamic>> encryptMap(Map<String, dynamic> data) async {
    if (!_isInitialized) await initialize();

    final jsonString = jsonEncode(data);
    final encryptedString = await encryptString(jsonString);
    
    return {
      'encrypted': true,
      'data': encryptedString,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> decryptMap(Map<String, dynamic> encryptedData) async {
    if (!_isInitialized) await initialize();

    if (encryptedData['encrypted'] != true) {
      return encryptedData;
    }

    final encryptedString = encryptedData['data'] as String;
    final decryptedString = await decryptString(encryptedString);
    
    return jsonDecode(decryptedString);
  }

  Future<void> changeEncryptionKey() async {
    if (!_isInitialized) await initialize();

    final prefs = await SharedPreferences.getInstance();
    
    // 生成新密钥
    final newKey = Key.fromSecureRandom(32);
    final newIv = IV.fromSecureRandom(16);
    
    final newKeyString = base64Encode(newKey.bytes);
    final newIvString = base64Encode(newIv.bytes);
    
    // 保存新密钥
    await prefs.setString('encryption_key', newKeyString);
    await prefs.setString('encryption_iv', newIvString);
    
    // 更新当前实例
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

  // 生成随机密钥（用于测试）
  static String generateRandomKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  // 验证密钥强度
  static bool isKeyStrong(String key) {
    if (key.length < 32) return false;
    
    // 检查是否包含足够的随机性
    final bytes = base64Decode(key);
    final uniqueBytes = bytes.toSet();
    
    // 至少应该有20个不同的字节值
    return uniqueBytes.length >= 20;
  }

  // 获取密钥信息（不暴露实际密钥）
  Future<Map<String, dynamic>> getKeyInfo() async {
    if (!_isInitialized) await initialize();

    final prefs = await SharedPreferences.getInstance();
    final keyString = prefs.getString('encryption_key');
    
    if (keyString == null) {
      return {
        'hasKey': false,
        'keyLength': 0,
        'isStrong': false,
      };
    }

    return {
      'hasKey': true,
      'keyLength': keyString.length,
      'isStrong': isKeyStrong(keyString),
      'algorithm': 'AES-256-GCM',
    };
  }
}
