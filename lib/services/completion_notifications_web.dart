import 'dart:js_interop';

@JS('abakascanNotifications.prepare')
external JSPromise<JSAny?> _prepare();
@JS('abakascanNotifications.done')
external JSPromise<JSAny?> _done();
Future<void> prepare() async { await _prepare().toDart; }
Future<void> done() async { await _done().toDart; }

@JS('abakascanNotifications.setAnalyzeVisible')
external void _setAnalyzeVisible(bool visible);
Future<void> setAnalyzeVisible(bool visible) async { _setAnalyzeVisible(visible); }
