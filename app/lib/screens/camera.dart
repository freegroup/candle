import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:flutter_vision/flutter_vision.dart';

late List<CameraDescription> cameras;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late FlutterVision vision;
  late CameraController controller;
  late List<Map<String, dynamic>> yoloResults;
  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() async {
    super.dispose();
    _stopDetection();
    await vision.closeTesseractModel();
    await vision.closeYoloModel();
    controller.dispose();
  }

  _init() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((value) {
      _initVision().then((value) {
        _startDetection();
        setState(() {
          isLoaded = true;
          yoloResults = [];
        });
      });
    });
  }

  _initVision() async {
    vision = FlutterVision();
    await vision.loadYoloModel(
        labels: 'assets/labels.txt',
        modelPath: 'assets/yolov8n.tflite',
        modelVersion: "yolov8",
        numThreads: 1,
        useGpu: false);
    setState(() {
      isLoaded = true;
    });
  }

  Future<void> _yoloOnFrame(CameraImage image) async {
    final result = await vision.yoloOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5);
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
      });
    }
  }

  Future<void> _startDetection() async {
    if (controller.value.isStreamingImages) {
      return;
    }
    await controller.startImageStream((image) async {
      if (!isDetecting) {
        isDetecting = true;
        cameraImage = image;
        _yoloOnFrame(image).then((value) => isDetecting = false);
      }
    });
  }

  Future<void> _stopDetection() async {
    if (!controller.value.isStreamingImages) {
      return;
    }
    controller.stopImageStream();
    yoloResults.clear();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: Text("Model not loaded, waiting for it"),
        ),
      );
    }
    var appBar = CandleAppBar(
      title: Text("Camera Preview"), // Replace with your app bar title
      talkback: "Camera Preview", // Replace with your talkback text
    );
    return Scaffold(
      appBar: appBar,
      body: Stack(fit: StackFit.expand, children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(
            controller,
          ),
        ),
        ...displayBoxesAroundRecognizedObjects(size, appBar.height),
      ]),
    );
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen, appBarHeight) {
    if (yoloResults.isEmpty) return [];
    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);

    return yoloResults.map((result) {
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY - appBarHeight,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }
}
