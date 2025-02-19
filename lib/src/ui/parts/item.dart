import 'dart:async';

import 'package:board_datetime_picker/src/options/board_item_option.dart';
import 'package:board_datetime_picker/src/utils/board_enum.dart';
import 'package:board_datetime_picker/src/utils/datetime_util.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'focus_node.dart';

class ItemWidget extends StatefulWidget {
  const ItemWidget({
    super.key,
    required this.option,
    required this.onChange,
    required this.foregroundColor,
    required this.textColor,
    required this.showedKeyboard,
    required this.wide,
    required this.subTitle,
    required this.inputable,
  });

  final BoardPickerItemOption option;
  final void Function(int) onChange;
  final Color foregroundColor;
  final Color? textColor;
  final bool Function() showedKeyboard;
  final bool wide;
  final String? subTitle;
  final bool inputable;

  @override
  State<ItemWidget> createState() => ItemWidgetState();
}

class ItemWidgetState extends State<ItemWidget>
    with SingleTickerProviderStateMixin {
  final double itemSize = 44;
  final duration = const Duration(milliseconds: 200);
  final borderRadius = BorderRadius.circular(12);

  /// ScrollController
  late FixedExtentScrollController scrollController;

  /// TextField Controller
  late TextEditingController textController;

  /// Correction Animation Controller
  late AnimationController correctAnimationController;
  late Animation<Color?> correctColor;

  /// Picker list
  Map<int, int> map = {};

  int selectedIndex = 0;
  bool isTextEditing = false;

  /// Timer for debouncing process
  Timer? debouceTimer;
  Timer? wheelDebouceTimer;

  /// Number of items to display in the list
  int get wheelCount => widget.wide ? 7 : 5;

  /// Short name of items to display in the list
  Map<int, String> monthMap = {};

  final pickerFocusNode = PickerWheelItemFocusNode();

  bool get useAmpmMode {
    return widget.option.type == DateType.hour &&
        widget.option.useAmpm &&
        widget.option.ampm != null;
  }

  void setMap({Map<int, int>? newMap}) {
    if (useAmpmMode) {
      final values = widget.option.itemMap.values.toList();
      final mapEntry = DateTimeUtil.ampmContrastMap.entries.where((x) {
        return values.contains(x.key) && x.value.ampm == widget.option.ampm;
      }).toList();
      map = {
        for (var i = 0; i < mapEntry.length; i++) i: mapEntry[i].value.hour,
      };
    } else {
      map = newMap ?? widget.option.itemMap;
    }
  }

  int getWheelIndex(int index) {
    if (useAmpmMode) {
      final hour = widget.option.itemMap[index];
      final cotrast = DateTimeUtil.ampmContrastMap[hour]!;
      final i = map.entries
          .firstWhereOrNull(
            (x) => x.value == cotrast.hour,
          )
          ?.key;
      return i ?? cotrast.index;
      // return DateTimeUtil.ampmContrastMap[hour]!.index;
    } else {
      return index;
    }
  }

  /// Notify caller of changed index
  void callbackOnChange(int index) {
    if (useAmpmMode) {
      Map<int, AmpmCotrast> contrastMap;
      if (widget.option.ampm! == AmPm.am) {
        contrastMap = DateTimeUtil.ampmContrastAmMap;
      } else {
        contrastMap = DateTimeUtil.ampmContrastPmMap;
      }

      final hour = map[index];
      final mapIndex =
          contrastMap.entries.firstWhereOrNull((e) => e.value.hour == hour);
      if (mapIndex != null) {
        final idx = widget.option.itemMap.entries.firstWhereOrNull(
          (e) => e.value == mapIndex.key,
        );
        if (idx != null) {
          widget.onChange(idx.key);
        }
      }
    } else {
      widget.onChange(index);
    }
  }

  @override
  void initState() {
    setMap();
    selectedIndex = getWheelIndex(widget.option.selectedIndex);
    scrollController = FixedExtentScrollController(
      initialItem: selectedIndex,
    );
    textController = TextEditingController(text: '${map[selectedIndex]}');
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );

    widget.option.focusNode.addListener(focusListener);

    correctAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    correctColor = ColorTween(
      begin: widget.foregroundColor,
      end: Colors.redAccent.withValues(alpha: 0.8),
    ).animate(correctAnimationController);

    correctAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        correctAnimationController.reverse();
      }
    });

    if (widget.option.type == DateType.month) {
      monthMap = widget.option.monthMap();
    }

    super.initState();
  }

  @override
  void dispose() {
    widget.option.focusNode.removeListener(focusListener);
    scrollController.dispose();
    textController.dispose();
    super.dispose();
  }

  void focusListener() {
    changeText(textController.text, toDefault: true);
    if (widget.option.focusNode.hasFocus && !isTextEditing) {
      setState(() {
        isTextEditing = true;
      });
    }
  }

  void onChange(int index) {
    setState(() {
      selectedIndex = index;
    });

    void setText() {
      final day = map[selectedIndex]!;
      final text = widget.option.isMonthText ? monthMap[day]! : day.toString();
      if (textController.text != text) {
        textController.text = text;
      }
      debouceTimer?.cancel();
      debouceTimer = null;
    }

    // Debounce process to prevent inadvertent text updates when in focus
    if (widget.option.focusNode.hasFocus) {
      debouceTimer?.cancel();
      // Ignore empty characters as they do not need to be scrolled.
      if (textController.text != '') {
        debouceTimer = Timer(const Duration(milliseconds: 300), setText);
      }
    } else {
      setText();
    }
  }

  void toAnimateChange(int index, {bool button = false}) {
    if (!widget.option.itemMap.keys.contains(index)) return;
    selectedIndex = getWheelIndex(index);
    scrollController.animateToItem(
      index,
      duration: duration,
      curve: Curves.easeIn,
    );
  }

  void updateState(Map<int, int> newMap, int newIndex) {
    if (!mounted) return;

    bool needAnimation = false;
    setState(() {
      // 表示する数字が同じ場合はアニメーションしない
      final oldValue = map[selectedIndex];

      setMap(newMap: newMap);
      final newWheelIndex = getWheelIndex(newIndex);
      if (selectedIndex != newWheelIndex) {
        selectedIndex = newWheelIndex;

        final newValue = map[newWheelIndex];

        if (oldValue != newValue) {
          needAnimation = true;
        }
      }
    });

    Future.delayed(const Duration(milliseconds: 10)).then((_) {
      if (needAnimation) {
        scrollController.animateToItem(
          selectedIndex,
          duration: duration,
          curve: Curves.easeIn,
        );
      } else {
        scrollController.jumpToItem(selectedIndex);
      }
    });
  }

  void _updateFocusNode() {
    final pf = FocusManager.instance.primaryFocus;
    if (pf is! PickerItemFocusNode && pf is! BoardDateTimeInputFocusNode) {
      pickerFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          if (widget.subTitle != null) ...[
            Container(
              height: widget.wide ? 40 : 32,
              width: double.infinity,
              alignment: Alignment.bottomCenter,
              padding: EdgeInsets.only(bottom: widget.wide ? 8 : 4),
              child: Text(
                widget.subTitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.textColor?.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
          Expanded(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: AnimatedBuilder(
                    animation: correctAnimationController,
                    builder: (context, child) {
                      return Material(
                        color: correctColor.value,
                        borderRadius: borderRadius,
                        child: SizedBox(
                          height: itemSize,
                          width: double.infinity,
                        ),
                      );
                    },
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: NotificationListener(
                      child: SizedBox(
                        height: itemSize * wheelCount,
                        child: GestureDetector(
                          child: Focus(
                            focusNode: pickerFocusNode,
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
                          ),
                          onTapDown: (details) {
                            _updateFocusNode();
                          },
                          onTapUp: (details) {
                            double clickOffset;
                            if (widget.showedKeyboard()) {
                              clickOffset =
                                  details.localPosition.dy - (itemSize * 3 / 2);
                            } else {
                              clickOffset = details.localPosition.dy -
                                  (itemSize * wheelCount / 2);
                            }
                            final currentIndex = scrollController.selectedItem;
                            final indexOffset =
                                (clickOffset / itemSize).round();
                            final newIndex = currentIndex + indexOffset;
                            toAnimateChange(newIndex);

                            _updateFocusNode();
                          },
                        ),
                      ),
                      onNotification: (info) {
                        if (info is ScrollEndNotification) {
                          // Change callback
                          callbackOnChange(selectedIndex);
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
                      onTap: widget.inputable
                          ? () {
                              setState(() {
                                isTextEditing = true;
                              });
                              Future.delayed(const Duration(milliseconds: 10))
                                  .then((_) {
                                widget.option.focusNode.requestFocus();
                              });
                            }
                          : null,
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
                  maintainState: widget.inputable,
                  child: _centerAlign(
                    TextField(
                      key: ValueKey(widget.option.type.name),
                      controller: textController,
                      focusNode: widget.option.focusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(bottom: 4, left: 2),
                      ),
                      enabled: widget.inputable,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: widget.textColor,
                          ),
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          widget.option.maxLength,
                        ),
                        // AllowTextInputFormatter(map.values.toList()),
                      ],
                      onChanged: onChangeText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Converts input text to an index
  int? _convertTextToIndex(String text) {
    try {
      int data;
      if (widget.option.isMonthText) {
        // If the input value is a date, get the index of the month
        try {
          data = int.parse(text);
        } catch (_) {
          data = monthMap.entries
              .firstWhereOrNull(
                (e) => e.value == text,
              )!
              .key;
        }
      } else {
        data = int.parse(text);
      }

      // Get index from input value
      int index = -1;
      for (final key in map.keys) {
        if (map[key]! == data) {
          index = key;
          break;
        }
      }
      return index;
    } catch (_) {
      return null;
    }
  }

  /// Converts input text into an index and performs change notifications
  void changeText(String text, {bool toDefault = false}) {
    int? index = _convertTextToIndex(text);

    // If non-numeric or empty, set to the first value
    if (index == null) {
      index = selectedIndex;
      final day = map[index]!;
      textController.text =
          widget.option.isMonthText ? monthMap[day]! : day.toString();
    }

    if (toDefault) {
      if (index == selectedIndex) return;
      if (index < 0) {
        index = selectedIndex;
        final day = map[index]!;
        textController.text =
            widget.option.isMonthText ? monthMap[day]! : day.toString();

        // If corrected, animation is performed
        correctAnimationController.forward();
      }
    } else {
      if (index < 0) return;
    }

    // Animated wheel movement
    toAnimateChange(index);
    // Change callback
    callbackOnChange(index);
  }

  /// Processing when text is changed
  void onChangeText(String text) {
    wheelDebouceTimer?.cancel();

    final index = _convertTextToIndex(text);
    if (index == null || index < 0) return;
    // Animated wheel movement
    wheelDebouceTimer = Timer(
      const Duration(milliseconds: 200),
      () {
        wheelDebouceTimer?.cancel();
        wheelDebouceTimer = null;
        toAnimateChange(index);
      },
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
    TextStyle? textStyle = Theme.of(context).textTheme.bodyLarge;

    if (selectedIndex == i) {
      textStyle = textStyle?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 17,
        color: widget.textColor?.withValues(alpha: isTextEditing ? 0.0 : 1.0),
      );
    } else {
      textStyle = textStyle?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: widget.textColor?.withValues(alpha: 0.4),
      );
    }

    String text = '${map[i]}';
    if (widget.option.isMonthText) {
      text = monthMap[map[i]]!;
    }

    return Center(
      child: Text(
        text,
        style: textStyle,
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
        final x = list.where(
          (x) => x.toString().contains(newValue.text),
        );
        if (x.isEmpty) {
          return oldValue;
        }
      }
    } catch (_) {
      return oldValue;
    }
    return newValue;
  }
}

class AmpmItemWidget extends StatefulWidget {
  const AmpmItemWidget({
    super.key,
    required this.initialValue,
    required this.onChange,
    required this.foregroundColor,
    required this.showedKeyboard,
    required this.textColor,
    required this.wide,
  });

  final AmPm initialValue;
  final void Function(AmPm) onChange;
  final Color foregroundColor;
  final bool Function() showedKeyboard;
  final Color? textColor;
  final bool wide;

  @override
  State<AmpmItemWidget> createState() => AmpmItemWidgetState();
}

class AmpmItemWidgetState extends State<AmpmItemWidget> {
  final double itemSize = 44;
  final duration = const Duration(milliseconds: 200);
  final borderRadius = BorderRadius.circular(12);

  int selectedIndex = 0;

  final pickerFocusNode = PickerWheelItemFocusNode();

  /// ScrollController
  late FixedExtentScrollController scrollController;

  final Map<int, AmPm> map = {0: AmPm.am, 1: AmPm.pm};

  /// Number of items to display in the list
  int get wheelCount => widget.wide ? 7 : 5;

  AmPm getAmPmByIndex(int index) {
    return map[index]!;
  }

  @override
  void initState() {
    selectedIndex = widget.initialValue == AmPm.am ? 0 : 1;
    scrollController = FixedExtentScrollController(
      initialItem: selectedIndex,
    );
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void onChange(int index) {
    setState(() {
      selectedIndex = index;
    });
    widget.onChange(getAmPmByIndex(index));
  }

  void updateState(AmPm ampm) {
    if (!mounted) return;
    final index = ampm == AmPm.am ? 0 : 1;
    if (selectedIndex == index) return;
    toAnimateChange(index);
  }

  void toAnimateChange(int index, {bool button = false}) {
    if (!map.containsKey(index)) return;

    selectedIndex = index;
    scrollController.animateToItem(
      index,
      duration: duration,
      curve: Curves.easeIn,
    );
  }

  void _updateFocusNode() {
    final pf = FocusManager.instance.primaryFocus;
    if (pf is! PickerItemFocusNode && pf is! BoardDateTimeInputFocusNode) {
      pickerFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Expanded(
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
                        height: itemSize * wheelCount,
                        child: GestureDetector(
                          child: Focus(
                            focusNode: pickerFocusNode,
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
                          ),
                          onTapDown: (details) {},
                          onTapUp: (details) {
                            double clickOffset;
                            if (widget.showedKeyboard()) {
                              clickOffset =
                                  details.localPosition.dy - (itemSize * 3 / 2);
                            } else {
                              clickOffset = details.localPosition.dy -
                                  (itemSize * wheelCount / 2);
                            }
                            final currentIndex = scrollController.selectedItem;
                            final indexOffset =
                                (clickOffset / itemSize).round();
                            final newIndex = currentIndex + indexOffset;
                            toAnimateChange(newIndex);

                            _updateFocusNode();
                          },
                        ),
                      ),
                      onNotification: (info) {
                        if (info is ScrollEndNotification) {
                          // Change callback
                          widget.onChange(getAmPmByIndex(selectedIndex));
                        }
                        return true;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(int i) {
    TextStyle? textStyle = Theme.of(context).textTheme.bodyLarge;
    if (selectedIndex == i) {
      textStyle = textStyle?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 17,
        color: widget.textColor?.withValues(alpha: 1.0),
      );
    } else {
      textStyle = textStyle?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: widget.textColor?.withValues(alpha: 0.4),
      );
    }

    return Center(
      child: Text(
        map[i]!.display,
        style: textStyle,
      ),
    );
  }
}
