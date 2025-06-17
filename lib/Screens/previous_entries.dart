import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PreviousEntriesScreen extends StatefulWidget {
  final String? userId;
  const PreviousEntriesScreen({super.key, this.userId});

  @override
  State<PreviousEntriesScreen> createState() => _PreviousEntriesScreenState();
}

class _PreviousEntriesScreenState extends State<PreviousEntriesScreen> {
  // final user = FirebaseAuth.instance.currentUser!;
  int selectedYear = DateTime.now().year;
  Map<String, double> monthlyMilk = {};
  Map<String, double> monthlySpent = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchYearlyData(selectedYear);
  }

  Future<void> fetchYearlyData(int year) async {
    setState(() {
      loading = true;
      monthlyMilk = {};
      monthlySpent = {};
    });

    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    for (int month = 1; month <= 12; month++) {
      final monthStr = month.toString().padLeft(2, '0');
      double totalMilk = 0.0;
      double totalSpent = 0.0;

      // Path: users/{uid}/milk_data/{year}/months/{MM}/days
      final daysRef = firestore
          .collection('users')
          .doc(widget.userId)
          .collection('milk_data')
          .doc(year.toString())
          .collection('months')
          .doc(monthStr)
          .collection('days');

      final daysSnapshot = await daysRef.get();

      for (var dayDoc in daysSnapshot.docs) {
        final data = dayDoc.data();
        final double quantity = (data['quantity'] ?? 0).toDouble();
        final double price = (data['price'] ?? 0).toDouble();

        totalMilk += quantity;
        totalSpent += quantity * price;
      }

      monthlyMilk[monthStr] = totalMilk;
      monthlySpent[monthStr] = totalSpent;
    }

    setState(() {
      loading = false;
    });
  }



  List<int> getYearOptions() {
    final currentYear = DateTime.now().year;
    return List.generate(3, (index) => currentYear - index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Previous Entries',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Year Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Year:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedYear,
                      items: getYearOptions().map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text(
                            year.toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                      onChanged: (year) {
                        if (year != null) {
                          setState(() {
                            selectedYear = year;
                          });
                          fetchYearlyData(year);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Monthly Data List
            loading
                ? const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.blue,)))
                : Expanded(
              child: ListView.builder(
                itemCount: 12,
                itemBuilder: (context, index) {
                  final monthNum = (index + 1).toString().padLeft(2, '0');
                  final monthName = _monthName(index + 1);
                  final milk = monthlyMilk[monthNum] ?? 0;
                  final spent = monthlySpent[monthNum] ?? 0;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[100]!, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue[300],
                        child: Text(
                          monthName.substring(0, 3),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(
                        "$monthName $selectedYear",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.water_drop, size: 18, color: Colors.blueGrey),
                                const SizedBox(width: 4),
                                Text("Milk: ${milk.toStringAsFixed(2)} L"),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.currency_rupee, size: 18, color: Colors.blueGrey),
                                const SizedBox(width: 4),
                                Text("Spent: ₹${spent.toStringAsFixed(2)}"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
