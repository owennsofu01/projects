import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// The outcome of handling one scan in continuous mode, shown as feedback
/// over the camera.
class ScanFeedback {
  const ScanFeedback.success(this.message) : isError = false;
  const ScanFeedback.error(this.message) : isError = true;

  final String message;
  final bool isError;
}

/// Full-screen camera barcode scanner.
///
/// With no [onScan], pops with the first code read (e.g. to fill a
/// product's barcode field). With [onScan], stays open and calls it for
/// every code, so a whole basket can be scanned in one go.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({
    super.key,
    this.title = 'Scan barcode',
    this.onScan,
  });

  final String title;
  final ScanFeedback Function(String code)? onScan;

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  /// The same code is ignored for this long, so holding an item in front
  /// of the camera adds it once rather than many times a second.
  static const _repeatCooldown = Duration(milliseconds: 1500);

  final MobileScannerController _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.qrCode,
    ],
  );

  String? _lastCode;
  DateTime _lastScanAt = DateTime.fromMillisecondsSinceEpoch(0);
  ScanFeedback? _feedback;
  int _scanCount = 0;
  bool _popped = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes
        .map((b) => b.rawValue?.trim())
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (code == null) return;

    final onScan = widget.onScan;
    if (onScan == null) {
      if (_popped) return;
      _popped = true;
      Navigator.of(context).pop(code);
      return;
    }

    final now = DateTime.now();
    if (code == _lastCode && now.difference(_lastScanAt) < _repeatCooldown) {
      return;
    }
    _lastCode = code;
    _lastScanAt = now;

    final feedback = onScan(code);
    setState(() {
      _feedback = feedback;
      if (!feedback.isError) _scanCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final continuous = widget.onScan != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              if (state.torchState == TorchState.unavailable) {
                return const SizedBox.shrink();
              }
              final on = state.torchState == TorchState.on;
              return IconButton(
                tooltip: on ? 'Turn off flash' : 'Turn on flash',
                icon: Icon(on ? Icons.flash_on : Icons.flash_off),
                onPressed: _controller.toggleTorch,
              );
            },
          ),
          if (continuous)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _scanCount == 0 ? 'Done' : 'Done ($_scanCount)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final windowWidth = (constraints.maxWidth * 0.8).clamp(0.0, 360.0);
          final scanWindow = Rect.fromCenter(
            center: constraints.biggest.center(Offset.zero),
            width: windowWidth,
            height: windowWidth * 0.6,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                scanWindow: scanWindow,
                onDetect: _onDetect,
                errorBuilder: (context, error) => _ScannerError(error: error),
              ),
              IgnorePointer(
                child: CustomPaint(painter: _WindowPainter(scanWindow)),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: scanWindow.bottom + 24,
                child: Text(
                  continuous
                      ? 'Point at a barcode — each scan adds one to the sale'
                      : 'Point the camera at the barcode',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              if (_feedback != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 32,
                  child: SafeArea(child: _FeedbackBanner(feedback: _feedback!)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.feedback});

  final ScanFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final color = feedback.isError
        ? Colors.red.shade700
        : Colors.green.shade700;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        // Keyed on the message so repeated scans re-animate.
        key: ValueKey(feedback.message + feedback.isError.toString()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              feedback.isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                feedback.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Camera access is off. Allow camera access for ProfitPulse in your '
            'phone settings to scan barcodes.',
      MobileScannerErrorCode.unsupported =>
        'This device has no camera that can scan barcodes.',
      _ => 'The camera could not start. Please try again.',
    };

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white70,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dims everything outside the scan window and outlines the window.
class _WindowPainter extends CustomPainter {
  const _WindowPainter(this.window);

  final Rect window;

  @override
  void paint(Canvas canvas, Size size) {
    final rounded = RRect.fromRectAndRadius(window, const Radius.circular(16));
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(rounded),
      ),
      Paint()..color = Colors.black54,
    );
    canvas.drawRRect(
      rounded,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_WindowPainter oldDelegate) =>
      oldDelegate.window != window;
}
