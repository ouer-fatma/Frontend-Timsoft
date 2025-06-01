import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000'; // 🔁 Or your real backend for web
    } else {
      return dotenv.env['BASE_URL'] ?? 'http://localhost:3000';
    }
  }
}
