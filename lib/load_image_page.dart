import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LoadImagePage extends StatefulWidget {
  const LoadImagePage({super.key});

  @override
  State<LoadImagePage> createState() => _LoadImagePageState();
}

class _LoadImagePageState extends State<LoadImagePage> {
  XFile? _loadedImage;
  ui.Image? _pixelatedImage;

  void _setImageFile(XFile? value) {
    _loadedImage = value;
  }

  Future<Uint8List?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return image.readAsBytes();
    }
    return null;
  }

  Future<ui.Image> _decodeImage(Uint8List imageData) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(imageData, completer.complete);
    return completer.future;
  }

  Future<ui.Image> _convertToPixelArt(ui.Image image, int pixelSize) async {
    final int width = image.width;
    final int height = image.height;

    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return image;

    final Uint8List pixels = byteData.buffer.asUint8List();
    final Uint8List pixelated = Uint8List(width * height * 4);

    List<List<int>> matrix =
        List.generate(height, (_) => List.filled(width, 0));

    for (int y = 0; y < height; y += pixelSize) {
      for (int x = 0; x < width; x += pixelSize) {
        int sum = 0;
        int count = 0;

        for (int dy = 0; dy < pixelSize && y + dy < height; dy++) {
          for (int dx = 0; dx < pixelSize && x + dx < width; dx++) {
            final int index = ((y + dy) * width + (x + dx)) * 4;
            final int r = pixels[index];
            final int g = pixels[index + 1];
            final int b = pixels[index + 2];
            sum += (r + g + b) ~/ 3;
            count++;
          }
        }

        final int avg = sum ~/ count;
        final int grayscale = avg > 128 ? 255 : 0;

        for (int dy = 0; dy < pixelSize && y + dy < height; dy++) {
          for (int dx = 0; dx < pixelSize && x + dx < width; dx++) {
            final int index = ((y + dy) * width + (x + dx)) * 4;
            pixelated[index] = grayscale;
            pixelated[index + 1] = grayscale;
            pixelated[index + 2] = grayscale;
            pixelated[index + 3] = 255;

            matrix[dy][dx] = grayscale == 255 ? 0 : 1;
          }
        }
      }
    }

    // final matrix = _convertToMatrix(pixelated, width, height);
    print(" Matrix :: \n $matrix");

    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
        pixelated, width, height, ui.PixelFormat.rgba8888, completer.complete);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pixel Art Convert'),
      ),
      body: Column(
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.gallery);
                  setState(() {
                    _setImageFile(image);
                  });
                },
                child: const Text('Load Imgae'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_loadedImage != null) {
                    final Uint8List imageData =
                        await _loadedImage!.readAsBytes();
                    final ui.Image originalImage =
                        await _decodeImage(imageData);
                    final ui.Image pixelArtImage =
                        await _convertToPixelArt(originalImage, 20);
                    setState(() {
                      _pixelatedImage = pixelArtImage;
                    });
                  }
                },
                child: const Text('Convert Imgae to Pixel'),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: [
              _loadedImage != null
                  ? Expanded(
                      child: _pixelatedImage != null
                          ? CustomPaint(
                              painter: PixelArtPainter(_pixelatedImage!),
                              child: Container(),
                            )
                          : Image.network(_loadedImage!.path))
                  : const Text('No image loaded'),
            ],
          ),
        ],
      ),
    );
  }
}

class PixelArtPainter extends CustomPainter {
  final ui.Image image;
  PixelArtPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawImage(image, Offset.zero, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
