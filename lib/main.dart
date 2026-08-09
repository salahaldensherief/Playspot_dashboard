import 'package:flutter/material.dart';
import 'core/di/di.dart' as di;
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.setupInjection();

  runApp(const MyApp());
}
