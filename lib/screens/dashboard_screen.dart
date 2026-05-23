import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';
import '../models/reading.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  void _logout() {
    Provider.of<FirestoreService>(context, listen: false).logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _showNotificationsSheet(BuildContext context, FirestoreService service) {
    service.markAllNotificationsRead();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer<FirestoreService>(
          builder: (ctx2, svc, _) {
            final notifications = svc.notifications;
            return Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الإشعارات', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (notifications.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            svc.clearNotifications();
                            Navigator.pop(ctx2);
                          },
                          child: Text('مسح الكل', style: GoogleFonts.cairo(color: Colors.red)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (notifications.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('لا توجد إشعارات', style: GoogleFonts.cairo(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (ctx3, index) {
                          final notif = notifications[index];
                          final isSadad = notif.title.contains('سداد');
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: isSadad
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              child: Icon(
                                isSadad ? Icons.check_circle : Icons.receipt_long,
                                color: isSadad ? Colors.green : Colors.orange,
                              ),
                            ),
                            title: Text(notif.title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(notif.body, style: GoogleFonts.cairo(fontSize: 12)),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mockService = Provider.of<FirestoreService>(context);
    final currentUser = mockService.currentUser;
    final latestReading = mockService.latestReading;
    final readings = mockService.readings;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('لوحة المعلومات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
          Consumer<FirestoreService>(
            builder: (context, service, _) {
              final unreadCount = service.unreadNotificationsCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => _showNotificationsSheet(context, service),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Welcome Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مرحباً، ${currentUser?.subscriberName ?? "المشترك"}',
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'رقم العداد: ${currentUser?.meterNumber ?? ""}',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 40),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Unpaid Warning Banner
            if (latestReading != null && latestReading.paymentStatus == 'غير مدفوعة') ...[
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'تحذير: لديك فاتورة غير مسددة. يرجى السداد خلال ٢٤ ساعة لتجنب قطع التيار.',
                        style: GoogleFonts.cairo(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Latest Reading Info Card
            if (latestReading != null) ...[
              Text(
                'آخر فاتورة',
                style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoColumn('القراءة السابقة', '${latestReading.previousReading}'),
                          _buildInfoColumn('القراءة الحالية', '${latestReading.currentReading}'),
                          _buildInfoColumn('الاستهلاك', '${latestReading.consumption} kWh', isHighlighted: true),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Divider(color: Color(0xFFE2E8F0)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المبلغ المستحق',
                            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color),
                          ),
                          Text(
                            '${latestReading.amount.toStringAsFixed(2)} ر.ي',
                            style: GoogleFonts.cairo(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('بوابة الدفع غير متوفرة في هذه النسخة', style: GoogleFonts.cairo()),
                                behavior: SnackBarBehavior.floating,
                              )
                            );
                          },
                          child: const Text('دفع الفاتورة الآن'),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد فواتير أو قراءات مسجلة بعد.',
                          style: GoogleFonts.cairo(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Chart
            if (readings.length > 1) ...[
              Text(
                'تحليل الاستهلاك',
                style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    height: 220,
                    child: _buildChart(readings),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value, {bool isHighlighted = false}) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: isHighlighted ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<Reading> readings) {
    final sortedReadings = List<Reading>.from(readings)
      ..sort((a, b) => a.month.compareTo(b.month));

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < sortedReadings.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: sortedReadings[i].month,
          barRods: [
            BarChartRodData(
              toY: sortedReadings[i].consumption,
              color: Theme.of(context).colorScheme.secondary,
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _getMaxConsumption(sortedReadings) * 1.2,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxConsumption(sortedReadings) * 1.2,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text('ش ${value.toInt()}', style: GoogleFonts.cairo(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  double _getMaxConsumption(List<Reading> readings) {
    if (readings.isEmpty) return 0;
    double max = readings.first.consumption;
    for (var r in readings) {
      if (r.consumption > max) max = r.consumption;
    }
    return max;
  }
}
