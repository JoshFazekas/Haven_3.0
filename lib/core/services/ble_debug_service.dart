import 'dart:async';
import 'package:flutter/foundation.dart';

/// Represents a single BLE communication log entry
class BleLogEntry {
  final DateTime timestamp;
  final BleLogType type;
  final String characteristicName;
  final String data;
  final String? error;
  final bool isSuccess;

  BleLogEntry({
    required this.timestamp,
    required this.type,
    required this.characteristicName,
    required this.data,
    this.error,
    this.isSuccess = true,
  });

  String get formattedTime {
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.$ms';
  }

  String get typeString {
    switch (type) {
      case BleLogType.tx:
        return 'TX →';
      case BleLogType.rx:
        return 'RX ←';
      case BleLogType.event:
        return 'EVENT';
      case BleLogType.error:
        return 'ERROR';
    }
  }
}

enum BleLogType {
  tx,    // Data sent to device
  rx,    // Data received from device
  event, // Connection events, service discovery, etc.
  error, // Errors
}

/// Singleton service for capturing BLE debug logs
class BleDebugService {
  static final BleDebugService _instance = BleDebugService._internal();
  factory BleDebugService() => _instance;
  BleDebugService._internal();

  final List<BleLogEntry> _logs = [];
  final _logController = StreamController<BleLogEntry>.broadcast();

  /// Stream of new log entries
  Stream<BleLogEntry> get logStream => _logController.stream;

  /// Get all logs
  List<BleLogEntry> get logs => List.unmodifiable(_logs);

  /// Log a TX (transmit) operation
  void logTx(String characteristic, String data, {bool success = true, String? error}) {
    final entry = BleLogEntry(
      timestamp: DateTime.now(),
      type: success ? BleLogType.tx : BleLogType.error,
      characteristicName: characteristic,
      data: data,
      error: error,
      isSuccess: success,
    );
    _addLog(entry);
  }

  /// Log an RX (receive) operation
  void logRx(String characteristic, String data) {
    final entry = BleLogEntry(
      timestamp: DateTime.now(),
      type: BleLogType.rx,
      characteristicName: characteristic,
      data: data,
      isSuccess: true,
    );
    _addLog(entry);
  }

  /// Log a BLE event (connection, service discovery, etc.)
  void logEvent(String event, {String? details}) {
    final entry = BleLogEntry(
      timestamp: DateTime.now(),
      type: BleLogType.event,
      characteristicName: event,
      data: details ?? '',
      isSuccess: true,
    );
    _addLog(entry);
  }

  /// Log an error
  void logError(String operation, String error) {
    final entry = BleLogEntry(
      timestamp: DateTime.now(),
      type: BleLogType.error,
      characteristicName: operation,
      data: error,
      error: error,
      isSuccess: false,
    );
    _addLog(entry);
  }

  void _addLog(BleLogEntry entry) {
    _logs.add(entry);
    _logController.add(entry);
    debugPrint('[BLE ${entry.typeString}] ${entry.characteristicName}: ${entry.data}');
  }

  /// Clear all logs
  void clear() {
    _logs.clear();
    debugPrint('[BLE DEBUG] Logs cleared');
  }

  void dispose() {
    _logController.close();
  }
}
