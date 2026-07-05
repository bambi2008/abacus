import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures a RepaintBoundary-wrapped widget (identified by [key]) as a PNG
/// and shares it — shared by every celebration screen's "Share" button
/// (streak milestones, category challenge wins) so the capture logic isn't
/// duplicated per screen.
class ShareCaptureService {
  static Future<void> captureAndShare({
    required GlobalKey key,
    required String filename,
    required String text,
  }) async {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.png');
    await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    await Share.shareXFiles([XFile(file.path)], text: text);
  }
}
