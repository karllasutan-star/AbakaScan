import 'package:flutter/material.dart';

Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) {
      return page;
    },
    transitionDuration: const Duration(milliseconds: 160),
    reverseTransitionDuration: const Duration(milliseconds: 140),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      );

      return FadeTransition(opacity: curvedAnimation, child: child);
    },
  );
}

/// Use this for the main authenticated sections:
/// Analyze, History, Samples, Reports, Profile, Settings, About.
///
/// If we are currently on Dashboard, push the section.
/// If we are already inside another section, replace it instead of
/// stacking another full dashboard page.
Future<T?> openSection<T>(BuildContext context, Widget page) {
  final navigator = Navigator.of(context);

  final isRootRoute = ModalRoute.of(context)?.isFirst ?? false;

  if (isRootRoute) {
    return navigator.push<T>(fadeRoute<T>(page));
  }

  return navigator.pushReplacement<T, dynamic>(fadeRoute<T>(page));
}

/// Return to the authenticated Dashboard/root.
void returnToDashboard(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
}
