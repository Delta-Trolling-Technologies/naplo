import 'dart:math';
import 'package:animations/animations.dart';
import 'package:filcnaplo/api/providers/update_provider.dart';
import 'package:filcnaplo/models/settings.dart';
// TODO: gulag calendar sync
// import 'package:filcnaplo/providers/third_party_provider.dart';
import 'package:filcnaplo/utils/format.dart';
import 'package:filcnaplo_kreta_api/client/client.dart';
import 'package:filcnaplo_kreta_api/models/week.dart';
import 'package:filcnaplo_kreta_api/providers/timetable_provider.dart';
import 'package:filcnaplo/api/providers/user_provider.dart';
import 'package:filcnaplo/theme/colors/colors.dart';
import 'package:filcnaplo_kreta_api/models/lesson.dart';
import 'package:filcnaplo_mobile_ui/common/dot.dart';
import 'package:filcnaplo_mobile_ui/common/empty.dart';
import 'package:filcnaplo_mobile_ui/common/profile_image/profile_button.dart';
import 'package:filcnaplo_mobile_ui/common/profile_image/profile_image.dart';
import 'package:filcnaplo_mobile_ui/common/system_chrome.dart';
import 'package:filcnaplo_mobile_ui/common/widgets/lesson/lesson_view.dart';
import 'package:filcnaplo_kreta_api/controllers/timetable_controller.dart';
import 'package:filcnaplo_mobile_ui/common/widgets/lesson/lesson_viewable.dart';
import 'package:filcnaplo_mobile_ui/pages/timetable/day_title.dart';
import 'package:filcnaplo_mobile_ui/pages/timetable/fs_timetable.dart';
import 'package:filcnaplo_mobile_ui/screens/navigation/navigation_route_handler.dart';
import 'package:filcnaplo_mobile_ui/screens/navigation/navigation_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:i18n_extension/i18n_widget.dart';
import 'timetable_page.i18n.dart';

// todo: "fix" overflow (priority: -1)

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key, this.initialDay, this.initialWeek});

  final DateTime? initialDay;
  final Week? initialWeek;

  static void jump(BuildContext context,
      {Week? week, DateTime? day, Lesson? lesson}) {
    // Go to timetable page with arguments
    NavigationScreen.of(context)
        ?.customRoute(navigationPageRoute((context) => TimetablePage(
              initialDay: lesson?.date ?? day,
              initialWeek: lesson?.date != null
                  ? Week.fromDate(lesson!.date)
                  : day != null
                      ? Week.fromDate(day)
                      : week,
            )));

    NavigationScreen.of(context)?.setPage("timetable");

    // Show initial Lesson
    if (lesson != null) LessonView.show(lesson, context: context);
  }

  @override
  TimetablePageState createState() => TimetablePageState();
}

