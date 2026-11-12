import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppDependencies(child: RitmoApp()));
}
