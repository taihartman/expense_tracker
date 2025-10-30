import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';

/// A floating debug panel that shows routing and app state information.
///
/// Displays logs and routing state directly on screen (no console needed).
/// Only visible when `AppConfig.enableDebugPanel` is true.
class DebugPanel extends StatefulWidget {
  final List<String> logs;
  final Map<String, dynamic>? routingState;

  const DebugPanel({
    super.key,
    required this.logs,
    this.routingState,
  });

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  bool _isExpanded = true;
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    // Don't show if debug panel is disabled
    if (!AppConfig.enableDebugPanel) {
      return const SizedBox.shrink();
    }

    // Minimized state - show small FAB
    if (!_isVisible) {
      return Positioned(
        bottom: 16,
        right: 16,
        child: FloatingActionButton.small(
          backgroundColor: Colors.orange,
          heroTag: 'debug_panel_fab',
          onPressed: () => setState(() => _isVisible = true),
          child: const Icon(Icons.bug_report, size: 20),
        ),
      );
    }

    // Full panel
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(),

              // Content (only when expanded)
              if (_isExpanded) ...[
                // Routing State
                if (widget.routingState != null && widget.routingState!.isNotEmpty)
                  _buildRoutingState(),

                // Logs
                _buildLogs(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report, size: 20, color: Colors.black),
          const SizedBox(width: 8),
          const Text(
            'DEBUG PANEL',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.expand_more : Icons.expand_less,
              color: Colors.black,
            ),
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 20,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black, size: 20),
            onPressed: () => setState(() => _isVisible = false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutingState() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ROUTING STATE:',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          ...widget.routingState!.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${entry.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildLogs() {
    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxHeight: 250),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'LOGS:',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _copyLogsToClipboard,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'COPY',
                  style: TextStyle(fontSize: 10, color: Colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: widget.logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs yet',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  )
                : SingleChildScrollView(
                    reverse: true, // Show latest logs at bottom
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.logs
                          .map((log) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  log,
                                  style: TextStyle(
                                    color: _getLogColor(log),
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('ERROR') || log.contains('❌') || log.contains('🔴')) {
      return Colors.red;
    }
    if (log.contains('WARN') || log.contains('⚠️')) {
      return Colors.yellow;
    }
    if (log.contains('SUCCESS') || log.contains('✅')) {
      return Colors.green;
    }
    if (log.contains('🔀') || log.contains('REDIRECT')) {
      return Colors.cyan;
    }
    if (log.contains('📍') || log.contains('captured')) {
      return Colors.orange;
    }
    return Colors.white70;
  }

  void _copyLogsToClipboard() {
    final logsText = widget.logs.join('\n');
    Clipboard.setData(ClipboardData(text: logsText));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logs copied to clipboard'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
