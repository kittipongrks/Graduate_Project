import 'package:flutter/material.dart';


Widget _buildCardMessage(Map<String, dynamic> data) {
  final conditions = (data['conditions'] as List?) ?? [];
  final triage = data['triage'];

  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data["title"] ?? "",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.black54),
            ],
          ),
          const SizedBox(height: 16),

          // Conditions list
          if (conditions.isNotEmpty) ...[
            const Text(
              "ภาวะที่เป็นไปได้:",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...conditions.map((c) {
              final prob = (c["probability"] as double?) ?? 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        c["name"] ?? "-",
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    Text(
                      "${(prob * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 16),

          // Triage info
          if (triage != null) ...[
            const Text(
              "คำแนะนำเบื้องต้น:",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              triage["recommendation"] ?? "-",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("ระดับความรุนแรง: "),
                Text(
                  triage["level"] ?? "-",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}