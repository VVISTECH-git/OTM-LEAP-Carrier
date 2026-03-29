import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:leapcarrier/core/theme/leap_theme.dart';
import 'package:leapcarrier/core/services/otm_service.dart';
import 'package:leapcarrier/core/services/exceptions.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PodUploadScreen — LEAP Carrier
//
// Simple 3-step flow (mirrors the Driver app):
//   1. Camera opens immediately on load
//   2. Driver / carrier previews photo — Retake or Use Photo
//   3. Upload with spinner → success → pop(true)
//
// Caller receives a bool result:
//   true  → upload succeeded  (add docKey to _uploadedDocs)
//   false → cancelled / error (no state change)
// ═══════════════════════════════════════════════════════════════════════════════

// Top-level function required by compute() — runs in a background isolate.
// Reads the file and returns its base64-encoded content.
Future<String> _encodeFileToBase64(String filePath) async {
  final bytes = await File(filePath).readAsBytes();
  return base64Encode(bytes);
}

class PodUploadScreen extends StatefulWidget {
  /// Full shipment GID, e.g. "DEMO.36001"
  final String shipmentGid;

  /// Short key identifying the document type.
  /// • 'pod'           — single-stop Proof of Delivery
  /// • 'pod_stop_2'    — per-stop POD (multi-stop shipments)
  /// • 'eway'          — e-Way Bill
  /// • 'invoice'       — Invoice copy
  /// • 'damage'        — Damage photo
  final String docKey;

  /// Human-readable label shown in the top bar, e.g. "POD (Signed)"
  final String docLabel;

  const PodUploadScreen({
    super.key,
    required this.shipmentGid,
    required this.docKey,
    required this.docLabel,
  });

  @override
  State<PodUploadScreen> createState() => _PodUploadScreenState();
}

class _PodUploadScreenState extends State<PodUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  File?   _photo;
  bool    _uploading = false;
  String? _error;

  AppThemeData get _t => context.read<LeapThemeProvider>().theme;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Open camera immediately — after first frame so the route is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) => _openCamera());
  }

  // ── Step 1: Camera ─────────────────────────────────────────────────────────

  Future<void> _openCamera() async {
    final picked = await _picker.pickImage(
      source:       ImageSource.camera,
      imageQuality: 85,
      maxWidth:     1920,
      maxHeight:    1080,
    );
    if (picked != null) {
      setState(() { _photo = File(picked.path); _error = null; });
    } else {
      // User cancelled — go back
      if (mounted) Navigator.pop(context, false);
    }
  }

  Future<void> _openGallery() async {
    final picked = await _picker.pickImage(
      source:       ImageSource.gallery,
      imageQuality: 85,
      maxWidth:     1920,
      maxHeight:    1080,
    );
    if (picked != null) {
      setState(() { _photo = File(picked.path); _error = null; });
    }
  }

  // ── Step 2: Retake ─────────────────────────────────────────────────────────

  void _retake() {
    setState(() { _photo = null; _error = null; });
    _openCamera();
  }

  // ── Step 3: Upload ─────────────────────────────────────────────────────────

  Future<void> _upload() async {
    if (_photo == null) return;
    setState(() { _uploading = true; _error = null; });

    try {
      final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
      final rawExt    = _photo!.path.split('.').last.toLowerCase();
      final ext       = (rawExt == 'heic' || rawExt == 'heif') ? 'jpeg' : rawExt;
      final fileName  = '${widget.docKey}_$timestamp.$ext';
      final filePath  = _photo!.path;

      // Read + encode on a background isolate — avoids freezing the UI thread
      // on large images (2–5 MB is common for camera captures).
      final b64 = await compute(_encodeFileToBase64, filePath);

      await OtmService.uploadDocument(
        shipmentGid:   widget.shipmentGid,
        docKey:        widget.docKey,
        fileName:      fileName,
        mimeType:      'image/$ext',
        base64Content: b64,
      );

      if (mounted) Navigator.pop(context, true);
    } on SocketException {
      setState(() {
        _uploading = false;
        _error = 'No network connection. Check your connection and try again.';
      });
    } on ApiException catch (e) {
      setState(() {
        _uploading = false;
        _error = e.message;
      });
    } on AuthException catch (e) {
      setState(() {
        _uploading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _uploading = false;
        _error = 'Upload failed. Please try again. ($e)';
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _photo == null ? _buildWaiting() : _buildPreview(),
      ),
    );
  }

  // Waiting for camera to open
  Widget _buildWaiting() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      const SizedBox(height: 20),
      Text('Opening camera…',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14,
              fontFamily: LeapPlatform.fontFamily)),
    ]),
  );

  // Photo preview + action buttons
  Widget _buildPreview() {
    final t = _t;
    return Column(children: [

      // ── Top bar ────────────────────────────────────────────────────────────
      Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, false),
            child: const Icon(Icons.close, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(widget.docLabel,
              style: const TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w700, fontFamily: LeapPlatform.fontFamily))),
          // Gallery option
          GestureDetector(
            onTap: _uploading ? null : _openGallery,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.photo_library_rounded, color: Colors.white, size: 16),
                SizedBox(width: 5),
                Text('Gallery', style: TextStyle(color: Colors.white, fontSize: 12,
                    fontFamily: LeapPlatform.fontFamily)),
              ]),
            ),
          ),
        ]),
      ),

      // ── Photo preview ───────────────────────────────────────────────────────
      Expanded(
        child: InteractiveViewer(
          child: Image.file(_photo!, fit: BoxFit.contain, width: double.infinity),
        ),
      ),

      // ── Error banner ────────────────────────────────────────────────────────
      if (_error != null)
        Container(
          width: double.infinity,
          color: t.danger,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!,
                style: const TextStyle(color: Colors.white, fontSize: 13,
                    fontFamily: LeapPlatform.fontFamily))),
          ]),
        ),

      // ── Action buttons ──────────────────────────────────────────────────────
      Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: _uploading ? _buildUploading(t) : _buildActions(t),
      ),
    ]);
  }

  Widget _buildUploading(AppThemeData t) => Column(mainAxisSize: MainAxisSize.min, children: [
    LinearProgressIndicator(
      backgroundColor: Colors.white24,
      valueColor: AlwaysStoppedAnimation<Color>(t.success),
    ),
    const SizedBox(height: 16),
    Text('Uploading ${widget.docLabel}…',
        style: const TextStyle(color: Colors.white, fontSize: 14,
            fontFamily: LeapPlatform.fontFamily),
        textAlign: TextAlign.center),
  ]);

  Widget _buildActions(AppThemeData t) => Row(children: [
    // Retake
    Expanded(child: OutlinedButton.icon(
      onPressed: _retake,
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: const Text('Retake', overflow: TextOverflow.ellipsis, maxLines: 1),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(fontFamily: LeapPlatform.fontFamily,
            fontWeight: FontWeight.w700),
      ),
    )),
    const SizedBox(width: 12),
    // Use Photo
    Expanded(flex: 2, child: ElevatedButton.icon(
      onPressed: _upload,
      icon: const Icon(Icons.check_rounded, size: 20),
      label: const Text('Use Photo'),
      style: ElevatedButton.styleFrom(
        backgroundColor: t.success,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        minimumSize: const Size(0, 52),
        elevation: 0,
        textStyle: const TextStyle(fontFamily: LeapPlatform.fontFamily,
            fontWeight: FontWeight.w700, fontSize: 15),
      ),
    )),
  ]);
}