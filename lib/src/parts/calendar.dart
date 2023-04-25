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
  });

  final bool wide;
  final ValueNotifier<DateTime> dateState;
  final void Function(DateTime date) onChange;
  final BoxDecoration boxDecoration;
  final Color? textColor;
  final Color activeColor;
  final Color activeTextColor;
  final BoardPickerLanguages languages;

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  /// Calendar PageeController
  final pageController = PageController(initialPage: 999);
  final int initialPage = 999;

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
    currentPage = initialPage;
    initialDate = widget.dateState.value;
    selectedDate = initialDate;
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
    return PageView.builder(
      controller: pageController,
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
                  onPressed: () {
                    pageController.previousPage(
                        duration: pageDuration, curve: pageCurve);
                  },
                  icon: const Opacity(
                    opacity: 0.6,
                    child: Icon(
                      Icons.arrow_back_rounded,
                    ),
                  ),
                  color: widget.textColor,
                ),
                IconButton(
                  onPressed: () {
                    pageController.nextPage(
                        duration: pageDuration, curve: pageCurve);
                  },
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
            DateFormat('MMMM').format(date),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: widget.textColor,
                ),
          ),
          const SizedBox(width: 8),
          Opacity(
            opacity: 0.4,
            child: Text(
              DateFormat('yyyy').format(date),
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
    final weekdays = widget.languages.weekdays;
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
                        color: textColor(i),
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

    for (var i = 1; i <= y.day; i++) {
      list.add(_monthItem(x, i));
    }
    return list;
  }

  /// Widget to display date item
  Widget _monthItem(DateTime first, int i) {
    final z = first.add(Duration(days: i - 1));
    final selected = z.compareDate(selectedDate);

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: () {
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
                          : textColor(z.weekday),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Text Color
  Color? textColor(int weekday) {
    if (weekday == 7 || weekday == 0) {
      return Colors.red;
    } else if (weekday == 6) {
      return Colors.blue;
    }
    return widget.textColor;
  }
}
