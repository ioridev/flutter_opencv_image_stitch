import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

import 'livecamera.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenCV on Flutter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(title: 'OpenCV C++ on dart:ffi'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();
  // For Android, you call DynamicLibrary to find and open the shared library
  // You don’t need to do this in iOS since all linked symbols map when an app runs.
  final dylib = Platform.isAndroid
      ? DynamicLibrary.open("libOpenCV_ffi.so")
      : DynamicLibrary.process();
  Image _img = Image.asset('assets/img/default.jpg');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () async {
                  final imageFiles = await _picker.pickMultiImage();
                  debugPrint(
                      '${imageFiles!.length} images selected from gallery');
                  List<String> imagePaths = [];
                  imagePaths = imageFiles.map((imageFile) {
                    return imageFile.path;
                  }).toList();
                  imagePaths.toString().toNativeUtf8();
                  debugPrint(imagePaths.toString());
                  final stitch = dylib.lookupFunction<
                      Void Function(Pointer<Utf8>, Pointer<Utf8>),
                      void Function(Pointer<Utf8>, Pointer<Utf8>)>('stitch');
                  String dirpath =
                      (await getApplicationDocumentsDirectory()).path +
                          "/" +
                          DateTime.now().toString() +
                          "_.jpg";

                  print(dirpath);
                  stitch(imagePaths.toString().toNativeUtf8(),
                      dirpath.toNativeUtf8());
                  //遅延
                  Future.delayed(Duration(seconds: 1), () {}).then((_) {
                    setState(() {
                      print("stitch: ${DateTime.now().toString()}");

                      _img = Image.file(File(dirpath));
                    });
                  });
                },
                child: Text('Stitch')),
            _cameraButton(context),
            _imageGalleryButton(),
            Center(child: _img),
          ],
        ),
      ),
    );
  }

  ElevatedButton _imageGalleryButton() {
    return ElevatedButton(
      onPressed: () async {
        final imageFile = await _picker.pickImage(source: ImageSource.gallery);
        final imagePath =
            imageFile?.path.toNativeUtf8() ?? "none".toNativeUtf8();
        final gaussian = dylib.lookupFunction<Void Function(Pointer<Utf8>),
            void Function(Pointer<Utf8>)>('Gaussian');
        gaussian(imagePath);
        setState(() {
          _img = Image.file(File(imagePath.toDartString()));
        });
      },
      child: Text("Pick Image from Gallery"),
    );
  }
}

ElevatedButton _cameraButton(BuildContext context) {
  return ElevatedButton(
      onPressed: () async {
        WidgetsFlutterBinding.ensureInitialized();
        // Obtain a list of the available cameras on the device.
        final cameras = await availableCameras();
        // Get a specific camera from the list of available cameras.
        final firstCamera = cameras.first;
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TakePictureScreen(camera: firstCamera)));
      },
      child: Text('Camera'));
}
