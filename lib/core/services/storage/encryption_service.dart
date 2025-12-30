import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 加解密服务（单例）
///
/// 使用 AES-256-GCM 进行对称加密：
/// - 首次初始化时自动生成并持久化密钥与 IV（SharedPreferences）
/// - 提供字节、字符串、Map 的加解密方法
/// - 支持更换/清空密钥并重新初始化
class EncryptionService {
  /// 工厂构造：返回单例实例
  factory EncryptionService() => _instance;

  /// 私有构造：单例内部初始化
  EncryptionService._internal();

  /// 单例实例
  static final EncryptionService _instance = EncryptionService._internal();

  /// 获取单例实例
  static EncryptionService get instance => _instance;

  /// 加解密器（AES-GCM）
  Encrypter? _encrypter;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 初始化加密组件
  ///
  /// - 从 SharedPreferences 读取或生成并保存密钥
  /// - 构建 AES-GCM Encrypter
  ///
  /// 安全改进：不再持久化 IV，每次加密生成新的随机 IV
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    var keyString = prefs.getString('encryption_key');

    if (keyString == null) {
      final key = Key.fromSecureRandom(32);
      keyString = base64Encode(key.bytes);
      await prefs.setString('encryption_key', keyString);
    }

    final key = Key.fromBase64(keyString);
    _encrypter = Encrypter(AES(key, mode: AESMode.gcm));