class TimetablePageState extends State<TimetablePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late UserProvider user;
  late TimetableProvider timetableProvider;
  late UpdateProvider updateProvider;
  late SettingsProvider settingsProvider;

  late String firstName;

  late TimetableController _controller;
  late TabController _tabController;

  late Widget empty;

  int _getDayIndex(DateTime date) {
    int index = 0;
    if (_controller.days == null || (_controller.days?.isEmpty ?? true)) {
      return index;
    }

    // find the first day with upcoming lessons
    index = _controller.days!.indexWhere((day) => day.last.end.isAfter(date));
    if (index == -1) index = 0; // fallback

    return index;
  }

  // Update timetable on user change
  Future<void> _userListener() async {
    await Provider.of<KretaClient>(context, listen: false).refreshLogin();
    if (mounted) _controller.jump(_controller.currentWeek, context: context);
  }

  // When the app comes to foreground, refresh the timetable
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) _controller.jump(_controller.currentWeek, context: context);
    }
  }

  @override
  void initState() {
    super.initState();

    // Initalize controllers
    _controller = TimetableController();
    _tabController = TabController(length: 0, vsync: this, initialIndex: 0);

    empty = Empty(subtitle: "empty".i18n);

    bool initial = true;

    // Only update the TabController on week changes
    _controller.addListener(() {
      if (_controller.days == null) return;
      setState(() {
        _tabController = TabController(
          length: _controller.days!.length,
          vsync: this,
          initialIndex:
              min(_tabController.index, max(_controller.days!.length - 1, 0)),
        );

        if (initial ||
            _controller.previousWeekId != _controller.currentWeekId) {
          _tabController
              .animateTo(_getDayIndex(widget.initialDay ?? DateTime.now()));
        }
        initial = false;

        // Empty is updated once every week change
        empty = Empty(subtitle: "empty".i18n);
      });
    });

    if (mounted) {
      if (widget.initialWeek != null) {
        _controller.jump(widget.initialWeek!, context: context, initial: true);
      } else {
        _controller.jump(_controller.currentWeek,
            context: context, initial: true, skip: true);
      }
    }

    // Listen for user changes
    user = Provider.of<UserProvider>(context, listen: false);
    user.addListener(_userListener);

    // Register listening for app state changes to refresh the timetable
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    user.removeListener(_userListener);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String dayTitle(int index) {
    // Sometimes when changing weeks really fast,
    // controller.days might be null or won't include index
    try {
      return DateFormat("EEEE", I18n.of(context).locale.languageCode)
          .format(_controller.days![index].first.date);
    } catch (e) {
      return "timetable".i18n;
    }
  }

  @override
  Widget build(BuildContext context) {
    user = Provider.of<UserProvider>(context);
    timetableProvider = Provider.of<TimetableProvider>(context);
    updateProvider = Provider.of<UpdateProvider>(context);
    settingsProvider = Provider.of<SettingsProvider>(context);

    // First name
    List<String> nameParts = user.displayName?.split(" ") ?? ["?"];
    firstName = nameParts.length > 1 ? nameParts[1] : nameParts[0];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 9.0),
        child: RefreshIndicator(
          onRefresh: () => mounted
              ? _controller.jump(_controller.currentWeek,
                  context: context, loader: false)
              : Future.value(null),
          color: Theme.of(context).colorScheme.secondary,
          edgeOffset: 132.0,
          child: NestedScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                centerTitle: false,
                pinned: true,
                floating: false,
                snap: false,
                surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      splashRadius: 24.0,
                      // tested timetable sync
                      // onPressed: () async {
                      //   ThirdPartyProvider tpp =
                      //       Provider.of<ThirdPartyProvider>(context,
                      //           listen: false);

                      //   await tpp.pushTimetable(context, _controller);
                      // },
                      onPressed: () {
                        // If timetable empty, show empty
                        if (_tabController.length == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("empty_timetable".i18n),
                            duration: const Duration(seconds: 2),
                          ));
                          return;
                        }

                        Navigator.of(context, rootNavigator: true)
                            .push(PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  FSTimetable(
                            controller: _controller,
                          ),
                        ))
                            .then((_) {
                          SystemChrome.setPreferredOrientations(
                              [DeviceOrientation.portraitUp]);
                          setSystemChrome(context);
                        });
                      },
                      icon: Icon(FeatherIcons.trello,
                          color: AppColors.of(context).text),
                    ),
                  ),

                  // Profile Icon
                  Padding(
                    padding: const EdgeInsets.only(right: 24.0),
                    child: ProfileButton(
                      child: ProfileImage(
                        heroTag: "profile",
                        name: firstName,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary, //ColorUtils.stringToColor(user.displayName ?? "?"),
                        badge: updateProvider.available,
                        role: user.role,
                        profilePictureString: user.picture,
                      ),
                    ),
                  ),
                ],
                automaticallyImplyLeading: false,
                // Current day text
                title: PageTransitionSwitcher(
                  reverse:
                      _controller.currentWeekId < _controller.previousWeekId,
                  transitionBuilder: (
                    Widget child,
                    Animation<double> primaryAnimation,
                    Animation<double> secondaryAnimation,
                  ) {
                    return SharedAxisTransition(
                      animation: primaryAnimation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      child: child,
                    );
                  },
                  layoutBuilder: (List<Widget> entries) {
                    return Stack(
                      children: entries,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Row(
                      children: [
                        () {
                          final show = _controller.days == null ||
                              (_controller.loadType != LoadType.offline &&
                                  _controller.loadType != LoadType.online);
                          const duration = Duration(milliseconds: 150);
                          return AnimatedOpacity(
                            opacity: show ? 1.0 : 0.0,
                            duration: duration,
                            curve: Curves.easeInOut,
                            child: AnimatedContainer(
                              duration: duration,
                              width: show ? 24.0 : 0.0,
                              curve: Curves.easeInOut,
                              child: const Padding(
                                padding: EdgeInsets.only(right: 12.0),
                                child: CupertinoActivityIndicator(),
                              ),
                            ),
                          );
                        }(),
                        () {
                          if ((_controller.days?.length ?? 0) > 0) {
                            return DayTitle(
                                controller: _tabController, dayTitle: dayTitle);
                          } else {
                            return Text(
                              "timetable".i18n,
                              style: TextStyle(
                                fontSize: 32.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.of(context).text,
                              ),
                            );
                          }
                        }(),
                      ],
                    ),
                  ),
                ),
                shadowColor: Theme.of(context).shadowColor,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(50.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Previous week
                        IconButton(
                            onPressed: _controller.currentWeekId == 0
                                ? null
                                : () => setState(() {
                                      _controller.previous(context);
                                    }),
                            splashRadius: 24.0,
                            icon: const Icon(FeatherIcons.chevronLeft),
                            color: Theme.of(context).colorScheme.secondary),

                        // Week selector
                        InkWell(
                          borderRadius: BorderRadius.circular(6.0),
                          onTap: () => setState(() {
                            _controller.current();
                            if (mounted) {
                              _controller.jump(
                                _controller.currentWeek,
                                context: context,
                                loader: _controller.currentWeekId !=
                                    _controller.previousWeekId,
                              );
                            }
                            _tabController
                                .animateTo(_getDayIndex(DateTime.now()));
                          }),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "${DateFormat("${_controller.currentWeek.start.year != DateTime.now().year ? "yyyy. " : ""}MMM d", I18n.of(context).locale.languageCode).format(_controller.currentWeek.start)}${DateFormat("${_controller.currentWeek.start.year != DateTime.now().year ? " - yyyy. MMM " : (_controller.currentWeek.start.month == _controller.currentWeek.end.month ? '-' : ' - MMM ')}d", I18n.of(context).locale.languageCode).format(_controller.currentWeek.end)}  •  ${_controller.currentWeekId + 1}. ${"week".i18n}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ),

                        // Next week
                        IconButton(
                            onPressed: _controller.currentWeekId == 51
                                ? null
                                : () => setState(() {
                                      _controller.next(context);
                                    }),
                            splashRadius: 24.0,
                            icon: const Icon(FeatherIcons.chevronRight),
                            color: Theme.of(context).colorScheme.secondary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            body: PageTransitionSwitcher(
              transitionBuilder: (
                Widget child,
                Animation<double> primaryAnimation,
                Animation<double> secondaryAnimation,
              ) {
                return FadeThroughTransition(
                  animation: primaryAnimation,
                  secondaryAnimation: secondaryAnimation,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  child: child,
                );
              },
              child: _controller.days != null
                  ? Column(
                      key: Key(_controller.currentWeek.toString()),
                      children: [
                        // Week view
                        _tabController.length > 0
                            ? Expanded(
                                child: TabBarView(
                                  physics: const BouncingScrollPhysics(),
                                  controller: _tabController,
                                  // days
                                  children: List.generate(
                                    _controller.days!.length,
                                    (tab) => RefreshIndicator(
                                      onRefresh: () => mounted
                                          ? _controller.jump(
                                              _controller.currentWeek,
                                              context: context,
                                              loader: false)
                                          : Future.value(null),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        physics: const BouncingScrollPhysics(),
                                        itemCount:
                                            _controller.days![tab].length,
                                        itemBuilder: (context, index) {
                                          if (_controller.days == null) {
                                            return Container();
                                          }

                                          // Header
                                          // if (index == 0) {
                                          //   return const Padding(
                                          //     padding: EdgeInsets.only(
                                          //         top: 8.0,
                                          //         left: 24.0,
                                          //         right: 24.0),
                                          //     child: PanelHeader(
                                          //         padding: EdgeInsets.only(
                                          //             top: 12.0)),
                                          //   );
                                          // }

                                          // Footer
                                          // if (index ==
                                          //     _controller.days![tab].length +
                                          //         1) {
                                          //   return const Padding(
                                          //     padding: EdgeInsets.only(
                                          //         bottom: 8.0,
                                          //         left: 24.0,
                                          //         right: 24.0),
                                          //     child: PanelFooter(
                                          //         padding: EdgeInsets.only(
                                          //             top: 12.0)),
                                          //   );
                                          // }

                                          // Body
                                          int len =
                                              _controller.days![tab].length;

                                          final Lesson lesson =
                                              _controller.days![tab][index];
                                          final Lesson? before =
                                              len + index > len
                                                  ? _controller.days![tab]
                                                      [index - 1]
                                                  : null;

                                          final bool swapDescDay = _controller
                                                  .days![tab]
                                                  .map(
                                                      (l) => l.swapDesc ? 1 : 0)
                                                  .reduce((a, b) => a + b) >=
                                              _controller.days![tab].length *
                                                  .5;

                                          return Column(
                                            children: [
                                              if (before != null &&
                                                  (before.end.hour != 0 &&
                                                      lesson.start.hour != 0) &&
                                                  settingsProvider.showBreaks)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      top: index == 0
                                                          ? 0.0
                                                          : 12.0,
                                                      left: 24,
                                                      right: 24),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10.0),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.25),
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16.0),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8.0,
                                                                      vertical:
                                                                          2.5),
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50.0),
                                                                color: AppColors.of(
                                                                        context)
                                                                    .text
                                                                    .withOpacity(
                                                                        0.90),
                                                              ),
                                                              child: Text(
                                                                'break'.i18n,
                                                                style:
                                                                    TextStyle(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .scaffoldBackgroundColor,
                                                                  fontSize:
                                                                      12.5,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  height: 1.1,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 10.0,
                                                            ),
                                                            Text(
                                                              '${DateFormat("hh:mm", I18n.of(context).locale.languageCode).format(before.end)} - ${DateFormat("hh:mm", I18n.of(context).locale.languageCode).format(lesson.start)}',
                                                              // '${before.end.hour}:${before.end.minute} - ${lesson.start.hour}:${lesson.start.minute}',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        if (DateTime.now()
                                                                .isBefore(lesson
                                                                    .start) &&
                                                            DateTime.now()
                                                                .isAfter(
                                                                    before.end))
                                                          Dot(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .secondary
                                                                .withOpacity(
                                                                    .5),
                                                            size: 10.0,
                                                          )
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                    top:
                                                        index == 0 ? 5.0 : 12.0,
                                                    left: 24,
                                                    right: 24,
                                                    bottom: index + 1 == len
                                                        ? 20.0
                                                        : 0),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6.0),
                                                  decoration: BoxDecoration(
                                                    boxShadow: [
                                                      if (Provider.of<
                                                                  SettingsProvider>(
                                                              context,
                                                              listen: false)
                                                          .shadowEffect)
                                                        BoxShadow(
                                                          offset: const Offset(
                                                              0, 21),
                                                          blurRadius: 23.0,
                                                          color:
                                                              Theme.of(context)
                                                                  .shadowColor,
                                                        )
                                                    ],
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .background,
                                                    borderRadius:
                                                        BorderRadius.only(
                                                      topLeft: index == 0
                                                          ? const Radius
                                                              .circular(16.0)
                                                          : const Radius
                                                              .circular(16.0),
                                                      topRight: index == 0
                                                          ? const Radius
                                                              .circular(16.0)
                                                          : const Radius
                                                              .circular(16.0),
                                                      bottomLeft: index + 1 ==
                                                              len
                                                          ? const Radius
                                                              .circular(16.0)
                                                          : const Radius
                                                              .circular(16.0),
                                                      bottomRight: index + 1 ==
                                                              len
                                                          ? const Radius
                                                              .circular(16.0)
                                                          : const Radius
                                                              .circular(16.0),
                                                    ),
                                                  ),
                                                  child: LessonViewable(
                                                    lesson,
                                                    swapDesc: swapDescDay,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );

                                          // return Padding(
                                          //   padding: const EdgeInsets.symmetric(
                                          //       horizontal: 24.0),
                                          //   child: PanelBody(
                                          //     padding:
                                          //         const EdgeInsets.symmetric(
                                          //             horizontal: 10.0),
                                          //     child: LessonViewable(
                                          //       lesson,
                                          //       swapDesc: swapDescDay,
                                          //     ),
                                          //   ),
                                          // );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              )

                            // Empty week
                            : Expanded(
                                child: Center(child: empty),
                              ),

                        // Day selector
                        TabBar(
                          dividerColor: Colors.transparent,
                          controller: _tabController,
                          // Label
                          labelPadding: EdgeInsets.zero,
                          labelColor:
                              AppColors.of(context).text.withOpacity(0.9),
                          unselectedLabelColor: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.25)
                              .withAlpha(100),
                          // Indicator
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorPadding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                          indicator: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(
                                color: AppColors.of(context)
                                    .text
                                    .withOpacity(0.90)),
                            // color: Theme.of(context)
                            //     .colorScheme
                            //     .secondary
                            //     .withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          overlayColor: MaterialStateProperty.all(
                              const Color(0x00000000)),
                          // Tabs
                          padding: const EdgeInsets.symmetric(
                              vertical: 6.0, horizontal: 24.0),
                          tabs: List.generate(_tabController.length, (index) {
                            String label = DateFormat("EEEE",
                                    I18n.of(context).locale.languageCode)
                                .format(_controller.days![index].first.date)
                                .capital();
                            return Tab(
                              height: 56.0,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_sameDate(
                                      _controller.days![index].first.date,
                                      DateTime.now()))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 0.0),
                                      child: Dot(
                                          size: 4.0,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(0.25)
                                              .withAlpha(100)),
                                    ),
                                  Text(
                                    label.substring(0, min(2, label.length)),
                                    style: const TextStyle(
                                      fontSize: 22.0,
                                      fontWeight: FontWeight.w600,
                                      height: 1.1,
                                    ),
                                  ),
                                  SizedBox(
                                    height: _sameDate(
                                            _controller.days![index].first.date,
                                            DateTime.now())
                                        ? 0.0
                                        : 3.0,
                                  ),
                                  Text(
                                    _controller.days![index].first.date.day
                                        .toString(),
                                    style: TextStyle(
                                      height: 1.0,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 17.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withOpacity(0.25)
                                          .withAlpha(100),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    )
                  : const SizedBox(),
            ),
          ),
        ),
      ),
    );
  }
}

// difference.inDays is not reliable
bool _sameDate(DateTime a, DateTime b) =>
    (a.year == b.year && a.month == b.month && a.day == b.day);
