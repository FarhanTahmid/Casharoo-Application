import 'package:flutter/material.dart';

/// Bottom bar on narrow screens, NavigationRail on wide.
/// Provide [body], [appBar], [floatingActionButton].
class AdaptiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onDestinationSelected;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 900;
      final destinations = const [
        NavigationDestination(icon: Icon(Icons.book_rounded), label: 'Cashbooks'),
        NavigationDestination(icon: Icon(Icons.help_outline_rounded), label: 'Help'),
        NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Settings'),
      ];

      if (wide) {
        return Scaffold(
          appBar: appBar,
          floatingActionButton: floatingActionButton,
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.book_rounded), label: Text('Cashbooks')),
                  NavigationRailDestination(
                    icon: Icon(Icons.help_outline_rounded), label: Text('Help')),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_rounded), label: Text('Settings')),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        );
      }

      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          destinations: destinations,
          onDestinationSelected: onDestinationSelected,
        ),
      );
    });
  }
}