    _isInitialized = true;
  }

  /// 加密字节数据
  ///
  /// 参数：
  /// - data：待加密的字节数组
  ///
  /// 返回：包含 IV 和密文的元组 (iv, ciphertext)
  /// - iv: Base64 编码的初始化向量（16 字节）
  /// - ciphertext: Base64 编码的密文
  ///
  /// 安全改进：每次加密生成新的随机 IV，与密文一起返回
  Future<(String iv, String ciphertext)> encryptData(Uint8List data) async {
    if (!_isInitialized) await initialize();
    if (_encrypter == null) {
      throw Exception('Encryption not initialized');
    }

    // 每次加密生成新的随机 IV
    final iv = IV.fromSecureRandom(16);
    final enc = _encrypter!.encryptBytes(data, iv: iv);

    return (iv.base64, enc.base64);
  }

  /// 解密字节数据
  ///
  /// 参数：
  /// - ivBase64: Base64 编码的初始化向量
  /// - ciphertextBase64: Base64 编码的密文
  ///
  /// 返回：解密后的原始字节数组
  Future<Uint8List> decryptData(String ivBase64, String ciphertextBase64) async {
    if (!_isInitialized) await initialize();
    if (_encrypter == null) {
      throw Exception('Encryption not initialized');
    }

    final iv = IV.fromBase64(ivBase64);
    final dec = _encrypter!.decryptBytes(Encrypted.fromBase64(ciphertextBase64), iv: iv);
    return Uint8List.fromList(dec);
  }

  /// 加密字节数据（旧接口，向后兼容）
  ///
  /// 参数：
  /// - data：待加密的字节数组
  ///
  /// 返回：加密后的字节数组（包含密文与认证信息）
  @Deprecated('使用 encryptData 代替，返回 IV 和密文')
  Future<Uint8List> encrypt(Uint8List data) async {
    if (!_isInitialized) await initialize();
    if (_encrypter == null) {
      throw Exception('Encryption not initialized');
    }
    // 使用固定 IV 保持向后兼容，但不推荐
    final iv = IV.fromLength(16);
    final enc = _encrypter!.encryptBytes(data, iv: iv);
    return Uint8List.fromList(enc.bytes);
  }

  /// 解密字节数据（旧接口，向后兼容）
  @Deprecated('使用 decryptData 代替，需要传入 IV')
  Future<Uint8List> decrypt(Uint8List encryptedData) async {
    if (!_isInitialized) await initialize();
    if (_encrypter == null) {
      throw Exception('Encryption not initialized');
    }
    // 使用固定 IV 保持向后兼容
    final iv = IV.fromLength(16);
    final dec = _encrypter!.decryptBytes(Encrypted(encryptedData), iv: iv);
    return Uint8List.fromList(dec);
  }

  /// 加密字符串（Base64 编码输出）
  ///
  /// 参数：
  /// - text：待加密的明文字符串
  ///
  /// 返回：包含 IV 和密文的元组 (iv, ciphertext)
  ///
  /// 安全改进：每次加密生成新的随机 IV
  Future<(String iv, String ciphertext)> encryptString(String text) async {
    if (!_isInitialized) await initialize();
    if (_encrypter == null) {
      throw Exception('Encryption not initialized');
    }

    final iv = IV.fromSecureRandom(16);
    final enc = _encrypter!.encrypt(text, iv: iv);

    return (iv.base64, enc.base64);
  }

  /// 解密字符串（Base64 编码输入）
  ///
  /// 参数：
  /// - ivBase64: Base64 编码的初始化向量
  /// - ciphertextBase64: Base64 编码的密文字符串
  ///
  /// 返回：解密后的明文字符串
  Future<String> decryptString(String ivBase64, String ciphertextBase64) async {
    if (!_isInitialized) await initialize();
    if (_encrypter == null) {
      throw Exception('Encryption not initialized');
    }

    final iv = IV.fromBase64(ivBase64);
    return _encrypter!.decrypt(Encrypted.fromBase64(ciphertextBase64), iv: iv);
  }

  /// 加密 Map 数据
  ///
  /// 流程：先序列化为 JSON 字符串，再进行字符串加密。
  ///
  /// 返回：包含以下键的 Map：
  /// - encrypted: 是否加密（true）
  /// - iv: Base64 编码的初始化向量
  /// - data: Base64 密文
  /// - timestamp: ISO8601 时间戳
  Future<Map<String, dynamic>> encryptMap(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    final (iv, ciphertext) = await encryptString(jsonString);
    return {
      'encrypted': true,
      'iv': iv,
      'data': ciphertext,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 解密 Map 数据
  ///
  /// 若传入的数据未标记为加密（encrypted != true），将原样返回副本。
  Future<Map<String, dynamic>> decryptMap(
    Map<String, dynamic> encryptedData,
  ) async {
    if (encryptedData['encrypted'] != true) {
      return Map<String, dynamic>.from(encryptedData);
    }
    final iv = encryptedData['iv'] as String?;
    final encryptedString = encryptedData['data'] as String?;
    if (iv == null || encryptedString == null) return <String, dynamic>{};
    final decryptedString = await decryptString(iv, encryptedString);
    final decoded = jsonDecode(decryptedString);
    return decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
  }

  /// 重新生成并替换持久化密钥
  ///
  /// 注意：更换密钥后，之前的密文将无法解密，请确保有迁移方案。
  Future<void> changeEncryptionKey() async {
    final prefs = await SharedPreferences.getInstance();
    final newKey = Key.fromSecureRandom(32);
    await prefs.setString('encryption_key', base64Encode(newKey.bytes));
    // 移除旧的 IV（不再需要）
    await prefs.remove('encryption_iv');
    _encrypter = Encrypter(AES(newKey, mode: AESMode.gcm));
  }

  /// 清空持久化的密钥，并重置初始化状态
  Future<void> clearEncryptionKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('encryption_key');
    await prefs.remove('encryption_iv'); // 移除旧的 IV
    _encrypter = null;
    _isInitialized = false;
  }

  /// 是否已启用加密（初始化完成且存在 Encrypter）
  bool get isEncryptionEnabled => _isInitialized && _encrypter != null;

  /// 生成随机密钥（Base64 字符串，长度约 44）
  ///
  /// 使用安全随机源生成 32 字节作为 AES-256 密钥。
  static String generateRandomKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// 判断密钥是否足够强（简单启发式）
  ///
  /// 要求：
  /// - Base64 字符串长度 >= 32
  /// - 解码后字节的去重数量 >= 20
  static bool isKeyStrong(String key) {
    if (key.length < 32) return false;
    final bytes = base64Decode(key);
    return bytes.toSet().length >= 20;
  }

  /// 获取当前密钥信息
  ///
  /// 返回：
  /// - hasKey: 是否存在密钥
  /// - keyLength: 密钥字符串长度（Base64）
  /// - isStrong: 是否满足强度要求
  /// - algorithm: 使用的算法（AES-256-GCM）
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
