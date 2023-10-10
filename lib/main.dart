import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fs1/data.dart';
import 'package:fs1/screens/join_screen.dart';
import 'package:fs1/services/signaling_service.dart';

void main() {
  runApp(VideoCallApp());
}

class VideoCallApp extends StatelessWidget {
  VideoCallApp({super.key});

  final String webSocketUrl = "http://192.168.13.125:5000";
  final String selfCallerId =
      Random().nextInt(999999).toString().padLeft(6, '0');

  @override
  Widget build(BuildContext context) {
    SignalingService.instance
        .init(webSocketUrl: webSocketUrl, selfCallerId: selfCallerId);
    return MaterialApp(
      title: "VideoApp",
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark().copyWith(
          useMaterial3: true,
          colorScheme:
              const ColorScheme.dark().copyWith(brightness: Brightness.dark)),
      home: JoinScreen(selfCalledId: selfCallerId),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Records and patterns",
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark().copyWith(
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent)),
      home: JoinScreen(selfCalledId: "123456"),
    );
  }
}

class MainAppBody extends StatelessWidget {
  const MainAppBody({super.key, required this.dDocument});

  final DDocument dDocument;

  @override
  Widget build(BuildContext context) {
    final metadata = dDocument.metadata;
    final pt = dDocument.p;
    final result = pt.function(pt.x, pt.y);

    return Scaffold(
      appBar: AppBar(
        title: const Text('R&P'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Title : ${metadata.$1}'),
            Text('Last Modified : ${metadata.modified}'),
            Text('Result : ${result}')
          ],
        ),
      ),
    );
  }
}
