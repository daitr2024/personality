import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quickAccessServiceProvider = Provider((ref) => QuickAccessService());

class QuickAccessService {
  static const platform = MethodChannel(
    'com.daitr2024.personalityai/quick_actions',
  );

  /// Check for pending action from widget/tile/wear.
  /// Returns either a String action name, or a Map with 'action' and 'voiceText'
  /// for wear voice input.
  Future<dynamic> checkPendingAction() async {
    try {
      final result = await platform.invokeMethod('checkPendingAction');
      return result;
    } on PlatformException catch (_) {
      return null;
    }
  }

  void setMethodCallHandler(Future<void> Function(MethodCall call) handler) {
    platform.setMethodCallHandler(handler);
  }
}
