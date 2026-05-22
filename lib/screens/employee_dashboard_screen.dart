import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/mock_data_service.dart';
import '../models/subscriber.dart';
import 'login_screen.dart';
import '../theme/app_theme.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  final _searchController = TextEditingController();
  Subscriber? _foundUser;
  bool _hasSearched = false;

  void _searchUser() {
    final service = Provider.of<MockDataService>(context, listen: false);
    final query = _searchController.text.trim();
    
    if (query.isEmpty) return;

    setState(() {
      _hasSearched = true;
      try {
        _foundUser = service.citizens.firstWhere((u) => u.meterNumber == query);
      } catch (e) {
        _foundUser = null;
      }
    });
  }

  void _addReadingDialog(Subscriber user) {
    final readingController = TextEditingController();
    final month = DateTime.now().month;
    final year = DateTime.now().year;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'إضافة قراءة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المشترك: ${user.subscriberName}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('رقم العداد: ${user.meterNumber}', style: GoogleFonts.cairo(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: readingController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'القراءة الحالية بالواط (kWh)',
                prefixIcon: Icon(Icons.speed_rounded),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final readingVal = double.tryParse(readingController.text);
              if (readingVal != null) {
                try {
                  Provider.of<MockDataService>(context, listen: false).addReadingForUser(
                    user.subscriberId,
                    readingVal,
                    month,
                    year,
                  );
                  Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم إضافة القراءة بنجاح. تم إرسال إشعار للمشترك بضرورة السداد خلال ٢٤ ساعة لتجنب قطع التيار.', 
                          style: GoogleFonts.cairo(),
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString(), style: GoogleFonts.cairo()), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('حفظ القراءة'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Provider.of<MockDataService>(context, listen: false).logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<MockDataService>(context).currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('بوابة الموظفين', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
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
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
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
                          'مرحباً، ${currentUser?.subscriberName ?? "الموظف"}',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
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
                            'الرقم الوظيفي: ${currentUser?.meterNumber ?? ""}',
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
                    child: const Icon(Icons.assignment_ind_rounded, color: Colors.white, size: 40),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'تسجيل قراءة جديدة',
              style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'أدخل رقم العداد...',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                            onSubmitted: (_) => _searchUser(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _searchUser,
                          child: const Icon(Icons.search_rounded, size: 28),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_hasSearched) ...[
              if (_foundUser != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_foundUser!.subscriberName, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text('رقم الجوال: ${_foundUser!.phone}', style: GoogleFonts.cairo(color: Theme.of(context).textTheme.bodyMedium?.color)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Divider(color: Color(0xFFE2E8F0)),
                        ),
                        SizedBox(
                          child: ElevatedButton.icon(
                            onPressed: () => _addReadingDialog(_foundUser!),
                            icon: const Icon(Icons.add_chart_rounded),
                            label: const Text('إدخال القراءة الحالية'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'لم يتم العثور على عداد بهذا الرقم',
                            style: GoogleFonts.cairo(color: Colors.red.shade700, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'يرجى التأكد من الرقم وإعادة المحاولة',
                            style: GoogleFonts.cairo(color: Theme.of(context).textTheme.bodyMedium?.color),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]
            ]
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
