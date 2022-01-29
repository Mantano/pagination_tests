import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:pagination_tests/src/widgets/paginating_web_view.dart';
import 'package:preload_page_view/preload_page_view.dart' as preload_pageview;
import 'package:preload_page_view/preload_page_view.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'src/widgets/fling_page_scroll_physics.dart';

void main() {
  if (kReleaseMode) {
    Fimber.plantTree(FimberTree());
  } else {
    Fimber.plantTree(DebugBufferTree());
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Pagination tests'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const NB_CHAPTERS = 6;
  final _webviewKeys =
      List<GlobalKey>.generate(NB_CHAPTERS, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    // Enable hybrid composition (not required if webview_flutter >= 3.0.0
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: _chaptersListView(context),
        ),
      ),
    );
  }

  bool flingMode = false;

  Widget _chaptersListView(BuildContext context) {
    final scrollPhysics = flingMode
        ? FlingPageScrollPhysics(PageController())
        : preload_pageview.PageScrollPhysics();
    return createListview(scrollPhysics);
  }

  Widget createListview(ScrollPhysics scrollPhysics) {
    return PreloadPageView(
        preloadPagesCount: 5,
        // controller: PreloadPageController(viewportFraction: 0.9999),
        controller: PreloadPageController(),
        children: new List<Widget>.generate(
            NB_CHAPTERS,
            (i) => PaginatingWebView(
                  i,
                  key: _webviewKeys[i],
                )));
  }
}
