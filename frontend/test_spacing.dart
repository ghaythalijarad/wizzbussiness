import 'package:flutter/material.dart';
import 'core/design_system/spacing_system.dart';

void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: SpacingSystem.allMd,
          child: Column(
            children: [
              Text('Testing SpacingSystem'),
              SpacingWidgets.verticalSm,
              Text('Success!'),
            ],
          ),
        ),
      ),
    );
  }
}
