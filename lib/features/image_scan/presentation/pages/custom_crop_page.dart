import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CustomCropPage extends StatefulWidget {
  final File imageFile;

  const CustomCropPage({super.key, required this.imageFile});

  @override
  State<CustomCropPage> createState() => _CustomCropPageState();
}

class _CustomCropPageState extends State<CustomCropPage> {
  final _controller = CropController();
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Bölge Seçimi',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_isCropping)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: () {
                setState(() => _isCropping = true);
                _controller.crop();
              },
              child: const Text(
                'ONAYLA',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Text(
                'Beyaz çerçeveyi kenarlarından veya köşelerinden parmağınızla çekerek analiz edilecek alanı belirleyin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            Expanded(
              child: Crop(
                image: _imageBytes!,
                controller: _controller,
                onCropped: (dynamic result) async {
                  Uint8List? imageBytes;
                  if (result is Uint8List) {
                    imageBytes = result;
                  } else {
                    // Handle CropResult (likely CropSuccess or similar)
                    try {
                      imageBytes = (result as dynamic).image as Uint8List?;
                    } catch (_) {
                      try {
                        imageBytes =
                            (result as dynamic).croppedImage as Uint8List?;
                      } catch (__) {}
                    }
                  }

                  if (imageBytes == null) return;

                  final tempDir = await getTemporaryDirectory();
                  final tempFile = File(
                    p.join(
                      tempDir.path,
                      'custom_crop_${DateTime.now().millisecondsSinceEpoch}.jpg',
                    ),
                  );
                  await tempFile.writeAsBytes(imageBytes);

                  if (mounted && context.mounted) {
                    Navigator.of(context).pop(tempFile);
                  }
                },
                baseColor: Colors.black,
                maskColor: Colors.black.withValues(alpha: 0.6),
                cornerDotBuilder: (size, edgeAlignment) =>
                    const DotControl(color: Colors.blue),
                interactive: true,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class DotControl extends StatelessWidget {
  final Color color;
  const DotControl({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
