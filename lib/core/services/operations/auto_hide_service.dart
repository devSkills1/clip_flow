import 'dart:async';

import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum to track how the window was activated
enum WindowActivationSource {
  /// Activated via global hotkey
  hotkey,

  /// Activated via system tray icon
  tray,

  /// Not activated / Initial state
  none,
}

/// Service to manage auto-hide functionality when summoned via hotkey.
class AutoHideService {
  /// Creates a new instance of [AutoHideService].
  AutoHideService(this._ref);

  final Ref _ref;
  Timer? _inactivityTimer;
  final Stopwatch _interactionStopwatch = Stopwatch();
  bool get _isEnabled => _ref.read(userPreferencesProvider).autoHideEnabled;

  Duration get _timeoutDuration {
    final seconds = _ref.read(userPreferencesProvider).autoHideTimeoutSeconds;
    final clampedSeconds = seconds < 3
        ? 3
        : (seconds > 30 ? 30 : seconds);
    return Duration(seconds: clampedSeconds);
  }

  /// Start monitoring for inactivity.
  void startMonitoring() {
    if (!_isEnabled) {
      _resetStopwatch();
      _cancelTimer();
      return;
    }
    _cancelTimer();
    unawaited(
      Log.d('AutoHideService: Started monitoring', tag: 'AutoHideService'),
    );

    _markInteraction();
    _startTimer();
  }

  /// Stop monitoring.
  void stopMonitoring() {
    final hadTimer = _inactivityTimer != null;
    final hadStopwatch = _interactionStopwatch.isRunning;
    _cancelTimer();
    _resetStopwatch();
    if (!hadTimer && !hadStopwatch) {
      return;
    }
    unawaited(
      Log.d('AutoHideService: Stopped monitoring', tag: 'AutoHideService'),
    );
  }

  /// Call this when user interacts with the app.
  void onUserInteraction() {
    if (!_isEnabled) {
      return;
    }
    _markInteraction();
    if (_inactivityTimer != null && _inactivityTimer!.isActive) {
      _startTimer();
    }
  }

  void _startTimer() {
    _cancelTimer();
    _inactivityTimer = Timer(_timeoutDuration, _handleTimeout);
  }

  Future<void> _handleTimeout() async {
    if (!_isEnabled) {
      _cancelTimer();
      _resetStopwatch();
      return;
    }
    final elapsed = _interactionStopwatch.elapsed;
    if (elapsed < _timeoutDuration) {
      unawaited(
        Log.d(
          'AutoHideService: Timer fired early, restarting '
          '(elapsed=${elapsed.inMilliseconds}ms)',
          tag: 'AutoHideService',
        ),
      );
      _startTimer();
      return;
    }

    unawaited(
      Log.i(
        'AutoHideService: Inactivity timeout reached, hiding window',
        tag: 'AutoHideService',
      ),
    );

    // Use TrayService to hide, ensuring consistent state
    try {
      final trayService = await _ref.read(trayServiceProvider.future);
      await trayService.hideWindow();
      _cancelTimer();
    } on Exception catch (e) {
      unawaited(
        Log.e(
          'Failed to hide window in AutoHideService',
          error: e,
          tag: 'AutoHideService',
        ),
      );
      _startTimer();
    }
  }

  void _cancelTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _markInteraction() {
    _interactionStopwatch
      ..reset()
      ..start();
  }

  void _resetStopwatch() {
    if (_interactionStopwatch.isRunning ||
        _interactionStopwatch.elapsedMilliseconds > 0) {
      _interactionStopwatch
        ..stop()
        ..reset();
    }
  }
}
