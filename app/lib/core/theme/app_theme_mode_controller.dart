import 'package:flutter/material.dart';

/// Minimal light/dark mode controller (Phase 15: "Support light mode and
/// dark mode"). Defaults to following the OS setting; Phase 4's Profile ->
/// Settings screen will let users override this explicitly.
class AppThemeModeController extends ValueNotifier<ThemeMode> {
  AppThemeModeController() : super(ThemeMode.system);

  void setMode(ThemeMode mode) => value = mode;
}
