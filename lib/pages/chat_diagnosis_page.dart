import 'package:flutter/material.dart';

class ChatDiagnosisPage extends StatelessWidget{
  const ChatDiagnosisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('Symptom'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // กล่องข้อความใหญ่
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'TEXT',
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            // ช่อง input 1.1

            const SizedBox(height: 10),
            // ช่อง input 2.1

            const SizedBox(height: 10),
            // ช่อง input 3.1

          ],
        ),
      ),
    );
  }
}