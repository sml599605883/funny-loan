import 'dart:math';

abstract class RandomUtil {
  static final Random _random = Random();

  static String numeric(int length) {
    final buffer = StringBuffer();
    for (int index = 0; index < length; index++) {
      buffer.write(_random.nextInt(10));
    }
    return buffer.toString();
  }
}
