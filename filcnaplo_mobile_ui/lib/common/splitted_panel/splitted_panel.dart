import 'package:filcnaplo/models/settings.dart';
import 'package:filcnaplo/theme/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplittedPanel extends StatelessWidget {
  const SplittedPanel({
    super.key,
    this.children,
    this.title,
    this.padding,
    this.cardPadding,
    this.hasShadow = true,
    this.isSeparated = false,
    this.spacing = 6.0,
    this.isTransparent = false,
    this.hasBorder = false,
  });

  final List<Widget>? children;
  final Widget? title;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? cardPadding;
  final bool hasShadow;
  final bool isSeparated;
  final double spacing;
  final bool isTransparent;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    double sp = spacing;

    if (isSeparated && spacing == 6.0) {
      sp = 9.0;
    }

    List<Widget> childrenInMyBasement = [];

    if (children != null) {
      var i = 0;

      for (var widget in children!) {
        var w = Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isTransparent
                ? Colors.transparent
                : Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(i == 0 ? 16.0 : 8.0),
              bottom: Radius.circular(children!.length == i + 1 ? 16.0 : 8.0),
            ),
            border: hasBorder
                ? Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(.25),
                    width: 1.0)
                : null,
          ),
          margin: EdgeInsets.only(top: i == 0 ? 0.0 : sp),
          padding: cardPadding ?? EdgeInsets.zero,
          child: widget,
        );

        childrenInMyBasement.add(w);

        i++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // title
        if (title != null)
          SplittedPanelTitle(
            title: title!,
            leftPadding: (padding?.horizontal ?? 48.0) / 2,
          ),

        // body
        if (children != null)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.transparent,
              boxShadow: [
                if (hasShadow &&
                    Provider.of<SettingsProvider>(context, listen: false)
                        .shadowEffect)
                  BoxShadow(
                    offset: const Offset(0, 21),
                    blurRadius: 23.0,
                    color: Theme.of(context).shadowColor,
                  )
              ],
            ),
            padding: padding ??
                const EdgeInsets.only(bottom: 20.0, left: 24.0, right: 24.0),
            child: Column(children: childrenInMyBasement),
          ),
      ],
    );
  }
}

class SplittedPanelTitle extends StatelessWidget {
  const SplittedPanelTitle(
      {super.key, required this.title, this.leftPadding = 24.0});

  final Widget title;
  final double leftPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 14.0 + leftPadding, bottom: 8.0),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.of(context).text.withOpacity(0.65)),
        child: title,
      ),
    );
  }
}
