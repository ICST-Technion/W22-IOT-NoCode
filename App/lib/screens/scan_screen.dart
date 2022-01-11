import 'package:flutter/material.dart';
import 'package:app/res/custom_colors.dart';
import 'package:app/widgets/app_bar_title.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:camera/camera.dart';


enum DetectionState {empty, invalid, detected}

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ScanScreen createState() => _ScanScreen();
}

class _ScanScreen extends State<ScanScreen> {

  final User _user = FirebaseAuth.instance.currentUser;

  final BarcodeDetector _detector = FirebaseVision.instance.barcodeDetector(
      const BarcodeDetectorOptions(
          barcodeFormats: BarcodeFormat.qrCode
      )
  );

  CameraController _controller;
  DetectionState _currentState = DetectionState.empty;
  bool _scanInProgess = false;
  bool _barcodeDetected = false;

  @override
  void initState() {

    super.initState();

    availableCameras().then((cameras) {
      // Choose the back camera, or first available
      CameraDescription selected = cameras.firstWhere(
              (CameraDescription camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first);

      _controller = CameraController(selected, ResolutionPreset.low);
      _controller.initialize().then((_) {
        if (!mounted) {
          return;
        }

        _controller.startImageStream(_handleCameraImage);
        // Rebuild UI once camera is fully initialized
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller.value.isInitialized) {
      return Container();
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: CustomColors.navy,
        title: AppBarTitle(title: widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Scan device QR code')
              ),
              Expanded(
                child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller)
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _detectionStateWidget(),
              )
            ],
          ),
        ),
      ),
    );
  }
  /// Callback to handle each camera frame
  void _handleCameraImage(CameraImage image) async {
    // Drop the frame if we are still scanning
    if (_scanInProgess || _barcodeDetected) return;

    _scanInProgess = true;

    // Collect all planes into a single buffer
    final WriteBuffer allBytesBuffer = WriteBuffer();
    image.planes.forEach((Plane plane) => allBytesBuffer.putUint8List(plane.bytes));
    final Uint8List allBytes = allBytesBuffer.done().buffer.asUint8List();

    // Convert the image buffer into a Firebase detector frame
    FirebaseVisionImage firebaseImage = FirebaseVisionImage.fromBytes(allBytes,
      FirebaseVisionImageMetadata(
        rawFormat: image.format.raw,
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: ImageRotation.rotation90,
        planeData: image.planes.map((plane) => FirebaseVisionImagePlaneMetadata(
          height: plane.height,
          width: plane.width,
          bytesPerRow: plane.bytesPerRow,
        )).toList(),
      ),
    );

    try {
      // Run detection and check for the proper QR code
      final List<Barcode> barcodes = await _detector.detectInImage(firebaseImage);
      if (barcodes.isEmpty) {
        _reportDetectionState(DetectionState.empty);
      } else {
        final Map<String, dynamic> device = await _handleBarcodeResult(barcodes[0]);
        _barcodeDetected = true;
        _reportDetectionState(DetectionState.detected);

        device['owner'] = _user.uid;
        Navigator.of(context).pop(device);
      }
    } catch (error) {
      print(error);
      _reportDetectionState(DetectionState.invalid);
    } finally {
      _scanInProgess = false;
    }
  }

  /// Utility to update UI with scanner state
  void _reportDetectionState(DetectionState state) {
    if (mounted) {
      setState(() {
        _currentState = state;
      });
    }
  }

  Widget _detectionStateWidget() {
    switch (_currentState) {
      case DetectionState.detected:
        return const Icon(Icons.check_circle,
            color: Colors.green,
            size: 48.0);
      case DetectionState.invalid:
        return const Icon(Icons.cancel,
            color: Colors.red,
            size: 48.0);
      case DetectionState.empty:
      default:
        return Container(height: 48.0);
    }
  }

  /// Validate a QR code as device data
  Future<Map<String, dynamic>> _handleBarcodeResult(Barcode barcode) async {
    // Check for valid QR code data type
    if (barcode.valueType != BarcodeValueType.text) {
      throw("Invalid QR code type");
    }
    // Check for valid JSON payload
    Map<String, dynamic> json = jsonDecode(barcode.rawValue);
    if (json == null || json['serial_number'] == null || json['public_key'] == null) {
      throw("Not a device QR code");
    }

    return json;
  }

}