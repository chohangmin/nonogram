import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LoadImage extends StatelessWidget {
  const LoadImage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }

  static Future<Image> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    return Image.network(image!.path);
  }
}
