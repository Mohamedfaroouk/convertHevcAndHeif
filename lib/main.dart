import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

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
    // VideoCompress.compressProgress$.subscribe((progress) {
    //   log(progress.toString());
    //   setState(() {
    //     if (progress > 0.0) {
    //       loading = true;
    //     }
    //     this.progress = progress;
    //     if (progress == 100.0) {
    //       loading = false;
    //     }
    //   });
    // });
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
                          saveFile(context, file);
                        });
                      },
                      child: Column(
                        children: const [
                          Icon(
                            Icons.image,
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
                    onTap: () async {
                      final file = FilePicker.platform.pickFiles(
                        type: FileType.video,
                      );
                      file.then((value) async {
                        if (value == null) {
                          return;
                        }
                        final path = value.files.first.path!;

                        final inputFilePath = path;
                        final outputFilePath =
                            '${path.replaceAll(RegExp(r'\.[^.]*$'), '')}${DateTime.now().microsecondsSinceEpoch}.mp4';
                        log(outputFilePath);
                        loading = true;
                        setState(() {});
                        FFmpegKit.execute(
                                "-i $inputFilePath -y  -vcodec mpeg4 -acodec aac -qscale 0 $outputFilePath")
                            .then((value) async {
                          log(((await value.getAllLogsAsString()).toString()));
                          try {
                            saveVideo(context, File(outputFilePath));
                          } on Exception {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error in Procceing File'),
                              ),
                            );

                            return;
                          }
                          loading = false;
                          setState(() {});
                        });

                        // if (newPath == null) {
                        //   ScaffoldMessenger.of(context).showSnackBar(
                        //     const SnackBar(
                        //       content: Text('File Not Supported'),
                        //     ),
                        //   );
                        //   return;
                        // }
                        // final file = File(newPath);
                        // saveFile(file).then((value) {
                        //   ScaffoldMessenger.of(context).showSnackBar(
                        //     const SnackBar(
                        //       content: Text('File Saved Successfully'),
                        //     ),
                        //   );
                        // });
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.video_call,
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
                children: const [
                  Text('Converting'),
                  SizedBox(
                    height: 10,
                  ),
                  CircularProgressIndicator(),
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
  return null;

  // log(videoPath);
  // final result = await VideoCompress.compressVideo(
  //   videoPath,
  //   quality: VideoQuality.DefaultQuality,
  //   deleteOrigin: false,
  //   includeAudio: true,
  // );

  // // Return the path of the converted image
  // return result?.path;
}

saveFile(context, File file) async {
  final check = await showDialog(
    context: context,
    builder: (context) => AlertDialogToSaveFile(
      onYes: () {
        Navigator.of(context).pop(true);
      },
    ),
  );
  if (check == null) {
    return;
  }
  final pickedDirectory = await FlutterFileDialog.pickDirectory();

  if (pickedDirectory != null) {
    final filePath = await FlutterFileDialog.saveFileToDirectory(
      directory: pickedDirectory,
      data: file.readAsBytesSync(),
      mimeType: "image/jpeg",
      fileName: "fileName.jpeg",
      replace: true,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File Saved Successfully'),
      ),
    );
  }
}

saveVideo(context, File file) async {
  final check = await showDialog(
    context: context,
    builder: (context) => AlertDialogToSaveFile(
      onYes: () {
        Navigator.of(context).pop(true);
      },
    ),
  );
  if (check == null) {
    return;
  }
  final pickedDirectory = await FlutterFileDialog.pickDirectory();

  if (pickedDirectory != null) {
    final filePath = await FlutterFileDialog.saveFileToDirectory(
      directory: pickedDirectory,
      data: file.readAsBytesSync(),
      mimeType: "video/mp4",
      fileName: "fileName.mp4",
      replace: true,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File Saved Successfully'),
      ),
    );
  }
}

class AlertDialogToSaveFile extends StatelessWidget {
  const AlertDialogToSaveFile({super.key, required this.onYes});
  final VoidCallback onYes;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save File'),
      content: const Text('Do you want to save the file?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () {
            onYes();
          },
          child: const Text('Yes'),
        ),
      ],
    );
  }
}
