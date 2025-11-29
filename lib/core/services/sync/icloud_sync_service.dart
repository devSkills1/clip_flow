import 'dart:io' show Platform;

import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Supported CloudKit database scopes.
enum ICloudDatabaseScope {
  private,
  public,
  shared,
}

extension _ICloudScopeWireName on ICloudDatabaseScope {
  String get wireName {
    switch (this) {
      case ICloudDatabaseScope.private:
        return 'private';
      case ICloudDatabaseScope.public:
        return 'public';
      case ICloudDatabaseScope.shared:
        return 'shared';
    }
  }
}

/// Configuration payload for iCloud synchronization.
class ICloudSyncConfig {
  const ICloudSyncConfig({
    required this.containerId,
    this.recordType = 'ClipItem',
    this.subscriptionId = 'clipflow_sync_subscription',
    this.databaseScope = ICloudDatabaseScope.private,
  });

  final String containerId;
  final String recordType;
  final String subscriptionId;
  final ICloudDatabaseScope databaseScope;

  Map<String, dynamic> toJson() {
    return {
      'containerId': containerId,
      'recordType': recordType,
      'subscriptionId': subscriptionId,
      'databaseScope': databaseScope.wireName,
    };
  }
}

/// Service responsible for bridging Flutter code with the native CloudKit layer.
class ICloudSyncService {
  ICloudSyncService._();

  static final ICloudSyncService instance = ICloudSyncService._();

  static const MethodChannel _channel = MethodChannel('icloud_sync');

  bool _isConfigured = false;
  ICloudSyncConfig? _config;

  bool get _isMacOS => !kIsWeb && Platform.isMacOS;

  /// Whether the service can talk to the native implementation.
  bool get isAvailable => _isMacOS && _isConfigured;

  /// Configures the native CloudKit bridge on macOS.
  Future<void> configure(ICloudSyncConfig config) async {
    _config = config;

    if (!_isMacOS) {
      _isConfigured = false;
      return;
    }

    try {
      await _channel.invokeMethod<void>('initialize', config.toJson());
      _isConfigured = true;
      await Log.i(
        'iCloud sync configured',
        tag: 'ICloudSyncService',
        fields: config.toJson(),
      );
    } on PlatformException catch (e, stackTrace) {
      _isConfigured = false;
      await Log.w(
        'Failed to configure iCloud sync',
        tag: 'ICloudSyncService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } on Exception catch (e, stackTrace) {
      _isConfigured = false;
      await Log.w(
        'Unexpected error while configuring iCloud sync',
        tag: 'ICloudSyncService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Upserts a single clip item to CloudKit.
  Future<void> upsertClipItem(ClipItem clip) async {
    if (!isAvailable) return;

    await _invokeWithoutResult(
      'upsertClip',
      {'record': clip.toJson()},
    );
  }

  /// Deletes a clip item from CloudKit using its identifier.
  Future<void> deleteClipItem(String id) async {
    if (!isAvailable) return;

    await _invokeWithoutResult(
      'deleteClip',
      {'id': id},
    );
  }

  /// Fetches remote clip items, optionally filtering by last update timestamp.
  Future<List<ClipItem>> fetchRemoteClips({DateTime? since}) async {
    if (!isAvailable) return const [];

    try {
      final payload = <String, dynamic>{};
      if (since != null) {
        payload['since'] = since.toUtc().toIso8601String();
      }

      final response = await _channel.invokeMethod<List<dynamic>>(
        'fetchClips',
        payload,
      );

      final items = response ?? const [];
      return items
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> raw) =>
              Map<String, dynamic>.from(raw.cast<String, dynamic>()))
          .map(ClipItem.fromJson)
          .toList();
    } on PlatformException catch (e, stackTrace) {
      await Log.w(
        'Failed to fetch remote clips from iCloud',
        tag: 'ICloudSyncService',
        error: e,
        stackTrace: stackTrace,
      );
      return const [];
    } on Exception catch (e, stackTrace) {
      await Log.w(
        'Unexpected error while fetching iCloud clips',
        tag: 'ICloudSyncService',
        error: e,
        stackTrace: stackTrace,
      );
      return const [];
    }
  }

  Future<void> _invokeWithoutResult(
    String method,
    Map<String, dynamic> arguments,
  ) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException catch (e, stackTrace) {
      await Log.w(
        'iCloud sync method failed',
        tag: 'ICloudSyncService',
        fields: {
          'method': method,
        },
        error: e,
        stackTrace: stackTrace,
      );
    } on Exception catch (e, stackTrace) {
      await Log.w(
        'Unexpected iCloud sync error',
        tag: 'ICloudSyncService',
        fields: {
          'method': method,
        },
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
