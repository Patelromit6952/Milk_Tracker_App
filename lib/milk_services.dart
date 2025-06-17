import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addMilkEntryByDate({
  required String id,
  required DateTime entryDate,
  required String name,
  required double quantity,
  required double rate,
}) async {
  final year = entryDate.year.toString();
  final month = entryDate.month.toString().padLeft(2, '0');
  final day = entryDate.day.toString().padLeft(2, '0');

  final path = FirebaseFirestore.instance
      .collection('users')
      .doc(id)
      .collection('milk_data')
      .doc(year)
      .collection('months')
      .doc(month)
      .collection('days')
      .doc(day)
      .collection('milk_entries');

  await path.add({
    'name': name,
    'quantity': quantity,
    'rate': rate,
    'timestamp': entryDate,
  });
}
