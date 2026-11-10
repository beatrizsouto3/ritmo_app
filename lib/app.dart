import 'package:flutter/material.dart';

import 'ui/dashboard/dashboard_view.dart';

class RitmoApp extends StatelessWidget {
  const RitmoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Ritmo',
      debugShowCheckedModeBanner: false,
      home: DashboardView(),
    );
  }
}