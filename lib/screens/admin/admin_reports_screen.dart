import 'package:flutter/material.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = {
      "عدد المستخدمين": 250,
      "عدد الأطباء": 50,
      "عدد المواعيد": 430,
      "المواعيد المقبولة": 320,
    };

    return Scaffold(
      appBar: AppBar(title: const Text("📊 التقارير والإحصائيات")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: stats.entries.map((e) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(e.value.toString(), style: const TextStyle(fontSize: 16)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
