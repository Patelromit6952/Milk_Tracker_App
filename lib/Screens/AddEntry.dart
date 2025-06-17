import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController(
    text: "60",
  );

  DateTime selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.lightBlue.shade400, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Default text color
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _saveEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final quantity = double.tryParse(quantityController.text.trim()) ?? 0.0;
    final price = double.tryParse(priceController.text.trim()) ?? 0.0;

    final year = selectedDate.year.toString();
    final month = selectedDate.month.toString().padLeft(2, '0');
    final day = selectedDate.day.toString().padLeft(2, '0');

    // Use a fixed ID ("entry") to overwrite for the same day
    final entryRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('milk_data')
        .doc(year)
        .collection('months')
        .doc(month)
        .collection('days')
        .doc(day);

    await entryRef.set({
      'quantity': quantity,
      'price': price,
      'date': selectedDate,
    }, SetOptions(merge: true));

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final themeBlue = Colors.lightBlue[100];
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light neutral background
      appBar: AppBar(
        title: const Text(
          "Add Milk Entry",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.lightBlue[400],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Entry Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.lightBlue[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Date Field
                      GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Date',
                              prefixIcon: const Icon(Icons.calendar_today),
                              filled: true,
                              fillColor: Colors.white,
                              labelStyle: const TextStyle(
                                color: Colors.blueGrey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            controller: TextEditingController(
                              text: DateFormat(
                                'dd MMM yyyy',
                              ).format(selectedDate),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quantity
                      TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Quantity (Liters)",
                          prefixIcon: const Icon(Icons.water_drop_outlined),
                          filled: true,
                          fillColor: Colors.white,
                          labelStyle: const TextStyle(color: Colors.blueGrey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter quantity'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Price
                      TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Price (₹)",
                          prefixIcon: const Icon(Icons.currency_rupee),
                          filled: true,
                          fillColor: Colors.white,
                          labelStyle: const TextStyle(color: Colors.blueGrey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter price'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text(
                            "Save Entry",
                            style: TextStyle(fontSize: 16),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _saveEntry();
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Entry Saved'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                    ],
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
