import 'package:flutter/material.dart';

class DummyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dummy Page'),
      ),
      body: Center(
        child: Text(
          'This is a dummy page for testing navigation.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}