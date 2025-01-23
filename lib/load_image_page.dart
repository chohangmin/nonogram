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
  List<int> matrix1d = [];
  List<List<int>> matrix2d = [];
  int pixelSize = 10;

  ui.Image? _originalImage;

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

    final int boundedWidth = width ~/ pixelSize;
    final int boundedHeight = height ~/ pixelSize;

    final floorWidth = (width ~/ 10) * 10;
    final floorHeight = (height ~/ 10) * 10;

    final Uint8List resultMatrix1d = Uint8List(boundedWidth * boundedHeight);

    for (int y = 0; y < floorHeight; y += pixelSize) {
      for (int x = 0; x < floorWidth; x += pixelSize) {
        int sum = 0;
        int count = 0;

        for (int dy = 0; dy < pixelSize && y + dy < floorHeight; dy++) {
          for (int dx = 0; dx < pixelSize && x + dx < floorWidth; dx++) {
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

        for (int dy = 0; dy < pixelSize && y + dy < floorHeight; dy++) {
          for (int dx = 0; dx < pixelSize && x + dx < floorWidth; dx++) {
            final int index = ((y + dy) * width + (x + dx)) * 4;
            pixelated[index] = grayscale;
            pixelated[index + 1] = grayscale;
            pixelated[index + 2] = grayscale;
            pixelated[index + 3] = 255;
          }
        }

        // print("x $x");
        // print("y $y");
        // print("real x ${x ~/ pixelSize}");
        // print("real y ${y ~/ pixelSize}");

        // print(
        //     "index : ${(x ~/ pixelSize) + (y ~/ pixelSize) * (width ~/ pixelSize)}");

        resultMatrix1d[(x ~/ pixelSize) +
            (y ~/ pixelSize) * (width ~/ pixelSize)] = grayscale == 255 ? 0 : 1;
      }
    }

    print("boundedwidth : width / pixelSize : $boundedWidth");
    print("boundedheight : height / pixelSize : $boundedHeight");

    print("floor width : $floorWidth");
    print("floor height : $floorHeight");
    // print("width $width");
    // print("height $height");

    // print("matrix 1d length : ${divHeight * divWidth}");

    List<List<int>> resultMatrix2d =
        convertTo2dArray(resultMatrix1d, boundedWidth, boundedHeight);

    setState(() {
      matrix2d = resultMatrix2d;
    });

    setState(() {
      matrix1d = resultMatrix1d;
    });

    print("1d : $matrix1d");

    print("2d : $matrix2d");

    print("matrix 1d length : ${matrix1d.length}");

    print("matrix 2d length row? : ${matrix2d.length}");

    print("matrix 2d length column? : ${matrix2d[0].length}");

    print(
        "crossAxisCount (_originalImage!.width ~/ pixelSize): ${_originalImage!.width ~/ pixelSize}");

    print(
        "_originalImage!.height ~/ pixelSize: ${_originalImage!.height ~/ pixelSize}");

    print(
        "grid builder item count : ${(_originalImage!.width ~/ pixelSize) * (_originalImage!.height ~/ pixelSize)}");

    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
        pixelated, width, height, ui.PixelFormat.rgba8888, completer.complete);
    return completer.future;
  }

  List<List<int>> convertTo2dArray(Uint8List data, int width, int height) {
    List<List<int>> result = [];

    for (int i = 0; i < height; i++) {
      result.add(data.sublist(i * width, (i + 1) * width));
    }
    return result;
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
                    _loadedImage = image;
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

                    setState(() {
                      _originalImage = originalImage;
                    });

                    final ui.Image pixelArtImage =
                        await _convertToPixelArt(originalImage, pixelSize);
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
          (_loadedImage != null && _pixelatedImage != null)
              ? CustomPaint(
                  painter: PixelArtPainter(_pixelatedImage!),
                )
              : Container(),
          const SizedBox(
            height: 200,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: _loadedImage != null
                  ? Container(
                      child: _pixelatedImage != null
                          ? GridView.builder(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          _originalImage!.width ~/ pixelSize,
                                      crossAxisSpacing: 16.0,
                                      mainAxisSpacing: 16.0),
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    color: matrix1d[index] == 0
                                        ? Colors.blue
                                        : Colors.red,
                                  ),
                                );
                              },
                              itemCount: (_originalImage!.width ~/ pixelSize) *
                                  (_originalImage!.height ~/ pixelSize),
                            )
                          : Image.network(_loadedImage!.path))
                  : const Text('No image loaded'),
            ),
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
