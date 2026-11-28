import 'dart:async';
import 'package:flutter/widgets.dart';
import 'completion_notifications_stub.dart'
    if (dart.library.io) 'completion_notifications_mobile.dart'
    if (dart.library.js_interop) 'completion_notifications_web.dart' as platform;

/// Notification failures must never turn a completed analysis into an error.
class CompletionNotifications {
  static bool requestingPermission = false;
  static final RouteObserver<PageRoute<dynamic>> routeObserver = _AnalysisRouteObserver();
  static Object? _visibleScreen;
  static Route<dynamic>? _visibleRoute;

  static void showAnalyze(Object screen, Route<dynamic> route) {
    _visibleScreen = screen;
    _visibleRoute = route;
    unawaited(_setVisible(true));
  }

  static void hideAnalyze(Object screen) {
    if (!identical(_visibleScreen, screen)) return;
    _visibleScreen = null;
    _visibleRoute = null;
    unawaited(_setVisible(false));
  }

  static void _hideRoute(Route<dynamic>? route) {
    if (route != null && identical(_visibleRoute, route)) {
      final screen = _visibleScreen;
      if (screen != null) hideAnalyze(screen);
    }
  }

  static Future<void> _setVisible(bool visible) async {
    try { await platform.setAnalyzeVisible(visible); } catch (_) { /* Optional alerts. */ }
  }
  static Future<void> prepare() async {
    requestingPermission = true;
    try { await platform.prepare(); } catch (_) { /* Optional permission. */ }
    finally { requestingPermission = false; }
  }
  static Future<void> done() async {
    try { await platform.done(); } catch (_) { /* Result remains available. */ }
  }
}

class _AnalysisRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    CompletionNotifications._hideRoute(oldRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    CompletionNotifications._hideRoute(route);
    super.didRemove(route, previousRoute);
  }
}
