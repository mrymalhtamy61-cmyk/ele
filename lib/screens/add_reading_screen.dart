import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';

class AddReadingScreen extends StatefulWidget {
  const AddReadingScreen({super.key});

  @override
  State<AddReadingScreen> createState() => _AddReadingScreenState();
}

class _AddReadingScreenState extends State<AddReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _readingController = TextEditingController();
  
  // Default to current month
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  void _submitReading() {
    if (_formKey.currentState!.validate()) {
      try {
        final mockService = Provider.of<FirestoreService>(context, listen: false);
        double currentReading = double.parse(_readingController.text);
        
        mockService.addReading(currentReading, _selectedMonth, _selectedYear);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة القراءة بنجاح!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final latestReading = Provider.of<FirestoreService>(context, listen: false).latestReading;
    final previousReading = latestReading?.currentReading ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدخال قراءة جديدة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'القراءة السابقة',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$previousReading',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedMonth,
                      decoration: const InputDecoration(labelText: 'الشهر'),
                      items: List.generate(12, (index) {
                        return DropdownMenuItem(
                          value: index + 1,
                          child: Text('شهر ${index + 1}'),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonth = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedYear,
                      decoration: const InputDecoration(labelText: 'السنة'),
                      items: List.generate(5, (index) {
                        int year = DateTime.now().year - 2 + index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text('$year'),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _readingController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'القراءة الحالية بالوحدات (kWh)',
                  prefixIcon: Icon(Icons.electric_meter),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال القراءة';
                  }
                  double? reading = double.tryParse(value);
                  if (reading == null) {
                    return 'يرجى إدخال رقم صحيح';
                  }
                  if (reading <= previousReading) {
                    return 'يجب أن تكون القراءة الحالية أكبر من السابقة ($previousReading)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitReading,
                child: const Text('حفظ القراءة وحساب الاستهلاك', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _readingController.dispose();
    super.dispose();
  }
}
