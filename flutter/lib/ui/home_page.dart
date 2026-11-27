import 'package:flutter/material.dart';

import '../state/mending_scope.dart';
import 'body_page.dart';
import 'review_page.dart';
import 'working_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var index = 0;
  var askedReview = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || askedReview) return;
      askedReview = true;
      final pending = MendingScope.of(context).pendingReview();
      if (pending == null) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ReviewPage(pending: pending)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mending')),
      body: IndexedStack(
        index: index,
        children: const [WorkingPage(), BodyPage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.star_border_rounded),
            selectedIcon: Icon(Icons.star_rounded),
            label: 'Working',
          ),
          NavigationDestination(
            icon: Icon(Icons.accessibility_new_outlined),
            selectedIcon: Icon(Icons.accessibility_new_rounded),
            label: 'Body',
          ),
        ],
      ),
    );
  }
}
