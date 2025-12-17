import 'package:flutter/material.dart';
import 'package:keyboard_done_button_ios/keyboard_done_button_ios.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iOS Done Button Demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('iOS Done Button Demo')),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ============================================================ //
              // Without Done Button (Text Keyboard)
              // ============================================================ //
              const _SectionHeader(
                'Without Done Button',
                'Text keyboard has Return key',
              ),
              // Use KeyboardToolbarField with showToolbar: false
              // to explicitly hide toolbar when switching from number fields
              KeyboardToolbarField(
                showToolbar: false,
                child: const TextField(
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
              ),
              const SizedBox(height: 12),
              KeyboardToolbarField(
                showToolbar: false,
                child: const TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),

              const SizedBox(height: 32),

              // ============================================================ //
              // With Done Button (Number Keyboard)
              // ============================================================ //
              const _SectionHeader(
                'With Done Button',
                'Number keyboard has no dismiss key',
              ),
              // Use KeyboardToolbarField widget (recommended)
              KeyboardToolbarField(
                child: const TextField(
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(height: 12),
              KeyboardToolbarField(
                child: const TextField(
                  decoration: InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 12),
              KeyboardToolbarField(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
