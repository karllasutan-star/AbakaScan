import '../services/completion_notifications.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_providers.dart';
import '../services/offline_mobile.dart';

class OfflineWorkspace extends StatefulWidget {
  const OfflineWorkspace({super.key, required this.child});
  final Widget child;
  @override
  State<OfflineWorkspace> createState() => _OfflineWorkspaceState();
}

class _OfflineWorkspaceState extends State<OfflineWorkspace>
    with WidgetsBindingObserver {
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!OfflineMobile.enabled ||
        OfflineMobile.instance.authenticating ||
        CompletionNotifications.requestingPermission) {
      return;
    }
    // Camera/gallery are trusted external activities initiated by this app.
    // Keep the current image-selection route alive while they return.
    if (context.read<ImageSelectionProvider>().loading) return;
    if (context.read<AuthProvider>().isUser &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden)) {
      unawaited(OfflineMobile.instance.lock().catchError((Object _) {}));
    }
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await OfflineMobile.instance.unlock();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unlock was cancelled or unavailable. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!OfflineMobile.enabled || !auth.isUser) return widget.child;
    return ValueListenableBuilder<bool>(
      valueListenable: OfflineMobile.instance.unlocked,
      builder: (context, unlocked, _) {
        Widget lockedScreen() {
          return Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Unlock AbakaScan',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Use your phone screen lock to continue. No Internet is needed.',
                          textAlign: TextAlign.center,
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(_error!),
                          ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _busy ? null : _unlock,
                          child: Text(_busy ? 'Unlocking…' : 'Unlock'),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () async {
                                  context
                                      .read<ImageSelectionProvider>()
                                      .removeImage();
                                  context
                                      .read<ClassificationProvider>()
                                      .reset();
                                  context.read<HistoryProvider>().reset();
                                  context.read<AdminProvider>().reset();
                                  await auth.logout();
                                },
                          child: const Text('Log out'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final workspace = Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.offline_bolt_outlined, size: 16),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Offline workspace · Saved on this phone',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Check offline models',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.fact_check_outlined, size: 18),
                        onPressed: () async {
                          try {
                            final report = await OfflineMobile.instance
                                .selfTest();
                            if (context.mounted) {
                              showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Offline model check'),
                                  content: SelectableText(report.toString()),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: widget.child),
          ],
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            Offstage(offstage: !unlocked, child: workspace),
            if (!unlocked) Positioned.fill(child: lockedScreen()),
          ],
        );
      },
    );
  }
}
