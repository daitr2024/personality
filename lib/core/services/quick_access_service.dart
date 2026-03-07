import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quickAccessServiceProvider = Provider((ref) => QuickAccessService());

class QuickAccessService {
  static const platform = MethodChannel(
    'com.daitr2024.personalityai/quick_actions',
  );

  Future<String?> checkPendingAction() async {
    try {
      final String? action = await platform.invokeMethod('checkPendingAction');
      return action;
    } on PlatformException catch (_) {
      return null;
    }
  }

  void setMethodCallHandler(Future<void> Function(MethodCall call) handler) {
    platform.setMethodCallHandler(handler);
  }
}
