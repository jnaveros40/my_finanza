/*import 'dart:convert';
import 'package:mis_finanza/services/firestore_service.dart';
import 'package:mis_finanza/services/firestore_service/category_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';


class ExportService {
  final _firestoreService = FirestoreService();

  // Convierte recursivamente Timestamps a String ISO o int
  dynamic _convertTimestamps(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is Map) {
      return value.map((k, v) => MapEntry(k, _convertTimestamps(v)));
    } else if (value is List) {
      return value.map(_convertTimestamps).toList();
    } else {
      return value;
    }
  }

  Future<String> exportAllDataAsJson() async {
    // Obtener todos los datos como listas
    final accounts = await _firestoreService.getAccounts().first;
    final movements = await _firestoreService.getMovements().first;
    final budgets = await _firestoreService.getBudgets().first;
    final investments = await _firestoreService.getInvestments().first;
    final debts = await _firestoreService.getDebts().first;
    final categories = await CategoryService.getCategories().first;

    // Serializar a mapas y convertir Timestamps
    final data = {
      'accounts': accounts.map((a) => _convertTimestamps(a.toFirestore())).toList(),
      'movements': movements.map((m) => _convertTimestamps(m.toFirestore())).toList(),
      'budgets': budgets.map((b) => _convertTimestamps(b.toFirestore())).toList(),
      'investments': investments.map((i) => _convertTimestamps(i.toFirestore())).toList(),
      'debts': debts.map((d) => _convertTimestamps(d.toFirestore())).toList(),
      'categories': categories.map((c) => _convertTimestamps(c.toFirestore())).toList(),
    };

    // Convertir a JSON
    return jsonEncode(data);
  }
}
*/