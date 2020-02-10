import "package:flutter/widgets.dart";
import "dart:math";

import 'package:pagination_tests/src/widgets/fling_page_scroll_physics.dart';

// Inspired by: https://gist.githubusercontent.com/yunyu/ac6812d6c550da1f31ae464bef8b37ea/raw/566b7dad1ce63b07007746a0fe66ee6630d4a873/snapping_list_view.dart
// which is part of: https://github.com/iebrosalin/mobile/tree/flutter/social_network
class SnappingListView extends StatefulWidget {
  final Axis scrollDirection;
  final ScrollController controller;

  final IndexedWidgetBuilder itemBuilder;
  final List<Widget> children;
  final int itemCount;

  final double itemExtent;
  // final List<int> itemExtents;
  final ValueChanged<int> onItemChanged;

  final EdgeInsets padding;

  SnappingListView(
      {this.scrollDirection,
        this.controller,
        @required this.children,
        @required this.itemExtent,
        this.onItemChanged,
        this.padding = const EdgeInsets.all(0.0)})
      : assert(itemExtent > 0),
        itemCount = null,
        itemBuilder = null;

  SnappingListView.builder(
      {this.scrollDirection,
        this.controller,
        @required this.itemBuilder,
        this.itemCount,
        @required this.itemExtent,
        this.onItemChanged,
        this.padding = const EdgeInsets.all(0.0)})
      : assert(itemExtent > 0),
        children = null;

  @override
  createState() => _SnappingListViewState();
}

class _SnappingListViewState extends State<SnappingListView> {
  int _lastItem = 0;

  @override
  Widget build(BuildContext context) {
    final startPadding = widget.scrollDirection == Axis.horizontal
        ? widget.padding.left
        : widget.padding.top;
//    final scrollPhysics = SnappingListScrollPhysics(
//        mainAxisStartPadding: startPadding, itemExtent: widget.itemExtent);
    // Nous pourrions utiliser soit la PageScroll en mode lecture, soit la FlingPageScroll dans un mode "overview" comme Google Play
    final scrollPhysics = PageScrollPhysics();
    // final scrollPhysics = FlingPageScrollPhysics(PageController());
    final listView = widget.children != null
        ? ListView(
        scrollDirection: widget.scrollDirection,
        controller: widget.controller,
        children: widget.children,
        itemExtent: widget.itemExtent,
        physics: scrollPhysics,
        padding: widget.padding)
        : ListView.builder(
        scrollDirection: widget.scrollDirection,
        controller: widget.controller,
        itemBuilder: widget.itemBuilder,
        itemCount: widget.itemCount,
        itemExtent: widget.itemExtent,
        physics: scrollPhysics,
        padding: widget.padding);
    return NotificationListener<ScrollNotification>(
        child: listView,
        onNotification: (notif) {
          if (notif.depth == 0 &&
              widget.onItemChanged != null &&
              notif is ScrollUpdateNotification) {
            final currItem =
                (notif.metrics.pixels - startPadding) ~/ widget.itemExtent;
            if (currItem != _lastItem) {
              _lastItem = currItem;
              widget.onItemChanged(currItem);
            }
          }
          return false;
        });
  }
}

class SnappingListScrollPhysics extends ScrollPhysics {
  final double mainAxisStartPadding;
  /// The width in pixels of items (= pages)
  final double itemExtent;
  /// The number of pages in each chapter. First chapter at position 0
  final List<int> _chapterLengths = const<int>[];
  /// The number of the chapter containing each page
  final List<int> _pageToChapterNum = const<int>[];

  SnappingListScrollPhysics(
      {ScrollPhysics parent,
        this.mainAxisStartPadding = 0.0,
        @required this.itemExtent})
      : super(parent: parent) {
      chapterLengths = const<int>[];
  }

  void _initializePageToChapter() {
    _pageToChapterNum.clear();
    for (var chapterNum = 0; chapterNum < _chapterLengths.length; ++chapterNum) {
      var l = _chapterLengths[chapterNum];
      for (int p = 0; p < l; p++)
        _pageToChapterNum.add(chapterNum);
    }
  }

  set chapterLengths(List<int> chapLengths) {
    _chapterLengths.clear();
    _chapterLengths.addAll(chapLengths);
    _initializePageToChapter();
  }

  @override
  SnappingListScrollPhysics applyTo(ScrollPhysics ancestor) {
    return SnappingListScrollPhysics(
        parent: buildParent(ancestor),
        mainAxisStartPadding: mainAxisStartPadding,
        itemExtent: itemExtent);
  }

  // Modifier pour rechercher la page par parcours d'un tableau / hashmap
  double _getPage(ScrollPosition position) {
    var pageNum = (position.pixels - mainAxisStartPadding) / itemExtent;
    return pageNum;
  }

  // Modifier pour rechercher la largeur de la page dans une hashmap
  double _getPixels(ScrollPosition position, double item) {
    return min(item * itemExtent, position.maxScrollExtent);
  }

  // Modifier...
  double _getTargetPixels(
      ScrollPosition position, Tolerance tolerance, double velocity) {
    // Là il faut recupérer en plus de l'item l'offset (numéro de page dans cet item,
    // compté à partir de 0
    double item = _getPage(position);
    if (velocity < -tolerance.velocity)
      item -= 0.5;
    else if (velocity > tolerance.velocity) item += 0.5;
    return _getPixels(position, item.roundToDouble());
  }

  @override
  Simulation createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at a page boundary.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent))
      return super.createBallisticSimulation(position, velocity);
    final Tolerance tolerance = this.tolerance;
    final double target = _getTargetPixels(position, tolerance, velocity);
    if (target != position.pixels)
      return ScrollSpringSimulation(spring, position.pixels, target, velocity,
          tolerance: tolerance);
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}