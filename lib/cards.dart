import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flip_carousel_proto/card_data.dart';
import 'package:flutter/material.dart';

class FlippingCards extends StatefulWidget {
  final List<CardViewModel> cards;
  final Function(double percent) onScroll;

  FlippingCards({
    this.cards,
    this.onScroll,
  });

  @override
  FlippingCardsState createState() {
    return new FlippingCardsState();
  }
}

class FlippingCardsState extends State<FlippingCards> with TickerProviderStateMixin {
  double percentScroll = 0.0;
  Offset startDrag;
  double startDragPercentScroll;
  double finishScrollStart;
  double finishScrollEnd;
  AnimationController finishScrollController;

  @override
  void initState() {
    super.initState();

    finishScrollController = new AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    )
      ..addListener(() {
        setState(() {
          percentScroll =
              lerpDouble(finishScrollStart, finishScrollEnd, finishScrollController.value);

          if (null != widget.onScroll) {
            widget.onScroll(percentScroll);
          }
        });
      })
      ..addStatusListener((AnimationStatus status) {});
  }

  void _onPanStart(DragStartDetails details) {
    startDrag = details.globalPosition;
    startDragPercentScroll = percentScroll;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final currDrag = details.globalPosition;
    final dragDistance = currDrag.dx - startDrag.dx;
    final singleCardDragPercent = dragDistance / context.size.width;

    setState(() {
      percentScroll = (startDragPercentScroll + (-singleCardDragPercent / widget.cards.length))
          .clamp(0.0, 1.0 - (1 / widget.cards.length));
      print('percentScroll: $percentScroll');

      if (null != widget.onScroll) {
        widget.onScroll(percentScroll);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    finishScrollStart = percentScroll;
    finishScrollEnd = (percentScroll * widget.cards.length).round() / widget.cards.length;
    finishScrollController.forward(from: 0.0);

    setState(() {
      startDrag = null;
      startDragPercentScroll = null;
    });
  }

  Matrix4 _buildCardProjection(double percentScroll) {
    final fov = pi / 2;
    final near = 10.0;
    final far = 700.0;

    final cardZ = 300.0;
    Matrix4 cardTransform = new Matrix4.identity()
//      ..rotateY(pi / 8)
      ..translate(0.0, 0.0, cardZ);

    Matrix4 camera = new Matrix4.identity();
    camera = new Matrix4(
      //x
      1.0 / (tan(fov / 2)),
      0.0,
      0.0,
      0.0,
      //y
      0.0,
      1.0 / (tan(fov / 2)),
      0.0,
      0.0,
      //z
      0.0,
      0.0,
      (-near - far) / (near - far),
      1.0,
      //w
      0.0,
      0.0,
      (2 * far * near) / (near - far),
      0.0,
    )..translate(0.0, 0.0, 1.0);

//    camera.multiply(new Matrix4(
//      //x
//      1 / cardZ,
//      0.0,
//      0.0,
//      0.0,
//      //y
//      1 / cardZ,
//      0.0,
//      0.0,
//      0.0,
//      //z
//      0.0,
//      0.0,
//      1.0,
//      0.0,
//      //w
//      0.0,
//      0.0,
//      0.0,
//      1.0,
//    ));

//    Matrix4 projection = cardTransform.multiplied(camera);
//    projection.multiply(new Matrix4(
//      //x
//      1 / cardZ,
//      0.0,
//      0.0,
//      0.0,
//      //y
//      1 / cardZ,
//      0.0,
//      0.0,
//      0.0,
//      //z
//      0.0,
//      0.0,
//      1.0,
//      0.0,
//      //w
//      0.0,
//      0.0,
//      0.0,
//      1.0,
//    ));

    // Pre-multiplied matrix of a projection matrix and a view matrix.
    //
    // Projection matrix is a simplified perspective matrix
    // http://web.iitd.ac.in/~hegde/cad/lecture/L9_persproj.pdf
    // in the form of
    // [[1.0, 0.0, 0.0, 0.0],
    //  [0.0, 1.0, 0.0, 0.0],
    //  [0.0, 0.0, 1.0, 0.0],
    //  [0.0, 0.0, -perspective, 1.0]]
    //
    // View matrix is a simplified camera view matrix.
    // Basically re-scales to keep object at original size at angle = 0 at
    // any radius in the form of
    // [[1.0, 0.0, 0.0, 0.0],
    //  [0.0, 1.0, 0.0, 0.0],
    //  [0.0, 0.0, 1.0, -radius],
    //  [0.0, 0.0, 0.0, 1.0]]
    final perspective = 0.002;
    final radius = 1.0;
    final angle = percentScroll * pi / 8;
    final horizontalTranslation = 0.0;
    Matrix4 projection = new Matrix4.identity()
      ..setEntry(0, 0, 1 / radius)
      ..setEntry(1, 1, 1 / radius)
      ..setEntry(3, 2, -perspective)
      ..setEntry(2, 3, -radius)
      ..setEntry(3, 3, perspective * radius + 1.0);

    // Model matrix by first translating the object from the origin of the world
    // by radius in the z axis and then rotating against the world.
    final rotationPointMultiplier = angle > 0.0 ? angle / angle.abs() : 1.0;
    print('Angle: $angle');
    projection *= new Matrix4.translationValues(
            horizontalTranslation + (rotationPointMultiplier * 300.0), 0.0, 0.0) *
        new Matrix4.rotationY(angle) *
        new Matrix4.translationValues(0.0, 0.0, radius) *
        new Matrix4.translationValues(-rotationPointMultiplier * 300.0, 0.0, 0.0);

    return projection;
  }

  List<Widget> _buildCards() {
    int index = 0;

    return widget.cards.map((CardViewModel card) {
      final cardScrollOffset = index;
      final cardPercentScroll = percentScroll / (1 / widget.cards.length);
      final parallax = percentScroll - (index / widget.cards.length);
//      print('Card $index parallax: $parallax');
      ++index;

      return FractionalTranslation(
        translation: new Offset(cardScrollOffset - cardPercentScroll, 0.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: new Transform(
            transform: _buildCardProjection(cardPercentScroll - cardScrollOffset),
            child: new Card(
              viewModel: card,
              parallaxPercent: parallax,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onPanStart,
      onHorizontalDragUpdate: _onPanUpdate,
      onHorizontalDragEnd: _onPanEnd,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: _buildCards(),
      ),
    );
  }
}

class Card extends StatelessWidget {
  final CardViewModel viewModel;
  final double parallaxPercent;

  Card({
    this.viewModel,
    this.parallaxPercent = 0.0,
  });

  Widget _buildBackground() {
    return new ClipRRect(
      borderRadius: new BorderRadius.circular(10.0),
      child: new Container(
        child: FractionalTranslation(
          translation: new Offset(parallaxPercent / 0.5, 0.0),
          child: new OverflowBox(
            maxWidth: double.infinity,
            child: new Image.asset(
              viewModel.backdropAssetPath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        new Padding(
          padding: const EdgeInsets.only(top: 30.0, left: 20.0, right: 20.0),
          child: new Text(
            viewModel.address.toUpperCase(),
            style: new TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontFamily: 'petita',
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
        new Expanded(child: new Container()),
        new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            new Text(
              '${viewModel.minHeightInFeet} - ${viewModel.maxHeightInFeet}',
              style: new TextStyle(
                color: Colors.white,
                fontSize: 140.0,
                fontFamily: 'petita',
                letterSpacing: -5.0,
              ),
            ),
            new Padding(
              padding: const EdgeInsets.only(left: 10.0, top: 30.0),
              child: new Text(
                'FT',
                style: new TextStyle(
                  color: Colors.white,
                  fontSize: 22.0,
                  fontFamily: 'petita',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            new Icon(
              Icons.wb_sunny,
              color: Colors.white,
            ),
            new Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: new Text(
                '${viewModel.tempInDegrees.toStringAsFixed(1)}º',
                style: new TextStyle(
                  color: Colors.white,
                  fontFamily: 'petita',
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
            )
          ],
        ),
        new Expanded(child: new Container()),
        new Padding(
          padding: const EdgeInsets.only(top: 50.0, bottom: 50.0),
          child: new Container(
            decoration: new BoxDecoration(
              borderRadius: new BorderRadius.circular(30.0),
              border: new Border.all(
                color: Colors.white,
                width: 1.5,
              ),
              color: Colors.black.withOpacity(0.3),
            ),
            child: new Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 10.0,
                bottom: 10.0,
              ),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  new Text(
                    viewModel.weatherType,
                    style: new TextStyle(
                      color: Colors.white,
                      fontFamily: 'petita',
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  new Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                    child: new Icon(
                      Icons.wb_cloudy,
                      color: Colors.white,
                    ),
                  ),
                  new Text(
                    '${viewModel.windSpeedInMph.toStringAsFixed(1)}mph ${viewModel.cardinalDirection}',
                    style: new TextStyle(
                      color: Colors.white,
                      fontFamily: 'petita',
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          _buildContent(),
        ],
      ),
    );
  }
}
