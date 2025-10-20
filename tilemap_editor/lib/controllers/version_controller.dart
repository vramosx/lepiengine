import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionController extends ChangeNotifier {
  VersionController._internal();

  static final VersionController _instance = VersionController._internal();
  static VersionController get instance => _instance;

  String? _version;
  String? get version => _version;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    if (_isLoaded) return;
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _version = packageInfo.version;
    _isLoaded = true;
    notifyListeners();
  }
}
