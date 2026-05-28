import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class CryptoUtil {
  const CryptoUtil({
    required this.key,
    required this.iv,
  });

  final String key;
  final String iv;

  String encryptToBase64(String plainText) {
    if (plainText.isEmpty) {
      return '';
    }
    final cipher = _buildCipher(true);
    final output = cipher.process(Uint8List.fromList(utf8.encode(plainText)));
    return base64Encode(output);
  }

  String decryptFromBase64(String cipherText) {
    if (cipherText.isEmpty) {
      return '';
    }
    final cipher = _buildCipher(false);
    final output = cipher.process(base64Decode(cipherText));
    return utf8.decode(output);
  }

  PaddedBlockCipherImpl _buildCipher(bool forEncryption) {
    final paddedCipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    );
    paddedCipher.init(
      forEncryption,
      PaddedBlockCipherParameters<CipherParameters, CipherParameters>(
        ParametersWithIV<KeyParameter>(
          KeyParameter(Uint8List.fromList(utf8.encode(key))),
          Uint8List.fromList(utf8.encode(iv)),
        ),
        null,
      ),
    );
    return paddedCipher;
  }
}
