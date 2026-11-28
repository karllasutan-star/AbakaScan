import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('abakascan/completion_notifications');
Future<void> prepare() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    await _channel.invokeMethod<bool>('prepare');
  }
}
Future<void> done() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    await _channel.invokeMethod<void>('done');
  }
}

Future<void> setAnalyzeVisible(bool visible) async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    await _channel.invokeMethod<void>('setAnalyzeVisible', {'visible': visible});
  }
}
