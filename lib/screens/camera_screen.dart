import 'package:camera/camera.dart';
import 'package:chat_bot/screens/crop_image_screen.dart';
import 'package:chat_bot/utils/utils.dart' show Utils;
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    await Utils.requestCameraPermission();
    _cameras = await availableCameras();
    _initializeCamera(_selectedCameraIndex);
  }

  Future<void> _initializeCamera(int cameraIndex) async {
    _controller = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.medium,
    );
    await _controller.initialize();
    setState(() => _isCameraInitialized = true);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    setState(() => _isCameraInitialized = false);
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initializeCamera(_selectedCameraIndex);
  }

  Future<void> _takePicture() async {
    final XFile image = await _controller.takePicture();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CropScreen(imagePath: image.path)),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body:
            _isCameraInitialized
                ? Stack(
                  alignment: Alignment.center,
                  children: [
                    CameraPreview(_controller),
                    Positioned(
                      bottom: 30,
                      left: MediaQuery.of(context).size.width / 2 - 30,
                      child: FloatingActionButton(
                        onPressed: _takePicture,
                        child: const Icon(Icons.camera_alt),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 20,
                      child: IconButton(
                        icon: const Icon(
                          Icons.switch_camera,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: _switchCamera,
                      ),
                    ),
                  ],
                )
                : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
