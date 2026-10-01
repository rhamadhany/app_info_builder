import 'package:flutter/material.dart';
import 'generated/app_info.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example App Info',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'app_info_builder Demo'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final entries = <MapEntry<String, String>>[
      MapEntry('appName', ExampleAppInfo.appName),
      MapEntry('packageName', ExampleAppInfo.packageName),
      MapEntry('version', ExampleAppInfo.version),
      MapEntry('buildNumber', ExampleAppInfo.buildNumber),
      MapEntry('fullVersion', ExampleAppInfo.fullVersion),
      MapEntry('buildTimestamp', ExampleAppInfo.buildTimestamp),
      MapEntry('extra.buildFlavor', ExampleAppInfo.buildFlavor),
      MapEntry('extra.apiEnv', ExampleAppInfo.apiEnv),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, i) {
          final e = entries[i];
          return ListTile(
            dense: true,
            title: Text(e.key,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: SelectableText(e.value),
          );
        },
      ),
    );
  }
}
