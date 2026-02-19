import 'package:flutter/material.dart';

class ExportImportScreen extends StatelessWidget {
  const ExportImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export / Import')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.data_object),
                  title: const Text('Export JSON'),
                  subtitle:
                      const Text('Full fidelity backup including holidays'),
                  onTap: () => _showSnack(context, 'JSON export placeholder'),
                ),
                ListTile(
                  leading: const Icon(Icons.table_chart_outlined),
                  title: const Text('Export CSV'),
                  onTap: () => _showSnack(context, 'CSV export placeholder'),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Export ICS'),
                  onTap: () => _showSnack(context, 'ICS export placeholder'),
                ),
                ListTile(
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('Import JSON (Replace All)'),
                  subtitle: const Text('Destructive restore mode'),
                  onTap: () => _showSnack(context, 'Import JSON placeholder'),
                ),
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Import CSV'),
                  onTap: () => _showSnack(context, 'Import CSV placeholder'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
