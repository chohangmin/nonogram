import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LoadImage extends StatelessWidget {
  const LoadImage({super.key});

  @override
  Widget build(BuildContext context) {
    pickImage();
    
    return const Placeholder();
  }

  Future pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  }
}
