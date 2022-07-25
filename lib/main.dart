import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
                  List<String> imagePaths = [];
                  imagePaths = imageFiles!.map((imageFile) {
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
                  stitch(imagePaths.toString().toNativeUtf8(),
                      dirpath.toNativeUtf8());
                  setState(() {
                    _img = Image.file(File(dirpath));
                  });
                },
                child: Text('Stitch')),
            Center(child: _img),
          ],
        ),
      ),
    );
  }
}
