// ignore_for_file: use_build_context_synchronously

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:filcnaplo/api/providers/user_provider.dart';
import 'package:filcnaplo/helpers/subject.dart';
import 'package:filcnaplo/models/settings.dart';
import 'package:filcnaplo/theme/colors/colors.dart';
import 'package:filcnaplo/utils/format.dart';
import 'package:filcnaplo_kreta_api/models/grade.dart';
import 'package:filcnaplo_kreta_api/providers/absence_provider.dart';
import 'package:filcnaplo_kreta_api/providers/grade_provider.dart';
import 'package:filcnaplo_kreta_api/providers/timetable_provider.dart';
import 'package:filcnaplo_mobile_ui/common/panel/panel_button.dart';
import 'package:filcnaplo_mobile_ui/common/splitted_panel/splitted_panel.dart';
import 'package:filcnaplo_mobile_ui/screens/settings/settings_helper.dart';
import 'package:filcnaplo_mobile_ui/screens/settings/submenu/edit_subject.dart';
import 'package:filcnaplo_mobile_ui/screens/settings/submenu/paint_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:provider/provider.dart';
import 'package:filcnaplo_mobile_ui/screens/settings/settings_screen.i18n.dart';
import 'package:refilc_plus/models/premium_scopes.dart';
import 'package:refilc_plus/providers/premium_provider.dart';
import 'package:refilc_plus/ui/mobile/premium/upsell.dart';

class MenuPersonalizeSettings extends StatelessWidget {
  const MenuPersonalizeSettings({
    super.key,
    this.borderRadius = const BorderRadius.vertical(
        top: Radius.circular(4.0), bottom: Radius.circular(4.0)),
  });

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return PanelButton(
      onPressed: () => Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(
            builder: (context) => const PersonalizeSettingsScreen()),
      ),
      title: Text("personalization".i18n),
      leading: Icon(
        Icons.palette_outlined,
        size: 22.0,
        color: AppColors.of(context).text.withOpacity(0.95),
      ),
      trailing: Icon(
        FeatherIcons.chevronRight,
        size: 22.0,
        color: AppColors.of(context).text.withOpacity(0.95),
      ),
      borderRadius: borderRadius,
    );
  }
}

class PersonalizeSettingsScreen extends StatefulWidget {
  const PersonalizeSettingsScreen({super.key});

  @override
  PersonalizeSettingsScreenState createState() =>
      PersonalizeSettingsScreenState();
}

