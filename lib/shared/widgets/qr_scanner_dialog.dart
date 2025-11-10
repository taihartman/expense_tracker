import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/l10n/l10n_extensions.dart';
import '../../core/utils/link_utils.dart';

/// A dialog that displays a QR code scanner
///
/// Uses the device camera to scan QR codes containing trip invite URLs.
/// Automatically extracts the trip ID from the scanned URL and closes the dialog.
///
/// Returns the trip ID if a valid trip QR code is scanned, null otherwise.
///
/// Example:
/// ```dart
/// final tripId = await showDialog<String>(
///   context: context,
///   builder: (context) => const QrScannerDialog(),
/// );
/// if (tripId != null) {
///   // Use the trip ID to load the trip
/// }
/// ```
class QrScannerDialog extends StatefulWidget {
  const QrScannerDialog({super.key});

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  String? _errorMessage;
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final scannedValue = barcode.rawValue;

    if (scannedValue == null || scannedValue.isEmpty) {
      _showError(context.l10n.tripJoinInvalidQrCode);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Extract trip ID from the scanned URL
    final tripId = extractTripIdFromQrUrl(scannedValue);

    if (tripId == null || tripId.isEmpty) {
      _showError(context.l10n.tripJoinInvalidQrCode);
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    // Success! Return the trip ID and close the dialog
    if (mounted) {
      Navigator.of(context).pop(tripId);
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });

    // Clear error after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600;

    return Dialog(
      insetPadding: isMobile ? EdgeInsets.zero : const EdgeInsets.all(40),
      child: Container(
        width: isMobile ? double.infinity : 600,
        height: isMobile ? double.infinity : 700,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: isMobile ? null : BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Camera view
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          error.errorCode == MobileScannerErrorCode.permissionDenied
                              ? context.l10n.tripJoinCameraPermissionDenied
                              : context.l10n.tripJoinQrScannerError,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Top bar with title and close button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: mediaQuery.padding.top + 8,
                  left: 8,
                  right: 8,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        context.l10n.tripJoinScanningQrCode,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: context.l10n.tripJoinQrScannerClose,
                    ),
                  ],
                ),
              ),
            ),

            // Center scanning guide
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Corner decorations
                    ...List.generate(4, (index) {
                      final isTop = index < 2;
                      final isLeft = index % 2 == 0;
                      return Positioned(
                        top: isTop ? 0 : null,
                        bottom: !isTop ? 0 : null,
                        left: isLeft ? 0 : null,
                        right: !isLeft ? 0 : null,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.only(
                              topLeft: isTop && isLeft
                                  ? const Radius.circular(9)
                                  : Radius.zero,
                              topRight: isTop && !isLeft
                                  ? const Radius.circular(9)
                                  : Radius.zero,
                              bottomLeft: !isTop && isLeft
                                  ? const Radius.circular(9)
                                  : Radius.zero,
                              bottomRight: !isTop && !isLeft
                                  ? const Radius.circular(9)
                                  : Radius.zero,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom instruction text
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: mediaQuery.padding.bottom + 16,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  context.l10n.tripJoinScanQrTooltip,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Error message overlay
            if (_errorMessage != null)
              Positioned(
                bottom: mediaQuery.padding.bottom + 80,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Processing overlay
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.tripJoinQrCodeScanned,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
