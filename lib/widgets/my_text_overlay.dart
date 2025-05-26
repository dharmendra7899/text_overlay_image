import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class MyTextOverlay {
  Future<Uint8List> addOverlayToImage({
    required Uint8List imageBytes,
    required String hindiAddress,
    required String fullAddress,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
    required Uint8List mapThumbnailBytes,
    required Uint8List gpsCameraIconBytes,
  }) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final ui.Image baseImage = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();
    canvas.drawImage(baseImage, ui.Offset.zero, paint);

    final width = baseImage.width.toDouble();
    final height = baseImage.height.toDouble();

    final textStyle = ui.TextStyle(color: ui.Color(0xFFFFFFFF), fontSize: 14);
    final paragraphStyle = ui.ParagraphStyle(
      textDirection: ui.TextDirection.ltr,
      fontSize: 14,
      fontWeight: ui.FontWeight.w400,
    );

    final buffer =
        StringBuffer()
          ..writeln(hindiAddress)
          ..writeln(fullAddress)
          ..writeln(
            'Lat ${latitude.toStringAsFixed(6)}° Long ${longitude.toStringAsFixed(6)}°',
          )
          ..write(
            "${DateFormat("dd/MM/yyyy hh:mm a").format(timestamp)} GMT +05:30",
          );

    final paragraphBuilder =
        ui.ParagraphBuilder(paragraphStyle)
          ..pushStyle(textStyle)
          ..addText(buffer.toString());

    final paragraph = paragraphBuilder.build();
    const double textWidthMargin = 50;
    final double textMaxWidth = width - 80 - 25 - textWidthMargin;
    paragraph.layout(ui.ParagraphConstraints(width: textMaxWidth));

    final double textHeight = paragraph.height;
    final double verticalPadding = 20;
    final double overlayHeight = textHeight + verticalPadding;

    final overlayRect = ui.Rect.fromLTWH(
      0,
      height - overlayHeight,
      width,
      overlayHeight,
    );
    canvas.drawRect(overlayRect, paint..color = const ui.Color(0xCC000000));

    final mapCodec = await ui.instantiateImageCodec(mapThumbnailBytes);
    final mapFrame = await mapCodec.getNextFrame();
    final ui.Image mapThumb = mapFrame.image;
    const mapThumbSize = 80.0;
    canvas.drawImageRect(
      mapThumb,
      ui.Rect.fromLTWH(
        0,
        0,
        mapThumb.width.toDouble(),
        mapThumb.height.toDouble(),
      ),
      ui.Rect.fromLTWH(
        10,
        height - mapThumbSize - 10,
        mapThumbSize,
        mapThumbSize,
      ),
      paint,
    );

    final iconCodec = await ui.instantiateImageCodec(gpsCameraIconBytes);
    final iconFrame = await iconCodec.getNextFrame();
    final ui.Image gpsIcon = iconFrame.image;
    const iconSize = 25.0;
    canvas.drawImageRect(
      gpsIcon,
      ui.Rect.fromLTWH(
        0,
        0,
        gpsIcon.width.toDouble(),
        gpsIcon.height.toDouble(),
      ),
      ui.Rect.fromLTWH(
        width - iconSize - 10,
        height - iconSize - 10,
        iconSize,
        iconSize,
      ),
      paint,
    );

    canvas.drawParagraph(
      paragraph,
      ui.Offset(mapThumbSize + 20, height - overlayHeight + 10),
    );

    final finalImage = await recorder.endRecording().toImage(
      baseImage.width,
      baseImage.height,
    );
    final byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData!.buffer.asUint8List();
  }
}
