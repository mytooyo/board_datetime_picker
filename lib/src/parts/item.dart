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
  Map<int, int> map = {};

  int selectedIndex = 0;
  bool isTextEditing = false;

  @override
  void initState() {
    map = widget.option.map;
    selectedIndex = widget.option.selectedIndex;
    scrollController = FixedExtentScrollController(
      initialItem: selectedIndex,
    );
    textController = TextEditingController(text: '${map[selectedIndex]}');

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
      selectedIndex = index;
    });
    textController.text = '${map[selectedIndex]}';
  }

  void toAnimateChange(int index, {bool button = false}) {
    if (!widget.option.map.keys.contains(index)) return;

    selectedIndex = index;
    scrollController.animateToItem(
      index,
      duration: duration,
      curve: Curves.easeIn,
    );
  }

  void updateState(Map<int, int> newMap, int newIndex) {
    setState(() {
      map = newMap;
      if (selectedIndex != newIndex) {
        selectedIndex = newIndex;
        scrollController.animateToItem(
          selectedIndex,
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
                          for (final i in map.keys) _item(i),
                        ],
                      ),
                    ),
                    onTapUp: (details) {
                      final clickOffset =
                          details.localPosition.dy - (itemSize * 5 / 2);
                      final currentIndex = scrollController.selectedItem;
                      final indexOffset = (clickOffset / itemSize).round();
                      final newIndex = currentIndex + indexOffset;
                      toAnimateChange(newIndex);
                    },
                  ),
                ),
                onNotification: (info) {
                  if (info is ScrollEndNotification) {
                    // Change callback
                    widget.onChange(selectedIndex);
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
                  AllowTextInputFormatter(map.values.toList()),
                ],
                onChanged: (text) {
                  try {
                    final data = int.parse(text);

                    // Get index from input value
                    int index = -1;
                    for (final key in map.keys) {
                      if (map[key]! == data) {
                        index = key;
                        break;
                      }
                    }
                    if (index < 0) return;

                    // Animated wheel movement
                    toAnimateChange(index);
                    // Change callback
                    widget.onChange(index);
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
    if (selectedIndex == i) {
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
          '${map[i]}',
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
