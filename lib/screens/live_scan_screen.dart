import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../services/tflite_service.dart';
import 'result_screen.dart';

class LiveScanScreen extends StatefulWidget {
  const LiveScanScreen({super.key});

  @override
  State<LiveScanScreen> createState() => _LiveScanScreenState();
}

class _LiveScanScreenState extends State<LiveScanScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isClassifying = false;
  bool _isTorchOn = false;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _scanTimer;
  Map<String, dynamic>? _liveResult;
  String? _lastCapturedPath;
  final TFLiteService _tfLiteService = TFLiteService();

  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initCamera();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    if (mounted) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      await _tfLiteService.loadModel();

      // Request camera permission explicitly
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Camera permission is required for live scanning.';
          });
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'No camera hardware detected on this device.';
          });
        }
        return;
      }

      final backCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _hasError = false;
      });

      // Start periodic real-time frame scanning timer (every 650ms)
      _scanTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
        _runFrameInference();
      });
    } catch (e) {
      debugPrint('LiveScan Init Error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Could not start camera preview: $e';
        });
      }
    }
  }

  Future<void> _handleFallbackPicker() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.pickImage(ImageSource.camera, context);
    if (mounted && provider.currentPrediction != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ResultScreen()),
      );
    }
  }

  Future<void> _runFrameInference() async {
    if (_controller == null || !_controller!.value.isInitialized || _isClassifying) return;

    try {
      _isClassifying = true;
      final XFile imageFile = await _controller!.takePicture();
      final result = await _tfLiteService.classifyImage(imageFile.path);

      if (mounted && result != null) {
        setState(() {
          _liveResult = result;
          _lastCapturedPath = imageFile.path;
        });
      }
    } catch (e) {
      debugPrint('Live scan frame error: $e');
    } finally {
      _isClassifying = false;
    }
  }

  Future<void> _toggleTorch() async {
    if (_controller == null || !_isInitialized) return;
    try {
      _isTorchOn = !_isTorchOn;
      await _controller!.setFlashMode(_isTorchOn ? FlashMode.torch : FlashMode.off);
      setState(() {});
    } catch (e) {
      debugPrint('Torch Error: $e');
    }
  }

  Future<void> _lockAndProcessResult() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    if (_lastCapturedPath == null || _liveResult == null) {
      // If no frame captured yet, force take picture now
      if (_controller != null && _controller!.value.isInitialized) {
        try {
          final XFile file = await _controller!.takePicture();
          _lastCapturedPath = file.path;
          _liveResult = await _tfLiteService.classifyImage(file.path);
        } catch (e) {
          debugPrint('Lock capture error: $e');
        }
      }
    }

    if (_lastCapturedPath == null || _liveResult == null) return;

    _scanTimer?.cancel();
    await provider.processLiveScanResult(_lastCapturedPath!, _liveResult!);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ResultScreen()),
      );
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _animationController.dispose();
    _controller?.dispose();
    _tfLiteService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = Provider.of<AppProvider>(context);

    if (_hasError || !_isInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0C0A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_hasError) ...[
                  const Icon(Icons.camera_enhance_rounded, color: Color(0xFFFBC02D), size: 56),
                  const SizedBox(height: 16),
                  Text(
                    provider.tr('Camera Setup'),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.tr(_errorMessage.isNotEmpty ? _errorMessage : 'Camera permission or hardware is unavailable.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _initCamera,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(provider.tr('GRANT PERMISSION & RETRY')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _handleFallbackPicker,
                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                    label: Text(provider.tr('TAKE STATIC PHOTO'), style: const TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else ...[
                  const CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  const SizedBox(height: 20),
                  Text(
                    provider.tr('Initializing Camera...'),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Preview
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // 2. Viewfinder Overlay
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                provider.tr('REAL-TIME SCAN'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                              color: _isTorchOn ? const Color(0xFFFBC02D) : Colors.white,
                            ),
                            onPressed: _toggleTorch,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Scanner Viewfinder Frame
                  SizedBox(
                    width: size.width * 0.78,
                    height: size.width * 0.78,
                    child: Stack(
                      children: [
                        // Border corners
                        _buildCornerFrame(colorScheme.primary),

                        // Animated scanning laser line
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: _scanAnimation.value * (size.width * 0.78 - 4),
                              left: 8,
                              right: 8,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.greenAccent.withValues(alpha: 0.1),
                                      Colors.greenAccent,
                                      Colors.greenAccent.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.greenAccent.withValues(alpha: 0.8),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // 3. Real-Time HUD Output Card
                  _buildRealtimeHUD(provider, colorScheme),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerFrame(Color primaryColor) {
    const double cornerSize = 24.0;
    const double strokeWidth = 4.0;

    return Stack(
      children: [
        // Top-Left
        Positioned(
          top: 0, left: 0,
          child: Container(
            width: cornerSize, height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.greenAccent, width: strokeWidth),
                left: BorderSide(color: Colors.greenAccent, width: strokeWidth),
              ),
            ),
          ),
        ),
        // Top-Right
        Positioned(
          top: 0, right: 0,
          child: Container(
            width: cornerSize, height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.greenAccent, width: strokeWidth),
                right: BorderSide(color: Colors.greenAccent, width: strokeWidth),
              ),
            ),
          ),
        ),
        // Bottom-Left
        Positioned(
          bottom: 0, left: 0,
          child: Container(
            width: cornerSize, height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.greenAccent, width: strokeWidth),
                left: BorderSide(color: Colors.greenAccent, width: strokeWidth),
              ),
            ),
          ),
        ),
        // Bottom-Right
        Positioned(
          bottom: 0, right: 0,
          child: Container(
            width: cornerSize, height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.greenAccent, width: strokeWidth),
                right: BorderSide(color: Colors.greenAccent, width: strokeWidth),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRealtimeHUD(AppProvider provider, ColorScheme colorScheme) {
    final result = _liveResult;
    final String label = result != null ? (result['label'] ?? 'Analyzing...') : 'Scanning...';
    final double confidence = result != null ? ((result['confidence'] ?? 0.0) as double) : 0.0;
    final bool isLeaf = result != null ? (result['isLeaf'] ?? true) : true;
    final bool isHealthy = label.toLowerCase().contains('healthy') || label.toLowerCase().contains('nhyehyɛe');

    Color badgeColor = Colors.orangeAccent;
    IconData badgeIcon = Icons.center_focus_weak_rounded;

    if (result != null) {
      if (!isLeaf) {
        badgeColor = const Color(0xFFFF9800); // Orange
        badgeIcon = Icons.warning_amber_rounded;
      } else if (isHealthy) {
        badgeColor = const Color(0xFF4CAF50); // Green
        badgeIcon = Icons.check_circle_rounded;
      } else {
        badgeColor = const Color(0xFFE53935); // Red
        badgeIcon = Icons.coronavirus_rounded;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live Diagnosis Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(badgeIcon, color: badgeColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.tr('LIVE DIAGNOSIS'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (result != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${(confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Confidence Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: result != null ? confidence : 0.0,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 18),

          // Lock Result & View Details Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: result != null ? _lockAndProcessResult : null,
              icon: const Icon(Icons.analytics_rounded, size: 20),
              label: Text(
                provider.tr('CAPTURE & VIEW REPORT'),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: badgeColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white12,
                disabledForegroundColor: Colors.white30,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
