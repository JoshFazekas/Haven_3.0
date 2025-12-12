import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haven/core/services/ble_debug_service.dart';

/// Modal bottom sheet that displays BLE communication logs
class BleDebugModal extends StatefulWidget {
  const BleDebugModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BleDebugModal(),
    );
  }

  @override
  State<BleDebugModal> createState() => _BleDebugModalState();
}

class _BleDebugModalState extends State<BleDebugModal> {
  final BleDebugService _debugService = BleDebugService();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<BleLogEntry>? _logSubscription;
  List<BleLogEntry> _logs = [];
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _logs = List.from(_debugService.logs);
    
    // Listen for new logs
    _logSubscription = _debugService.logStream.listen((entry) {
      if (mounted) {
        setState(() {
          _logs.add(entry);
        });
        
        // Auto-scroll to bottom
        if (_autoScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Color _getTypeColor(BleLogType type) {
    switch (type) {
      case BleLogType.tx:
        return const Color(0xFF22C55E); // Green
      case BleLogType.rx:
        return const Color(0xFF3B82F6); // Blue
      case BleLogType.event:
        return const Color(0xFF8B5CF6); // Purple
      case BleLogType.error:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData _getTypeIcon(BleLogType type) {
    switch (type) {
      case BleLogType.tx:
        return Icons.arrow_upward;
      case BleLogType.rx:
        return Icons.arrow_downward;
      case BleLogType.event:
        return Icons.info_outline;
      case BleLogType.error:
        return Icons.error_outline;
    }
  }

  void _copyLogs() {
    final buffer = StringBuffer();
    for (final log in _logs) {
      buffer.writeln('[${log.formattedTime}] ${log.typeString} ${log.characteristicName}: ${log.data}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearLogs() {
    _debugService.clear();
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bug_report,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BLE Debug Console',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'TX/RX Communication Log',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Auto-scroll toggle
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _autoScroll = !_autoScroll;
                        });
                      },
                      icon: Icon(
                        _autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center,
                        color: _autoScroll ? const Color(0xFF22C55E) : Colors.grey,
                      ),
                      tooltip: 'Auto-scroll',
                    ),
                    // Copy button
                    IconButton(
                      onPressed: _logs.isEmpty ? null : _copyLogs,
                      icon: Icon(
                        Icons.copy,
                        color: _logs.isEmpty ? Colors.grey.shade700 : Colors.white,
                      ),
                      tooltip: 'Copy logs',
                    ),
                    // Clear button
                    IconButton(
                      onPressed: _logs.isEmpty ? null : _clearLogs,
                      icon: Icon(
                        Icons.delete_outline,
                        color: _logs.isEmpty ? Colors.grey.shade700 : Colors.red,
                      ),
                      tooltip: 'Clear logs',
                    ),
                  ],
                ),
              ),
              
              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildLegendItem('TX →', const Color(0xFF22C55E)),
                    const SizedBox(width: 16),
                    _buildLegendItem('RX ←', const Color(0xFF3B82F6)),
                    const SizedBox(width: 16),
                    _buildLegendItem('EVENT', const Color(0xFF8B5CF6)),
                    const SizedBox(width: 16),
                    _buildLegendItem('ERROR', const Color(0xFFEF4444)),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              const Divider(color: Colors.grey, height: 1),
              
              // Log list
              Expanded(
                child: _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bluetooth_searching,
                              size: 48,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No logs yet',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start provisioning to see TX/RX data',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return _buildLogEntry(_logs[index]);
                        },
                      ),
              ),
              
              // Bottom safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildLogEntry(BleLogEntry entry) {
    final color = _getTypeColor(entry.type);
    final icon = _getTypeIcon(entry.type);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.formattedTime,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        entry.typeString,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.characteristicName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (entry.data.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      entry.data,
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
