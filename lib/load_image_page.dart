import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LoadImagePage extends StatefulWidget {
  const LoadImagePage({super.key});

  @override
  State<LoadImagePage> createState() => _LoadImagePageState();

  // static Future<Image> pickImage() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  //   return Image.network(image!.path);
  // }
}

class _LoadImagePageState extends State<LoadImagePage> {
  XFile? _loadedImage;

  void _setImageFile(XFile? value) {
    _loadedImage = value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                onPressed: () {},
                child: const Text('Convert Imgae to Pixel'),
              ),
            ],
          ),
          Row(
            children: [
              _loadedImage != null
                  ? Image.network(_loadedImage!.path)
                  : Container(),
              Container(),
            ],
          ),
        ],
      ),
    );
  }
}
