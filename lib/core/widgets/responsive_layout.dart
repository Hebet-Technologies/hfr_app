import 'package:flutter/material.dart';

class AppBreakpoints {
  const AppBreakpoints._();

  static const double tablet = 700;
  static const double desktop = 1100;
  static const double maxContentWidth = 980;
  static const double maxFormWidth = 620;

  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= tablet;
  }

  static EdgeInsets pagePadding(BuildContext context, {double bottom = 24}) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) {
      return EdgeInsets.fromLTRB(32, 18, 32, bottom);
    }
    if (isTablet(context)) {
      return EdgeInsets.fromLTRB(24, 16, 24, bottom);
    }
    return EdgeInsets.fromLTRB(16, 12, 16, bottom);
  }
}

class ResponsiveWidth extends StatelessWidget {
  const ResponsiveWidth({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class ResponsiveListView extends StatelessWidget {
  const ResponsiveListView({
    super.key,
    required this.children,
    this.padding,
    this.physics,
    this.maxWidth = AppBreakpoints.maxContentWidth,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minHeight: constraints.maxHeight,
            ),
            child: ListView(
              physics: physics,
              padding: padding,
              children: children,
            ),
          ),
        );
      },
    );
  }
}
