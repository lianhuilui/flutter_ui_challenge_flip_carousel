import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class BottomBar extends StatelessWidget {
  final int cardCount;
  final double percentScroll;

  BottomBar({
    this.cardCount,
    this.percentScroll,
  });

  @override
  Widget build(BuildContext context) {
    return new Container(
      width: double.infinity,
      child: new Padding(
        padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
        child: new Row(
          children: <Widget>[
            new Expanded(
              child: new Center(
                child: new Icon(
                  Icons.settings,
                  color: Colors.white,
                ),
              ),
            ),
            new Expanded(
              child: new Center(
                child: new Container(
                  width: double.infinity,
                  height: 5.0,
                  child: new PhotoIndicator(
                    photoCount: cardCount,
                    percentScroll: percentScroll,
                  ),
                ),
              ),
            ),
            new Expanded(
              child: new Center(
                child: new Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoIndicator extends StatelessWidget {
  final int photoCount;
  final double percentScroll;

  PhotoIndicator({
    this.photoCount,
    this.percentScroll,
  });

  @override
  Widget build(BuildContext context) {
    return new CustomPaint(
      painter: new PhotoIndicatorPainter(
        photoCount: photoCount,
        percentScroll: percentScroll,
      ),
      child: new Container(),
    );
  }
}

class PhotoIndicatorPainter extends CustomPainter {
  final int photoCount;
  final double percentScroll;
  final Paint trackPaint;
  final Paint thumbPaint;

  PhotoIndicatorPainter({
    this.photoCount,
    this.percentScroll,
  })  : trackPaint = new Paint()
          ..color = const Color(0xFF444444)
          ..style = PaintingStyle.fill,
        thumbPaint = new Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw track
    canvas.drawRRect(
      new RRect.fromRectAndCorners(
        new Rect.fromLTWH(
          0.0,
          0.0,
          size.width,
          size.height,
        ),
        topLeft: new Radius.circular(3.0),
        topRight: new Radius.circular(3.0),
        bottomLeft: new Radius.circular(3.0),
        bottomRight: new Radius.circular(3.0),
      ),
      trackPaint,
    );

    // Draw thumb
    final thumbWidth = size.width / photoCount;
    final thumbLeft = percentScroll * size.width;

    Path thumbPath = new Path();
    thumbPath.addRRect(
      new RRect.fromRectAndCorners(
        new Rect.fromLTWH(
          thumbLeft,
          0.0,
          thumbWidth,
          size.height,
        ),
        topLeft: new Radius.circular(3.0),
        topRight: new Radius.circular(3.0),
        bottomLeft: new Radius.circular(3.0),
        bottomRight: new Radius.circular(3.0),
      ),
    );

    // Thumb shape
    canvas.drawPath(
      thumbPath,
      thumbPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
