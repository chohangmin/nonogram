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

  double pixelLength = 40;
  double pixelNumSize = 10;

  double accumulatedDx = 0;
  double accumulatedDy = 0;

  int startDragIndex = 0;
  int currentDragIndex = 0;

  List<List<int>> colCountNums = [];
  List<List<int>> rowCountNums = [];

  List<int> userMatrix1d = [];

  ui.Image? _originalImage;

  bool _checkAllIndex() {
    for (int i = 0; i < matrix1d.length; i++) {
      if (userMatrix1d[i] == matrix1d[i]) {
        continue;
      } else if (userMatrix1d[i] == 2) {
        if (matrix1d[i] == 0) {
          continue;
        }
      } else {
        return false;
      }
    }
    return true;
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
      userMatrix1d = List.filled(resultMatrix1d.length, 0);
    });

    print("1d : $matrix1d");

    print("2d : $matrix2d");

    print("matrix 1d length : ${matrix1d.length}");

    print("matrix 2d length row? : ${matrix2d.length}");

    print("matrix 2d length column? : ${matrix2d[0].length}");

    List<List<int>> rowNums =
        returnMatrixNums(matrix2d, matrix2d.length, matrix2d[0].length, "row")!;

    print("row Nums $rowNums");

    List<List<int>> colNums =
        returnMatrixNums(matrix2d, matrix2d.length, matrix2d[0].length, "col")!;

    print("col Nums $colNums");

    setState(() {
      colCountNums = colNums;
      rowCountNums = rowNums;
    });

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

  List<List<int>>? returnMatrixNums(
      List<List<int>> array2d, int row, int col, String type) {
    int compareNum = 0;
    int count = 0;
    List<List<int>> resultArray = [];

    if (type == "row") {
      for (int i = 0; i < row; i++) {
        List<int> appendList = [];
        for (int j = 0; j < col; j++) {
          // List<int> appendList = [];

          if (array2d[i][j] == 1) {
            // print("check type 1");
            count++;
            compareNum = array2d[i][j];
          } else if (array2d[i][j] == 0 && compareNum == 0) {
            // print("check type 2");
            continue;
          } else if (array2d[i][j] == 0 && compareNum == 1) {
            // print("check type 3");
            appendList.add(count);
            compareNum = 0;
            count = 0;

            continue;
          }
        }
        if (count != 0) {
          appendList.add(count);
          compareNum = 0;
          count = 0;
        }

        // print(appendList);
        resultArray.add(List.from(appendList));

        appendList.clear();
      }

      return resultArray;
    } else if (type == "col") {
      for (int i = 0; i < col; i++) {
        List<int> appendList = [];
        for (int j = 0; j < row; j++) {
          // List<int> appendList = [];

          int tmp = row;

          if (array2d[j][i] == 1) {
            count++;
            compareNum = array2d[j][i];
          } else if (array2d[j][i] == 0 && compareNum == 0) {
            continue;
          } else if (array2d[j][i] == 0 && compareNum == 1) {
            appendList.add(count);
            compareNum = 0;
            count = 0;

            continue;
          }
        }
        if (count != 0) {
          appendList.add(count);
          compareNum = 0;
          count = 0;
        }

        resultArray.add(List.from(appendList));
        appendList.clear();
      }

      return resultArray;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pixel Art Convert'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
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
                  ElevatedButton(
                      onPressed: () {
                        if (_checkAllIndex()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Correct!")));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Wrong!")));
                        }
                      },
                      child: const Text("Check the answer.")),
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
              // const SizedBox(
              //   height: 200,
              // ),
              _loadedImage != null
                  ? Container(
                      child: _pixelatedImage != null
                          ? Center(
                              child: Column(
                                children: [
                                  Text(
                                      "${colCountNums.length} X ${rowCountNums.length}"),
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: pixelLength,
                                        width: pixelLength,
                                      ),
                                      SizedBox(
                                        height: pixelLength,
                                        child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            shrinkWrap: true,
                                            itemCount: colCountNums.length,
                                            itemBuilder: (context, index) {
                                              List<int> temp =
                                                  colCountNums[index];
                                              int tempListLength = temp.length;
                                              String tempString = "";
                                              for (int i = 0;
                                                  i < tempListLength;
                                                  i++) {
                                                tempString +=
                                                    temp[i].toString();
                                                tempString += "\n";
                                              }

                                              print(tempString);

                                              return Container(
                                                alignment: Alignment.center,
                                                height: pixelLength,
                                                width: pixelLength,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  border: Border.all(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                child: Text(
                                                  tempString,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: pixelNumSize,
                                                  ),
                                                ),
                                              );
                                            }),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: pixelLength,
                                        child: ListView.builder(
                                            scrollDirection: Axis.vertical,
                                            shrinkWrap: true,
                                            itemCount: rowCountNums.length,
                                            itemBuilder: (context, index) {
                                              List<int> temp =
                                                  rowCountNums[index];
                                              int tempListLength = temp.length;
                                              String tempString = "";
                                              for (int i = 0;
                                                  i < tempListLength;
                                                  i++) {
                                                tempString +=
                                                    temp[i].toString();
                                                tempString += " ";
                                              }

                                              print(tempString);

                                              return Container(
                                                alignment: Alignment.center,
                                                height: pixelLength,
                                                width: pixelLength,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  border: Border.all(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                child: Text(
                                                  tempString,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: pixelNumSize,
                                                  ),
                                                ),
                                              );
                                            }),
                                      ),
                                      SizedBox(
                                        height:
                                            rowCountNums.length * pixelLength,
                                        width:
                                            colCountNums.length * pixelLength,
                                        child: GridView.builder(
                                          scrollDirection: Axis.vertical,
                                          shrinkWrap: true,
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                                  childAspectRatio: 1,
                                                  crossAxisCount:
                                                      _originalImage!.width ~/
                                                          pixelSize,
                                                  crossAxisSpacing: 1.0,
                                                  mainAxisSpacing: 1.0),
                                          itemBuilder: (context, index) {
                                            return GestureDetector(
                                              onTap: () {
                                                if (userMatrix1d[index] == 0) {
                                                  if (matrix1d[index] == 1) {
                                                    userMatrix1d[index] = 1;
                                                    setState(() {});
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                            const SnackBar(
                                                      content: Text(
                                                        "Click Wrong!!!!",
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                      duration:
                                                          Duration(seconds: 2),
                                                    ));
                                                  }
                                                }

                                                // if (matrix1d[index] == 1) {
                                                //   if (userMatrix1d[index] ==
                                                //       matrix1d[index]) {
                                                //     userMatrix1d[index] == 0
                                                //         ? userMatrix1d[index] =
                                                //             1
                                                //         : userMatrix1d[index] =
                                                //             0;
                                                //     setState(() {});
                                                //   }
                                                // } else if (userMatrix1d[
                                                //         index] ==
                                                //     matrix1d[index]) {
                                                //   ScaffoldMessenger.of(context)
                                                //       .showSnackBar(
                                                //           const SnackBar(
                                                //     content: Text(
                                                //       "Click Wrong!!!!",
                                                //       style: TextStyle(
                                                //         color: Colors.red,
                                                //       ),
                                                //     ),
                                                //     duration:
                                                //         Duration(seconds: 2),
                                                //   ));
                                                // }
                                              },
                                              onDoubleTap: () {
                                                if (userMatrix1d[index] == 0) {
                                                  if (matrix1d[index] == 0) {
                                                    userMatrix1d[index] = 2;
                                                    setState(() {});
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                            const SnackBar(
                                                      content: Text(
                                                        "Grey Wrong!!!!",
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ));
                                                  }
                                                }

                                                // if (matrix1d[index] == 0) {
                                                //   userMatrix1d[index] = 2;
                                                //   setState(() {});
                                                // } else {
                                                //   ScaffoldMessenger.of(context)
                                                //       .showSnackBar(
                                                //           const SnackBar(
                                                //     content: Text(
                                                //       "Grey Wrong!!!!",
                                                //       style: TextStyle(
                                                //         color: Colors.red,
                                                //       ),
                                                //     ),
                                                //     duration:
                                                //         Duration(seconds: 2),
                                                //   ));
                                                // }
                                              },
                                              onHorizontalDragStart:
                                                  (DragStartDetails details) {
                                                int newRow =
                                                    (details.globalPosition.dx /
                                                                pixelLength)
                                                            .floor() -
                                                        1;

                                                int newCol =
                                                    (details.globalPosition.dy /
                                                                pixelLength)
                                                            .floor() -
                                                        4;

                                                startDragIndex = newCol *
                                                        colCountNums.length +
                                                    newRow;

                                                // userMatrix1d[startDragIndex] =
                                                //     1;
                                              },
                                              onHorizontalDragUpdate:
                                                  (DragUpdateDetails details) {
                                                int newRow =
                                                    (details.globalPosition.dx /
                                                                pixelLength)
                                                            .floor() -
                                                        1;

                                                int newCol =
                                                    (details.globalPosition.dy /
                                                                pixelLength)
                                                            .floor() -
                                                        4;

                                                currentDragIndex = newCol *
                                                        colCountNums.length +
                                                    newRow;

                                                print(
                                                    "check location $newRow $newCol");

                                                print(
                                                    "index $startDragIndex $currentDragIndex");

                                                if ((startDragIndex -
                                                            currentDragIndex)
                                                        .abs() >
                                                    0) {
                                                  userMatrix1d[
                                                      currentDragIndex] = 1;
                                                  setState(() {});
                                                }
                                                accumulatedDx +=
                                                    details.delta.dx;

                                                print(
                                                    "accumulatedDx $accumulatedDx ${details.delta.dx}");

                                                userMatrix1d[startDragIndex +
                                                    (accumulatedDx /
                                                            pixelNumSize)
                                                        .floor()] = 1;
                                                accumulatedDx = 0;
                                                setState(() {});
                                              },
                                              // onHorizontalDragEnd:
                                              //     (DragEndDetails details) {
                                              // accumulatedDx = 0;
                                              // int moveIndex =
                                              //     (accumulatedDx / 70)
                                              //         .floor();

                                              // accumulatedDx = 0;

                                              // print(
                                              //     "end $startDragIndex $moveIndex ${startDragIndex + moveIndex}");
                                              // },
                                              onVerticalDragStart:
                                                  (DragStartDetails details) {
                                                int newRow =
                                                    (details.globalPosition.dx /
                                                                pixelLength)
                                                            .floor() -
                                                        1;

                                                int newCol =
                                                    (details.globalPosition.dy /
                                                                pixelLength)
                                                            .floor() -
                                                        4;

                                                startDragIndex = newCol *
                                                        colCountNums.length +
                                                    newRow;
                                              },
                                              onVerticalDragUpdate:
                                                  (DragUpdateDetails details) {
                                                int newRow =
                                                    (details.globalPosition.dx /
                                                                pixelLength)
                                                            .floor() -
                                                        1;

                                                int newCol =
                                                    (details.globalPosition.dy /
                                                                pixelLength)
                                                            .floor() -
                                                        4;

                                                currentDragIndex = newCol *
                                                        colCountNums.length +
                                                    newRow;

                                                print(
                                                    "vertical check location $newRow $newCol");

                                                print(
                                                    "vertical index $startDragIndex $currentDragIndex");

                                                if ((startDragIndex -
                                                            currentDragIndex)
                                                        .abs() >
                                                    0) {
                                                  userMatrix1d[
                                                      currentDragIndex] = 1;
                                                  setState(() {});
                                                  print(
                                                      "accumulatedDx $accumulatedDy ${details.delta.dy}");

                                                  userMatrix1d[startDragIndex +
                                                      (accumulatedDx /
                                                              pixelNumSize)
                                                          .floor()] = 1;
                                                  accumulatedDy = 0;
                                                  setState(() {});
                                                }
                                                accumulatedDy +=
                                                    details.delta.dy;
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: userMatrix1d[index] ==
                                                          0
                                                      ? Colors.white
                                                      : (userMatrix1d[index] ==
                                                              1)
                                                          ? Colors.black
                                                          : Colors.red,
                                                  border: Border.all(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          itemCount: (_originalImage!.width ~/
                                                  pixelSize) *
                                              (_originalImage!.height ~/
                                                  pixelSize),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
                          : Image.network(_loadedImage!.path),
                    )
                  : const Text('No image loaded'),
            ],
          ),
        ),
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
    canvas.drawImage(image, const Offset(250, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
