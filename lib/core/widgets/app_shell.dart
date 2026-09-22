// lib/core/widgets/app_shell.dart
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'app_scaffold.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final UserRole userRole;

  const AppShell({
    super.key,
    required this.child,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(child: child);
  }
}
