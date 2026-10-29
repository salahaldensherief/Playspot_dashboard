import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Equal-height rows with natural content sizing, including large text.
/// Rows measure real layouts because card controls contain LayoutBuilders.
class RoomCardsLayout extends StatelessWidget {
  final int count;
  final Widget Function(int index, double width) itemBuilder;
  const RoomCardsLayout({
    super.key,
    required this.count,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = (c.maxWidth / 300).floor().clamp(1, 6);
      final width = (c.maxWidth - (columns - 1) * 12) / columns;
      return Column(
        children: [
          for (var row = 0; row < count; row += columns) ...[
            if (row > 0) const SizedBox(height: 12),
            _EqualRoomRow(
              direction: Directionality.of(context),
              children: [
                for (var col = 0; col < columns; col++) ...[
                  if (col > 0) const SizedBox(width: 12),
                  SizedBox(
                    width: width,
                    child: row + col < count
                        ? itemBuilder(row + col, width)
                        : null,
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    },
  );
}

class _EqualRoomRow extends MultiChildRenderObjectWidget {
  final TextDirection direction;
  const _EqualRoomRow({required this.direction, required super.children});
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderEqualRoomRow(direction);
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderEqualRoomRow renderObject,
  ) {
    renderObject.direction = direction;
  }
}

class _RoomParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderEqualRoomRow extends RenderBox
    with
        ContainerRenderObjectMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        >,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        > {
  _RenderEqualRoomRow(this._direction);
  TextDirection _direction;
  set direction(TextDirection value) {
    if (_direction == value) return;
    _direction = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ContainerBoxParentData<RenderBox>) {
      child.parentData = _RoomParentData();
    }
  }

  @override
  void performLayout() {
    var height = 0.0;
    var child = firstChild;
    while (child != null) {
      child.layout(
        BoxConstraints(maxWidth: constraints.maxWidth),
        parentUsesSize: true,
      );
      if (child.size.height > height) height = child.size.height;
      child = childAfter(child);
    }
    var x = _direction == TextDirection.rtl ? constraints.maxWidth : 0.0;
    child = firstChild;
    while (child != null) {
      // SizedBoxes retain their measured width, including explicit gaps.
      final width = child.size.width;
      child.layout(
        BoxConstraints(minWidth: width, maxWidth: width, minHeight: height),
        parentUsesSize: true,
      );
      if (_direction == TextDirection.rtl) x -= width;
      (child.parentData! as ContainerBoxParentData<RenderBox>).offset = Offset(
        x,
        0,
      );
      if (_direction == TextDirection.ltr) x += width;
      child = childAfter(child);
    }
    size = constraints.constrain(Size(constraints.maxWidth, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
