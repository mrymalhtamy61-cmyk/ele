import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../models/subscriber.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  void _logout(BuildContext context) {
    Provider.of<FirestoreService>(context, listen: false).logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const _OverviewTab(),
      const _AddCitizenTab(),
      const _AddEmployeeTab(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('لوحة التحكم والإدارة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      extendBody: true,
      body: pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        icons: const [
          Icons.dashboard_outlined,
          Icons.person_add_outlined,
          Icons.badge_outlined,
          Icons.settings_outlined,
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final mockService = Provider.of<FirestoreService>(context);

    final citizens = mockService.citizens;
    final readings = mockService.readings;

    double totalConsumption = 0;
    double totalRevenue = 0;
    for (var r in readings) {
      totalConsumption += r.consumption;
      totalRevenue += r.amount;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'المشتركون',
                  value: '${citizens.length}',
                  icon: Icons.people_alt_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'القراءات',
                  value: '${readings.length}',
                  icon: Icons.assignment_rounded,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'إجمالي الاستهلاك',
                  value: '$totalConsumption kWh',
                  icon: Icons.electric_bolt_rounded,
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'العوائد',
                  value: '${totalRevenue.toStringAsFixed(2)} ر.ي',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // === Admin Section ===
          _buildUserSection(
            context,
            title: 'الإدارة',
            icon: Icons.admin_panel_settings_rounded,
            color: const Color(0xFFEF4444),
            users: mockService.admins,
          ),
          const SizedBox(height: 24),
          // === Employees Section ===
          _buildUserSection(
            context,
            title: 'الموظفون',
            icon: Icons.badge_rounded,
            color: Theme.of(context).colorScheme.secondary,
            users: mockService.employees,
          ),
          const SizedBox(height: 24),
          // === Citizens Section ===
          _buildCitizensSection(
            context,
            title: 'المشتركون',
            icon: Icons.person_rounded,
            color: const Color(0xFF10B981),
            users: citizens,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.cairo(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection(BuildContext context, {required String title, required IconData icon, required Color color, required List<Subscriber> users}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              '$title (${users.length})',
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (users.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(child: Text('لا يوجد', style: GoogleFonts.cairo(color: Theme.of(context).textTheme.bodyMedium?.color))),
            ),
          )
        else
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(user.subscriberName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  subtitle: Text('الرقم: ${user.meterNumber} | الجوال: ${user.phone}', style: GoogleFonts.cairo(fontSize: 12)),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCitizensSection(BuildContext context, {required String title, required IconData icon, required Color color, required List<Subscriber> users}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              '$title (${users.length})',
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (users.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(child: Text('لا يوجد', style: GoogleFonts.cairo(color: Theme.of(context).textTheme.bodyMedium?.color))),
            ),
          )
        else
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(user.subscriberName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  subtitle: Text('الرقم: ${user.meterNumber} | الجوال: ${user.phone}', style: GoogleFonts.cairo(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => _UserReadingsDialog(user: user),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _AddCitizenTab extends StatefulWidget {
  const _AddCitizenTab();

  @override
  State<_AddCitizenTab> createState() => _AddCitizenTabState();
}

class _AddCitizenTabState extends State<_AddCitizenTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _meterController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Provider.of<FirestoreService>(context, listen: false).addCitizen(
        name: _nameController.text.trim(),
        meterNumber: _meterController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        email: _emailController.text.trim(),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة المشترك وإنشاء رقم عداد له بنجاح', style: GoogleFonts.cairo()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      _formKey.currentState!.reset();
      _nameController.clear();
      _meterController.clear();
      _phoneController.clear();
      _addressController.clear();
      _emailController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'بيانات المشترك الجديد',
                  style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _meterController,
                  decoration: const InputDecoration(labelText: 'رقم العداد (يُترك فارغاً للتوليد التلقائي)', prefixIcon: Icon(Icons.electric_meter_outlined)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الجوال', prefixIcon: Icon(Icons.phone_outlined)),
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'العنوان', prefixIcon: Icon(Icons.location_on_outlined)),
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني (اختياري)', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('إضافة المشترك وإصدار عداد'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddEmployeeTab extends StatefulWidget {
  const _AddEmployeeTab();

  @override
  State<_AddEmployeeTab> createState() => _AddEmployeeTabState();
}

class _AddEmployeeTabState extends State<_AddEmployeeTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _empIdController = TextEditingController();
  final _phoneController = TextEditingController();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Provider.of<FirestoreService>(context, listen: false).addEmployee(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        empId: _empIdController.text.trim(),
        address: '',
        email: '',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل الموظف وإصدار رقم وظيفي له بنجاح', style: GoogleFonts.cairo()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      _formKey.currentState!.reset();
      _nameController.clear();
      _empIdController.clear();
      _phoneController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'بيانات موظف القراءات',
                  style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _empIdController,
                  decoration: const InputDecoration(labelText: 'الرقم الوظيفي (يُترك فارغاً للتوليد التلقائي)', prefixIcon: Icon(Icons.pin_outlined)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم الموظف', prefixIcon: Icon(Icons.badge_outlined)),
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الجوال', prefixIcon: Icon(Icons.phone_outlined)),
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('إضافة الموظف'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserReadingsDialog extends StatelessWidget {
  final Subscriber user;
  const _UserReadingsDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirestoreService>(context);
    final userReadings = service.readings.where((r) => r.subscriberId == user.subscriberId).toList();
    
    userReadings.sort((a, b) {
      if (a.year == b.year) {
        return b.month.compareTo(a.month);
      }
      return b.year.compareTo(a.year);
    });

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('فواتير ${user.subscriberName}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (userReadings.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('لا توجد فواتير لهذا المشترك', style: GoogleFonts.cairo()),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: userReadings.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final reading = userReadings[index];
                    final isPaid = reading.paymentStatus == 'مدفوعة';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('شهر ${reading.month} / ${reading.year}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      subtitle: Text('الاستهلاك: ${reading.consumption} kWh\nالمبلغ: ${reading.amount} ر.ي', style: GoogleFonts.cairo(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            reading.paymentStatus,
                            style: GoogleFonts.cairo(
                              color: isPaid ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Switch(
                            value: isPaid,
                            activeThumbColor: Colors.green,
                            onChanged: (val) {
                              final newStatus = val ? 'مدفوعة' : 'غير مدفوعة';
                              service.updatePaymentStatus(reading.readingId, newStatus);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إغلاق', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
