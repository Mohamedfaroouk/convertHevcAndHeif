import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool loading = false;
  double progress = 0.0;
  @override
  void initState() {
    VideoCompress.compressProgress$.subscribe((progress) {
      setState(() {
        if (progress > 0.0) {
          loading = true;
        }
        this.progress = progress;
        if (progress == 1.0) {
          loading = false;
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: InkWell(
                      onTap: () {
                        final file = FilePicker.platform.pickFiles(
                          type: FileType.image,
                        );
                        file.then((value) async {
                          final path = value!.files.first.path;
                          final newPath = await convertHEICtoJPG(path!);
                          final file = File(newPath);
                          saveFile(file).then((value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('File Saved Successfully'),
                              ),
                            );
                          });
                        });
                      },
                      child: Column(
                        children: const [
                          Icon(
                            Icons.video_call,
                            size: 40,
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text('Convert Image'),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  child: InkWell(
                    onTap: () {
                      final file = ImagePicker.platform.getVideo(
                        source: ImageSource.gallery,
                      );
                      file.then((value) async {
                        if (value == null) {
                          return;
                        }
                        final path = value.path;
                        final newPath = await convertHEVCToMp4(path);
                        if (newPath == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('File Not Supported'),
                            ),
                          );
                          return;
                        }
                        final file = File(newPath);
                        saveFile(file).then((value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('File Saved Successfully'),
                            ),
                          );
                        });
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.image,
                            size: 40,
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text('Convert Video'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            //loading
            if (loading)
              Column(
                children: [
                  const Text('Converting'),
                  const SizedBox(
                    height: 10,
                  ),
                  CircularProgressIndicator(
                    value: progress,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

Future<String> convertHEICtoJPG(String imagePath) async {
  final result = await FlutterImageCompress.compressAndGetFile(
    imagePath,
    '$imagePath.jpg', // Output path for the converted image
    format: CompressFormat.jpeg,
    quality: 100, // Adjust the quality as needed (0-100)
  );

  // Return the path of the converted image
  return result!.path;
}

Future<String?> convertHEVCToMp4(String videoPath) async {
  final result = await VideoCompress.compressVideo(
    videoPath,
    quality: VideoQuality.DefaultQuality,
    deleteOrigin: false,
    includeAudio: true,
  );

  // Return the path of the converted image
  return result?.path;
}

saveFile(File file) async {
  final pickedDirectory = await FlutterFileDialog.pickDirectory();

  if (pickedDirectory != null) {
    final filePath = await FlutterFileDialog.saveFileToDirectory(
      directory: pickedDirectory,
      data: file.readAsBytesSync(),
      mimeType: "image/jpeg",
      fileName: "fileName.jpeg",
      replace: true,
    );
  }
}
