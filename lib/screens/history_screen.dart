import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mock_data_service.dart';
import '../models/reading.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final readings = Provider.of<MockDataService>(context).readings;
    
    // Sort descending by year then month
    final sortedReadings = List<Reading>.from(readings)
      ..sort((a, b) {
        if (a.year == b.year) {
          return b.month.compareTo(a.month);
        }
        return b.year.compareTo(a.year);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل القراءات والفواتير'),
      ),
      body: sortedReadings.isEmpty
          ? const Center(child: Text('لا توجد قراءات مسجلة'))
          : ListView.builder(
              itemCount: sortedReadings.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final reading = sortedReadings[index];
                final isPaid = reading.paymentStatus == 'مدفوعة';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: ExpansionTile(
                    title: Text(
                      'شهر ${reading.month} - ${reading.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('الاستهلاك: ${reading.consumption} kWh'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${reading.amount.toStringAsFixed(2)} ريال',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          reading.paymentStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: isPaid ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('القراءة السابقة:'),
                                Text('${reading.previousReading}'),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('القراءة الحالية:'),
                                Text('${reading.currentReading}'),
                              ],
                            ),
                            const Divider(),
                            if (!isPaid)
                              ElevatedButton(
                                onPressed: () {
                                  // Mark as paid action
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('سيتم تفعيل الدفع قريباً')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('تسديد الفاتورة'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
