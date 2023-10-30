import 'package:board_datetime_picker/src/board_datetime_options.dart';
import 'package:board_datetime_picker/src/utils/datetime_util.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({
    super.key,
    required this.dateState,
    required this.onChange,
    required this.boxDecoration,
    required this.textColor,
    required this.wide,
    required this.activeColor,
    required this.activeTextColor,
    required this.languages,
    required this.minimumDate,
    required this.maximumDate,
  });

  final bool wide;
  final ValueNotifier<DateTime> dateState;
  final void Function(DateTime date) onChange;
  final BoxDecoration boxDecoration;
  final Color? textColor;
  final Color activeColor;
  final Color activeTextColor;
  final BoardPickerLanguages languages;
  final DateTime minimumDate;
  final DateTime maximumDate;

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  /// Calendar PageeController
  late PageController pageController;

  /// PageView count
  late int pageCount;
  int initialPage = 999;

  /// Current Page for controller
  late int currentPage;

  late DateTime selectedDate;
  late DateTime initialDate;

  /// Animation during page transitions
  final pageDuration = const Duration(milliseconds: 300);
  final pageCurve = Curves.easeIn;

  double get topMargin => widget.wide ? 8 : 20;

  @override
  void initState() {
    initialDate = widget.dateState.value;
    selectedDate = initialDate;

    /// Calculate the number of pages to display in the calendar
    /// from the minimum and maximum dates
    int count = (widget.maximumDate.year - widget.minimumDate.year + 1) * 12;
    count -= (widget.minimumDate.month - 1);
    count -= (12 - widget.maximumDate.month);
    pageCount = count;

    initialPage = diffYMD(widget.minimumDate, initialDate);
    pageController = PageController(initialPage: initialPage);

    currentPage = initialPage;

    super.initState();

    widget.dateState.addListener(changeListener);
  }

  void changeListener() {
    final d = widget.dateState.value;
    final diff = diffYMD(initialDate, d);
    if (mounted) {
      if (pageController.hasClients) {
        pageController.animateToPage(
          initialPage + diff,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      setState(() {
        selectedDate = d;
      });
    }
  }

  int diffYMD(DateTime then, DateTime now) {
    int years = now.year - then.year;
    int months = now.month - then.month;
    return years * 12 + months;
  }

  @override
  void dispose() {
    widget.dateState.removeListener(changeListener);
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: _calendar()),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _moveButtons(),
        ),
      ],
    );
  }

  Widget _calendar() {
    return NotificationListener<ScrollNotification>(
      child: PageView.builder(
        controller: pageController,
        itemCount: pageCount,
        itemBuilder: (context, index) {
          final diff = index - initialPage;
          final date = initialDate.calcMonth(diff);

          return Column(
            children: [
              _displayed(date),
              _weekdays(),
              Expanded(
                child: GridView(
                  padding: const EdgeInsets.all(0),
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                  ),
                  children: _generateCalendarOfMonth(date),
                ),
              ),
            ],
          );
        },
        onPageChanged: (index) {
          currentPage = index;
        },
      ),
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          setState(() {});
        }
        return true;
      },
    );
  }

  /// Button to change year and month
  Widget _moveButtons() {
    return Container(
      height: 40,
      margin: EdgeInsets.only(top: topMargin, left: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: widget.boxDecoration,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: currentPage != 0
                      ? () {
                          pageController.previousPage(
                              duration: pageDuration, curve: pageCurve);
                        }
                      : null,
                  icon: const Opacity(
                    opacity: 0.6,
                    child: Icon(
                      Icons.arrow_back_rounded,
                    ),
                  ),
                  color: widget.textColor,
                ),
                IconButton(
                  onPressed: currentPage != pageCount - 1
                      ? () {
                          pageController.nextPage(
                              duration: pageDuration, curve: pageCurve);
                        }
                      : null,
                  icon: const Opacity(
                    opacity: 0.6,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                    ),
                  ),
                  color: widget.textColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Year and month being displayed
  Widget _displayed(DateTime date) {
    return Container(
      height: 40,
      margin: EdgeInsets.only(top: topMargin, left: 12),
      child: Row(
        children: [
          Text(
            DateFormat.MMMM(widget.languages.locale).format(date),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: widget.textColor,
                ),
          ),
          const SizedBox(width: 8),
          Opacity(
            opacity: 0.4,
            child: Text(
              DateFormat.y(widget.languages.locale).format(date),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: widget.textColor,
                  ),
            ),
          ),
          Expanded(child: Container()),
        ],
      ),
    );
  }

  /// Display day of the week
  Widget _weekdays() {
    final weekdays = widget.languages.weekdays ??
        DateFormat.EEEE(widget.languages.locale).dateSymbols.SHORTWEEKDAYS;
    return Container(
      height: 24,
      margin: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          for (var i = 0; i < weekdays.length; i++)
            Expanded(
              child: Center(
                child: Text(
                  weekdays[i],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textColor(i, false),
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Generate a list of items in the calendar
  List<Widget> _generateCalendarOfMonth(DateTime date) {
    // Get beginning of month and end of month
    final x = DateTime(date.year, date.month, 1);
    final y = DateTime(date.year, date.month + 1, 1).add(
      const Duration(days: -1),
    );

    List<Widget> list = [];
    final first = x.weekday;
    // Add a Container to display a blank space
    // if the first day of the week is not Sunday.
    if (first != 7) {
      for (var i = 0; i < first; i++) {
        list.add(Container());
      }
    }

    // Inactive if less than the specified minimum date on the first page
    // or greater than the specified maximum date on the last page
    List<int> diabledList = [];
    if (date.year == widget.minimumDate.year &&
        date.month == widget.minimumDate.month) {
      diabledList.addAll(
        [for (var i = 1; i < widget.minimumDate.day; i++) i],
      );
    } else if (date.year == widget.maximumDate.year &&
        date.month == widget.maximumDate.month) {
      diabledList.addAll(
        [for (var i = widget.maximumDate.day + 1; i <= y.day; i++) i],
      );
    }

    for (var i = 1; i <= y.day; i++) {
      list.add(_monthItem(x, i, diabledList.contains(i)));
    }
    return list;
  }

  /// Widget to display date item
  Widget _monthItem(DateTime first, int i, bool disabled) {
    final z = first.addDay(i - 1);
    final selected = z.compareDate(selectedDate);

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: disabled
            ? null
            : () {
                setState(() {
                  selectedDate = z;
                });
                final to = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  initialDate.hour,
                  initialDate.minute,
                );
                widget.onChange(to);
              },
        child: Center(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? widget.activeColor : Colors.transparent,
            ),
            child: Center(
              child: Text(
                '$i',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: selected
                          ? widget.activeTextColor
                          : textColor(z.weekday, disabled),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Text Color
  Color? textColor(int weekday, bool disabled) {
    if (disabled) {
      return widget.textColor?.withOpacity(0.4);
    } else if (weekday == 7 || weekday == 0) {
      return Colors.red;
    } else if (weekday == 6) {
      return Colors.blue;
    }
    return widget.textColor;
  }
}