class PersonalizeSettingsScreenState extends State<PersonalizeSettingsScreen>
    with SingleTickerProviderStateMixin {
  late SettingsProvider settingsProvider;
  late UserProvider user;

  late AnimationController _hideContainersController;

  late List<Grade> editedShit;
  late List<Grade> otherShit;

  late List<Widget> tiles;

  @override
  void initState() {
    super.initState();

    editedShit = Provider.of<GradeProvider>(context, listen: false)
        .grades
        .where((e) => e.teacher.isRenamed || e.subject.isRenamed)
        // .map((e) => e.subject)
        .toSet()
        .toList()
      ..sort((a, b) => a.subject.name.compareTo(b.subject.name));

    List<Grade> other = Provider.of<GradeProvider>(context, listen: false)
        .grades
        .where((e) => !e.teacher.isRenamed && !e.subject.isRenamed)
        .toSet()
        .toList()
      ..sort((a, b) => a.subject.name.compareTo(b.subject.name));

    otherShit = [];
    var addedOthers = [];

    for (var e in other) {
      if (addedOthers.contains(e.subject.id)) continue;
      addedOthers.add(e.subject.id);

      otherShit.add(e);
    }

    otherShit = otherShit
      ..sort((a, b) =>
          a.subject.name.compareTo(b.subject.name)); // just cuz why not

    // editedTeachers = Provider.of<GradeProvider>(context, listen: false)
    //     .grades
    //     .where((e) => e.teacher.isRenamed || e.subject.isRenamed)
    //     .map((e) => e.teacher)
    //     .toSet()
    //     .toList();
    // // ..sort((a, b) => a.name.compareTo(b.name));
    // otherTeachers = Provider.of<GradeProvider>(context, listen: false)
    //     .grades
    //     .where((e) => !e.teacher.isRenamed && !e.subject.isRenamed)
    //     .map((e) => e.teacher)
    //     .toSet()
    //     .toList();
    // ..sort((a, b) => a.name.compareTo(b.name));

    _hideContainersController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
  }

  void buildSubjectTiles() {
    List<Widget> subjectTiles = [];

    var added = [];
    var i = 0;

    for (var s in editedShit) {
      if (added.contains(s.subject.id)) continue;

      Widget widget = PanelButton(
        onPressed: () => Navigator.of(context, rootNavigator: true).push(
          CupertinoPageRoute(
            builder: (context) => EditSubjectScreen(
              subject: s.subject,
              teacher: s.teacher, // not sure why, but it works tho
            ),
          ),
        ),
        title: Text(
          (s.subject.isRenamed && settingsProvider.renamedSubjectsEnabled
                  ? s.subject.renamedTo
                  : s.subject.name.capital()) ??
              '',
          style: TextStyle(
            color: AppColors.of(context).text.withOpacity(.95),
            fontStyle: settingsProvider.renamedSubjectsItalics
                ? FontStyle.italic
                : FontStyle.normal,
          ),
        ),
        leading: Icon(
          SubjectIcon.resolveVariant(context: context, subject: s.subject),
          size: 22.0,
          color: AppColors.of(context).text.withOpacity(.95),
        ),
        trailing: Icon(
          FeatherIcons.chevronRight,
          size: 22.0,
          color: AppColors.of(context).text.withOpacity(0.95),
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(i == 0 ? 12.0 : 4.0),
          bottom: Radius.circular(i + 1 == editedShit.length ? 12.0 : 4.0),
        ),
      );

      i += 1;
      subjectTiles.add(widget);
      added.add(s.subject.id);
    }

    tiles = subjectTiles;
  }

  @override
  Widget build(BuildContext context) {
    settingsProvider = Provider.of<SettingsProvider>(context);
    user = Provider.of<UserProvider>(context);

    String themeModeText = {
          ThemeMode.light: "light".i18n,
          ThemeMode.dark: "dark".i18n,
          ThemeMode.system: "system".i18n
        }[settingsProvider.theme] ??
        "?";

    buildSubjectTiles();

    return AnimatedBuilder(
      animation: _hideContainersController,
      builder: (context, child) => Opacity(
        opacity: 1 - _hideContainersController.value,
        child: Scaffold(
          appBar: AppBar(
            surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
            leading: BackButton(color: AppColors.of(context).text),
            title: Text(
              "personalization".i18n,
              style: TextStyle(color: AppColors.of(context).text),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              child: Column(
                children: [
                  // app theme
                  SplittedPanel(
                    padding: const EdgeInsets.only(top: 8.0),
                    cardPadding: const EdgeInsets.all(4.0),
                    isSeparated: true,
                    children: [
                      PanelButton(
                        onPressed: () {
                          SettingsHelper.theme(context);
                          setState(() {});
                        },
                        title: Text("theme".i18n),
                        leading: Icon(
                          FeatherIcons.sun,
                          size: 22.0,
                          color: AppColors.of(context).text.withOpacity(0.95),
                        ),
                        trailing: Text(
                          themeModeText,
                          style: const TextStyle(fontSize: 14.0),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12.0),
                          bottom: Radius.circular(12.0),
                        ),
                      ),
                    ],
                  ),
                  // color magic shit
                  SplittedPanel(
                    padding: const EdgeInsets.only(top: 9.0),
                    cardPadding: const EdgeInsets.all(4.0),
                    isSeparated: false,
                    children: [
                      PanelButton(
                        padding: const EdgeInsets.only(left: 14.0, right: 14.0),
                        onPressed: () async {
                          await _hideContainersController.forward();
                          SettingsHelper.accentColor(context);
                          setState(() {});
                          _hideContainersController.reset();
                        },
                        title: Text(
                          "color".i18n,
                          style: TextStyle(
                            color: AppColors.of(context).text.withOpacity(.95),
                          ),
                        ),
                        leading: Icon(
                          FeatherIcons.droplet,
                          size: 22.0,
                          color: AppColors.of(context).text.withOpacity(.95),
                        ),
                        trailing: Container(
                          width: 12.0,
                          height: 12.0,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12.0),
                          bottom: Radius.circular(4.0),
                        ),
                      ),
                      const MenuPaintList(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4.0),
                          bottom: Radius.circular(12.0),
                        ),
                      ),
                    ],
                  ),
                  // shadow toggle
                  SplittedPanel(
                    padding: const EdgeInsets.only(top: 9.0),
                    cardPadding: const EdgeInsets.all(4.0),
                    isSeparated: true,
                    children: [
                      PanelButton(
                        padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                        onPressed: () async {
                          settingsProvider.update(
                              shadowEffect: !settingsProvider.shadowEffect);

                          setState(() {});
                        },
                        title: Text(
                          "shadow_effect".i18n,
                          style: TextStyle(
                            color: AppColors.of(context).text.withOpacity(
                                settingsProvider.shadowEffect ? .95 : .25),
                          ),
                        ),
                        leading: Icon(
                          FeatherIcons.moon,
                          size: 22.0,
                          color: AppColors.of(context).text.withOpacity(
                              settingsProvider.shadowEffect ? .95 : .25),
                        ),
                        trailing: Switch(
                          onChanged: (v) async {
                            settingsProvider.update(shadowEffect: v);

                            setState(() {});
                          },
                          value: settingsProvider.shadowEffect,
                          activeColor: Theme.of(context).colorScheme.secondary,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12.0),
                          bottom: Radius.circular(12.0),
                        ),
                      ),
                    ],
                  ),
                  // change subject icons
                  SplittedPanel(
                    padding: const EdgeInsets.only(top: 9.0),
                    cardPadding: const EdgeInsets.all(4.0),
                    isSeparated: true,
                    children: [
                      PanelButton(
                        onPressed: () {
                          SettingsHelper.iconPack(context);
                        },
                        title: Text(
                          "icon_pack".i18n,
                          style: TextStyle(
                            color: AppColors.of(context).text.withOpacity(.95),
                          ),
                        ),
                        leading: Icon(
                          FeatherIcons.grid,
                          size: 22.0,
                          color: AppColors.of(context).text.withOpacity(.95),
                        ),
                        trailing: Text(
                          settingsProvider.iconPack.name.capital(),
                          style: const TextStyle(fontSize: 14.0),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12.0),
                          bottom: Radius.circular(12.0),
                        ),
                      ),
                    ],
                  ),
                  // grade colors
                  SplittedPanel(
                    padding: const EdgeInsets.only(top: 9.0),
                    cardPadding: const EdgeInsets.all(4.0),
                    isSeparated: true,
                    children: [
                      PanelButton(
                        onPressed: () {
                          SettingsHelper.gradeColors(context);
                          setState(() {});
                        },
                        title: Text(
                          "grade_colors".i18n,
                          style: TextStyle(
                            color: AppColors.of(context).text.withOpacity(.95),
                          ),
                        ),
                        leading: Icon(
                          FeatherIcons.star,
                          size: 22.0,
                          color: AppColors.of(context).text.withOpacity(.95),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            5,
                            (i) => Container(
                              margin: const EdgeInsets.only(left: 2.0),
                              width: 12.0,
                              height: 12.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: settingsProvider.gradeColors[i],
                              ),
                            ),
                          ),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12.0),
                          bottom: Radius.circular(12.0),
                        ),
                      ),
                    ],
                  ),
                  // rename things
                  SplittedPanel(
                    padding: const EdgeInsets.only(top: 9.0),
                    cardPadding: const EdgeInsets.all(4.0),
                    isSeparated: false,
                    children: [
                      // rename subjects
                      PanelButton(
                        padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                        onPressed: () async {
                          settingsProvider.update(
                              renamedSubjectsEnabled:
                                  !settingsProvider.renamedSubjectsEnabled);
                          await Provider.of<GradeProvider>(context,
                                  listen: false)
                              .convertBySettings();
                          await Provider.of<TimetableProvider>(context,
                                  listen: false)
                              .convertBySettings();
                          await Provider.of<AbsenceProvider>(context,
                                  listen: false)
                              .convertBySettings();

                          setState(() {});
                        },
                        title: Text(
                          "rename_subjects".i18n,
                          style: TextStyle(
                            color: AppColors.of(context).text.withOpacity(
                                settingsProvider.renamedSubjectsEnabled
                                    ? .95
                                    : .25),
                          ),
                        ),
                        leading: Icon(
                          Icons.school_outlined,
                          size: 22.0,
                          color: AppColors.of(context).text.withOpacity(
                              settingsProvider.renamedSubjectsEnabled
                                  ? .95
                                  : .25),
                        ),
                        trailing: Switch(
                          onChanged: (v) async {
                            settingsProvider.update(renamedSubjectsEnabled: v);
                            await Provider.of<GradeProvider>(context,
                                    listen: false)
                                .convertBySettings();
                            await Provider.of<TimetableProvider>(context,
                                    listen: false)
                                .convertBySettings();
                            await Provider.of<AbsenceProvider>(context,
                                    listen: false)
                                .convertBySettings();

                            setState(() {});
                          },
                          value: settingsProvider.renamedSubjectsEnabled,
                          activeColor: Theme.of(context).colorScheme.secondary,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12.0),
                          bottom: Radius.circular(4.0),
                        ),
                      ),
                      // rename teachers
                      PanelButton(
                        padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                        onPressed: () async {
                          settingsProvider.update(
                              renamedTeachersEnabled:
                                  !settingsProvider.renamedTeachersEnabled);
                          await Provider.of<GradeProvider>(context,
                                  listen: false)
                              .convertBySettings();
                          await Provider.of<TimetableProvider>(context,
                                  listen: false)
                              .convertBySettings();
                          await Provider.of<AbsenceProvider>(context,
                                  listen: false)
                              .convertBySettings();

                          setState(() {});
                        },
                        title: Text(
                          "rename_teachers".i18n,
                          style: TextStyle(
                            color: AppColors.of(context).text.withOpacity(
                                settingsProvider.renamedTeachersEnabled
                                    ? .95
                                    : .25),
                          ),
                        ),
                        leading: Icon(
                          FeatherIcons.user,
                          size: 22.0,
                          color: AppColors.of(context).text.withOpacity(
                              settingsProvider.renamedTeachersEnabled
                                  ? .95
                                  : .25),
                        ),
                        trailing: Switch(
                          onChanged: (v) async {
                            settingsProvider.update(renamedTeachersEnabled: v);
                            await Provider.of<GradeProvider>(context,
                                    listen: false)
                                .convertBySettings();
                            await Provider.of<TimetableProvider>(context,
                                    listen: false)
                                .convertBySettings();
                            await Provider.of<AbsenceProvider>(context,
                                    listen: false)
                                .convertBySettings();

                            setState(() {});
                          },
                          value: settingsProvider.renamedTeachersEnabled,
                          activeColor: Theme.of(context).colorScheme.secondary,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4.0),
                          bottom: Radius.circular(12.0),
                        ),
                      ),
                    ],
                  ),
                  // live activity color
                  SplittedPanel(
                    padding: const EdgeInsets.only(top: 9.0),
                    cardPadding: const EdgeInsets.all(4.0),
                    isSeparated: true,
                    children: [
                      PanelButton(
                        onPressed: () {
                          if (!Provider.of<PremiumProvider>(context,
                                  listen: false)
                              .hasScope(PremiumScopes.liveActivityColor)) {
                            PremiumLockedFeatureUpsell.show(
                              context: context,
                              feature: PremiumFeature.liveActivity,
                            );
                            return;
                          }

                          SettingsHelper.liveActivityColor(context);
                          setState(() {});
                        },
                        title: Text(
                          "live_activity_color".i18n,
                          style: TextStyle(
                            color: AppColors.of(context).text.withOpacity(.95),
                          ),
                        ),
                        leading: Icon(
                          FeatherIcons.activity,
                          size: 22.0,
                          color: AppColors.of(context).text.withOpacity(.95),
                        ),
                        trailing: Container(
                          margin: const EdgeInsets.only(left: 2.0),
                          width: 12.0,
                          height: 12.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: settingsProvider.liveActivityColor,
                          ),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12.0),
                          bottom: Radius.circular(12.0),
                        ),
                      ),
                    ],
                  ),

                  // SplittedPanel(
                  //   padding: const EdgeInsets.only(top: 9.0),
                  //   cardPadding: const EdgeInsets.all(4.0),
                  //   isSeparated: true,
                  //   children: [],
                  // ),
                  const SizedBox(
                    height: 18.0,
                  ),
                  SplittedPanel(
                    title: Text('subjects'.i18n),
                    padding: EdgeInsets.zero,
                    cardPadding: const EdgeInsets.all(4.0),
                    children: tiles,
                  ),
                  const SizedBox(
                    height: 9.0,
                  ),
                  SplittedPanel(
                    padding: EdgeInsets.zero,
                    cardPadding: const EdgeInsets.all(3.0),
                    hasBorder: true,
                    isTransparent: true,
                    children: [
                      DropdownButton2(
                        items: otherShit
                            .map((item) => DropdownMenuItem<String>(
                                  value: item.subject.id,
                                  child: Text(
                                    item.subject.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.of(context).text,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (String? v) async {
                          Navigator.of(context, rootNavigator: true).push(
                            CupertinoPageRoute(
                              builder: (context) => EditSubjectScreen(
                                subject: otherShit
                                    .firstWhere((e) => e.subject.id == v)
                                    .subject,
                                teacher: otherShit
                                    .firstWhere((e) => e.subject.id == v)
                                    .teacher,
                              ),
                            ),
                          );
                          // _subjectName.text = "";
                        },
                        iconSize: 14,
                        iconEnabledColor: AppColors.of(context).text,
                        iconDisabledColor: AppColors.of(context).text,
                        underline: const SizedBox(),
                        itemHeight: 40,
                        itemPadding: const EdgeInsets.only(left: 14, right: 14),
                        buttonWidth: 50,
                        dropdownWidth: 300,
                        dropdownPadding: null,
                        buttonDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        dropdownDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        dropdownElevation: 8,
                        scrollbarRadius: const Radius.circular(40),
                        scrollbarThickness: 6,
                        scrollbarAlwaysShow: true,
                        offset: const Offset(-10, -10),
                        buttonSplashColor: Colors.transparent,
                        customButton: PanelButton(
                          title: Text(
                            "select_subject".i18n,
                            style: TextStyle(
                              color:
                                  AppColors.of(context).text.withOpacity(.95),
                            ),
                          ),
                          leading: Icon(
                            FeatherIcons.plus,
                            size: 22.0,
                            color: AppColors.of(context).text.withOpacity(.95),
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12.0),
                            bottom: Radius.circular(12.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
