import 'package:flip_carousel_proto/bottom_bar.dart';
import 'package:flip_carousel_proto/card_data.dart';
import 'package:flip_carousel_proto/cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flip Carousel',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  double percentScroll = 0.0;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.black,
      body: new Column(
        children: [
          // Status bar spacer
          new Container(
            width: double.infinity,
            height: 20.0,
          ),
          new Expanded(
            child: new FlippingCards(
              cards: demoCards,
              onScroll: (double percent) {
                setState(() => percentScroll = percent);
              },
            ),
          ),
          new BottomBar(
            cardCount: demoCards.length,
            percentScroll: percentScroll,
          ),
        ],
      ),
    );
  }
}
