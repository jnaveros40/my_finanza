import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for current user ID

class ImportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Added

  Future<bool> importData(BuildContext context) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no autenticado. Por favor, inicia sesión e intenta de nuevo.')),
      );
      return false;
    }
    String userId = currentUser.uid;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String jsonString = await file.readAsString();
        Map<String, dynamic> data = jsonDecode(jsonString);

        // Optional: Show a confirmation dialog here before proceeding
        // bool confirm = await showDialog(...);
        // if (!confirm) return false;

        WriteBatch batch = _firestore.batch();

        // Collections exported by ExportService:
        // 'accounts', 'movements', 'budgets', 'investments', 'debts'
        // Assuming all these are user-specific collections.

        await _importCollection(data, 'accounts', batch, userId: userId);
        await _importCollection(data, 'movements', batch, userId: userId); // Changed from 'transactions'
        await _importCollection(data, 'budgets', batch, userId: userId);
        await _importCollection(data, 'investments', batch, userId: userId); // Changed from 'investment_wallets'
        await _importCollection(data, 'debts', batch, userId: userId);
        
        // Removed import for non-exported collections:
        // 'goals', 'investment_movements', 'recurring_transactions', 
        // 'payment_reminders', 'notifications', 'categories'
        // Also removed specific 'user' and 'profile' import logic as it's not in the current export structure

        await batch.commit();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos importados correctamente!')),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Importación cancelada.')),
        );
        return false;
      }
    } catch (e) {
      print('Error durante la importación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al importar datos: $e')),
      );
      return false;
    }
  }

  Future<void> _importCollection(Map<String, dynamic> allData, String collectionName, WriteBatch batch, {required String userId}) async {
    if (allData.containsKey(collectionName) && allData[collectionName] is List) {
      List<dynamic> items = allData[collectionName];
      for (var itemData in items) {
        if (itemData is Map<String, dynamic>) {
          // Use ID from JSON if available, otherwise Firestore generates one.
          // This assumes 'id' field exists in the JSON documents if you want to preserve IDs.
          // If 'id' is not in JSON, new documents will be created.
          // If 'id' IS in JSON, existing documents with that ID will be overwritten/merged.
          String docId = itemData['id'] ?? _firestore.collection('users').doc(userId).collection(collectionName).doc().id;
          
          Map<String, dynamic> processedItemData = _processTimestamps(Map<String, dynamic>.from(itemData));
          
          DocumentReference docRef;
          if (_isUserSpecificCollection(collectionName)) {
            docRef = _firestore.collection('users').doc(userId).collection(collectionName).doc(docId);
          } else {
            // This case might not be hit if all imported collections are user-specific
            docRef = _firestore.collection(collectionName).doc(docId);
          }
          // Using SetOptions(merge: true) is safer if the JSON might not contain all fields
          // of the document, preventing accidental deletion of existing fields.
          // If a full overwrite is intended, remove SetOptions(merge: true).
          batch.set(docRef, processedItemData, SetOptions(merge: true)); 
        }
      }
    }
  }

  bool _isUserSpecificCollection(String collectionName) {
    // Updated to reflect actual exported and user-specific collections
    const userSpecificCollections = [
      'accounts', 'movements', 'budgets', 'investments', 'debts'
    ];
    return userSpecificCollections.contains(collectionName);
  }

  Map<String, dynamic> _processTimestamps(Map<String, dynamic> itemData) {
    Map<String, dynamic> processedData = {};
    itemData.forEach((key, value) {
      // Convert ISO8601 strings (from export) back to Timestamps
      if (value is String && (key.toLowerCase().contains('date') || key.toLowerCase().contains('timestamp') || key.toLowerCase().endsWith('at') || key.toLowerCase().endsWith('on'))) {
        try {
          DateTime parsedDate = DateTime.parse(value);
          processedData[key] = Timestamp.fromDate(parsedDate);
        } catch (e) {
          print('Could not parse date string: $value for key: $key. Keeping original value. Error: $e');
          processedData[key] = value; 
        }
      } 
      // Handle direct Firestore Timestamp-like map objects, if any (e.g. from older exports or different sources)
      else if (value is Map<String, dynamic> && value.containsKey('_seconds') && value.containsKey('_nanoseconds')) {
         try {
          processedData[key] = Timestamp(value['_seconds'], value['_nanoseconds']);
        } catch (e) {
          print('Could not parse Timestamp map: $value for key: $key. Keeping original value. Error: $e');
          processedData[key] = value;
        }
      }
      else {
        processedData[key] = value;
      }
    });
    return processedData;
  }
}
