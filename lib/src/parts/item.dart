import 'package:board_datetime_picker/src/utils/board_enum.dart';
import 'package:board_datetime_picker/src/utils/board_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ItemWidget extends StatefulWidget {
  const ItemWidget({
    super.key,
    required this.option,
    required this.onChange,
    required this.foregroundColor,
    required this.textColor,
  });

  final BoardPickerItemOption option;
  final void Function(int) onChange;
  final Color foregroundColor;
  final Color? textColor;

  @override
  State<ItemWidget> createState() => ItemWidgetState();
}

class ItemWidgetState extends State<ItemWidget> {
  final double itemSize = 44;
  final duration = const Duration(milliseconds: 200);
  final borderRadius = BorderRadius.circular(12);

  /// ScrollController
  late FixedExtentScrollController scrollController;

  /// TextField Controller
  late TextEditingController textController;

  /// Picker list
  List<int> list = [];

  int selected = 0;
  bool isTextEditing = false;

  @override
  void initState() {
    list = widget.option.list;
    selected = widget.option.selected;
    scrollController = FixedExtentScrollController(
      initialItem: widget.option.getIndex(),
    );
    textController = TextEditingController(text: '$selected');

    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    textController.dispose();
    super.dispose();
  }

  void onChange(int index) {
    setState(() {
      selected = widget.option.getValueFromIndex(index);
    });
    textController.text = '$selected';
  }

  void toAnimateChange(int index, {bool button = false}) {
    if (!widget.option.list.contains(index)) return;

    selected = index;
    scrollController.animateToItem(
      widget.option.getIndex(index: selected),
      duration: duration,
      curve: Curves.easeIn,
    );
  }

  void updateState(List<int> newList) {
    setState(() {
      list = newList;
      if (widget.option.getIndex(index: selected) >= list.length) {
        selected = list.last;
        scrollController.animateToItem(
          widget.option.getIndex(index: selected),
          duration: duration,
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Material(
              color: widget.foregroundColor,
              borderRadius: borderRadius,
              child: SizedBox(
                height: itemSize,
                width: double.infinity,
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: NotificationListener(
                child: SizedBox(
                  height: itemSize * 5,
                  child: GestureDetector(
                    child: ListWheelScrollView.useDelegate(
                      controller: scrollController,
                      physics: const FixedExtentScrollPhysics(),
                      itemExtent: itemSize,
                      diameterRatio: 8,
                      perspective: 0.01,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      onSelectedItemChanged: onChange,
                      childDelegate: ListWheelChildListDelegate(
                        children: [
                          for (final i in list) _item(i),
                        ],
                      ),
                    ),
                    onTapUp: (details) {
                      final clickOffset =
                          details.localPosition.dy - (itemSize * 5 / 2);
                      final currentIndex = scrollController.selectedItem;
                      final indexOffset = (clickOffset / itemSize).round();
                      final newIndex = currentIndex + indexOffset;
                      toAnimateChange(list[newIndex]);
                    },
                  ),
                ),
                onNotification: (info) {
                  if (info is ScrollEndNotification) {
                    // Change callback
                    widget.onChange(selected);
                  }
                  return true;
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    isTextEditing = true;
                  });
                  Future.delayed(const Duration(milliseconds: 10)).then((_) {
                    widget.option.focusNode.requestFocus();
                  });
                },
                borderRadius: borderRadius,
                child: SizedBox(
                  height: itemSize,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          Visibility(
            visible: isTextEditing,
            child: _centerAlign(
              TextField(
                controller: textController,
                focusNode: widget.option.focusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 4, left: 2),
                ),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: widget.textColor,
                    ),
                textAlign: TextAlign.center,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(widget.option.maxLength),
                  if (widget.option.type != DateType.year)
                    AllowTextInputFormatter(list),
                ],
                onChanged: (text) {
                  try {
                    final data = int.parse(text);
                    // Performed only if the entered value is in the list
                    if (!widget.option.list.contains(data)) return;

                    // Animated wheel movement
                    toAnimateChange(data);
                    // Change callback
                    widget.onChange(data);
                  } catch (_) {
                    return;
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerAlign(Widget child) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: itemSize,
        width: double.infinity,
        child: child,
      ),
    );
  }

  Widget _item(int i) {
    double opacity = 1.0;
    TextStyle? textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: widget.textColor,
        );
    if (selected == i) {
      textStyle = textStyle?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 17,
      );
      opacity = isTextEditing ? 0.0 : 1.0;
    } else {
      textStyle = textStyle?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 14,
      );
      opacity = 0.4;
    }

    return Center(
      child: Opacity(
        opacity: opacity,
        child: Text(
          '$i',
          style: textStyle,
        ),
      ),
    );
  }
}

class AllowTextInputFormatter extends TextInputFormatter {
  AllowTextInputFormatter(this.list);

  final List<int> list;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    try {
      final value = int.parse(newValue.text);
      if (!list.contains(value)) {
        return oldValue;
      }
    } catch (_) {
      return oldValue;
    }
    return newValue;
  }
}
