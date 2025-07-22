// This file is now deprecated - we're using direct FlowListScreen in main.dart

import 'package:flutter/material.dart';
import 'screens/flow_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Just show FlowListScreen directly
  final List<Widget> _screens = [const FlowListScreen()];

  @override
  Widget build(BuildContext context) {
    // Simply return FlowListScreen directly
    return _screens[0];
  }

  // Keeping this class for reference, but it's no longer used
}
