import 'dart:io';

class Config {
  final String host;
  final int port;
  final String dataDir;
  final String adminPassword;
  final int privacyRetentionDays;
  final List<String> productList;

  const Config({
    required this.host,
    required this.port,
    required this.dataDir,
    required this.adminPassword,
    required this.privacyRetentionDays,
    required this.productList,
  });

  /// .env 파일 → 환경변수 → 기본값 순서로 로드
  factory Config.load({String envFile = '.env'}) {
    final env = <String, String>{};

    // 1) .env 파일 읽기
    final file = File(envFile);
    if (file.existsSync()) {
      for (final line in file.readAsLinesSync()) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final idx = trimmed.indexOf('=');
        if (idx < 0) continue;
        final key = trimmed.substring(0, idx).trim();
        var value = trimmed.substring(idx + 1).trim();
        // 따옴표 제거
        if ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"))) {
          value = value.substring(1, value.length - 1);
        }
        env[key] = value;
      }
    }

    // 2) 환경변수가 있으면 .env보다 우선
    String get(String key, String defaultValue) {
      return Platform.environment[key] ?? env[key] ?? defaultValue;
    }

    return Config(
      host: get('HOST', '0.0.0.0'),
      port: int.parse(get('PORT', '8080')),
      dataDir: get('DATA_DIR', './data'),
      adminPassword: get('ADMIN_PASSWORD', 'admin1234'),
      privacyRetentionDays: int.parse(get('PRIVACY_RETENTION_DAYS', '365')),
      productList: get('PRODUCT_LIST', '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }

  void printConfig() {
    print('=== Server Config ===');
    print('HOST: $host');
    print('PORT: $port');
    print('DATA_DIR: $dataDir');
    print('ADMIN_PASSWORD: ${'*' * adminPassword.length}');
    print('PRIVACY_RETENTION_DAYS: $privacyRetentionDays');
    print('PRODUCT_LIST: ${productList.join(', ')}');
    print('=====================');
  }
}
