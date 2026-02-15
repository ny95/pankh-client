import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InAppWebView Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: InAppWebViewExample(),
    );
  }
}

class InAppWebViewExample extends StatefulWidget {
  const InAppWebViewExample({super.key});

  @override
  InAppWebViewExampleState createState() => InAppWebViewExampleState();
}

class InAppWebViewExampleState extends State<InAppWebViewExample> {
  final String htmlContent = """
  """;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: InAppWebView(
              initialData: InAppWebViewInitialData(data: htmlContent),
              onWebViewCreated: (controller) {},
            ),
          ),
        ],
      ),
    );
  }
}
