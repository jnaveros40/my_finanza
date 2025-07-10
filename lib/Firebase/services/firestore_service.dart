// lib/services/firestore_service.dart
/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math'; // Importar para usar pow (potencia)
import 'package:rxdart/rxdart.dart'; // Importar para combinar streams

// Importa todos los modelos
import '../../models/account.dart';
//import '../../models/category.dart';
//import '../../models/payment_method.dart';
import '../../models/movement.dart';
import '../../models/budget.dart';
import '../../models/debt.dart';
import '../../models/investment.dart';


class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper para obtener el ID del usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  // --- Métodos Generales (Ayudantes) ---

  // Función genérica para obtener una colección de un usuario
  CollectionReference<Map<String, dynamic>> _userCollection(String collectionName) {
     if (currentUserId == null) {
        //print("ADVERTENCIA: Intentando acceder a _userCollection sin usuario autenticado."); // DEBUG
        throw StateError("Usuario no autenticado.");
    }
    return _db.collection('users').doc(currentUserId).collection(collectionName);
  }

   // --- Método público para obtener un documento individual ---
   Future<DocumentSnapshot<Map<String, dynamic>>> getDocumentById(String collectionName, String documentId) async {
       if (currentUserId == null) {
           //print("Error: getDocumentById llamado sin usuario autenticado."); // DEBUG
           throw StateError("Usuario no autenticado.");
       }
       return _userCollection(collectionName).doc(documentId).get();
   }


  // --- Métodos para Cuentas ---
  // ... (saveAccount, getAccounts, deleteAccount, getAccountById - Mantener los anteriores) ...

   Future<void> saveAccount(Account account) async {
      if (currentUserId == null) {
         //print("Error: saveAccount llamado sin usuario autenticado."); // DEBUG
         throw StateError("Usuario no autenticado.");
      }
       var options = SetOptions(merge: true);
       return _userCollection('accounts')
           .doc(account.id)
           .set(account.toFirestore(), options);
   }

   Stream<List<Account>> getAccounts() {
      if (currentUserId == null) {
         //print("ADVERTENCIA: getAccounts llamado sin usuario autenticado."); // DEBUG
         return Stream.value([]);
       }
      return _userCollection('accounts')
          .orderBy('order')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Account.fromFirestore(doc)).toList());
   }

   Future<void> deleteAccount(String accountId) async {
      if (currentUserId == null) {
         //print("Error: deleteAccount llamado sin usuario autenticado."); // DEBUG
         throw StateError("Usuario no autenticado.");
      }
      // TODO: Considerar qué hacer con los movimientos asociados a esta cuenta antes de eliminarla.
      return _userCollection('accounts').doc(accountId).delete();
   }

    Future<Account?> getAccountById(String accountId) async {
       if (currentUserId == null) {
          //print("Error: getAccountById llamado sin usuario autenticado."); // DEBUG
          return null;
       }
       try {
          DocumentSnapshot doc = await getDocumentById('accounts', accountId);
          if (!doc.exists) return null;
          return Account.fromFirestore(doc);
       } catch (e) {
           //print("Error fetching account by ID: $e"); // DEBUG
           return null;
       }
    }

    // --- NUEVO: Método para obtener un stream de una cuenta por ID ---
    Stream<Account?> getAccountStreamById(String accountId) {
       if (currentUserId == null) {
          //print("ADVERTENCIA: getAccountStreamById llamado sin usuario autenticado."); // DEBUG
          return Stream.value(null);
       }
       return _userCollection('accounts')
           .doc(accountId)
           .snapshots()
           .map((snapshot) {
               if (!snapshot.exists || snapshot.data() == null) {
                   return null;
               }
               return Account.fromFirestore(snapshot);
           });
    }

/*
  // --- Métodos para Categorías ---
  // ... (saveCategory, getCategories, getCategoriesByType, deleteCategory, getCategoryById - Mantener los anteriores) ...

   Future<void> saveCategory(Category category) async {
       if (currentUserId == null) {
           //print("Error: saveCategory llamado sin usuario autenticado."); // DEBUG
           throw StateError("Usuario no autenticado.");
       }
      var options = SetOptions(merge: true);
      return _userCollection('categories')
          .doc(category.id)
          .set(category.toFirestore(), options);
   }

   Stream<List<Category>> getCategories() {
       if (currentUserId == null) {
           //print("ADVERTENCIA: getCategories llamado sin usuario autenticado."); // DEBUG
           return Stream.value([]);
       }
      return _userCollection('categories')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList());
   }

    Stream<List<Category>> getCategoriesByType(String type) {
       if (currentUserId == null) {
           //print("ADVERTENCIA: getCategoriesByType llamado sin usuario autenticado."); // DEBUG
           return Stream.value([]);
       }
       return _userCollection('categories')
           .where('type', isEqualTo: type)
           .snapshots()
           .map((snapshot) => snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList());
    }

    Future<Category?> getCategoryById(String categoryId) async {
       if (currentUserId == null) {
           //print("Error: getCategoryById llamado sin usuario autenticado."); // DEBUG
           return null;
       }
       try {
          DocumentSnapshot doc = await getDocumentById('categories', categoryId);
          if (!doc.exists) return null;
          return Category.fromFirestore(doc);
       } catch (e) {
           //print("Error fetching category by ID: $e"); // DEBUG
           return null;
       }
    }


   Future<void> deleteCategory(String categoryId) async {
       if (currentUserId == null) {
          //print("Error: deleteCategory llamado sin usuario autenticado."); // DEBUG
          throw StateError("Usuario no autenticado.");
       }
       // TODO: Considerar qué hacer con los movimientos asociados a esta categoría.
      return _userCollection('categories').doc(categoryId).delete();
   }
*/
/*
  // --- Métodos para Métodos de Pago ---
  // ... (savePaymentMethod, getPaymentMethods, deletePaymentMethod, getPaymentMethodById - Mantener los anteriores) ...

   Future<void> savePaymentMethod(PaymentMethod method) async {
       if (currentUserId == null) {
           //print("Error: savePaymentMethod llamado sin usuario autenticado."); // DEBUG
           throw StateError("Usuario no autenticado.");
       }
      var options = SetOptions(merge: true);
      return _userCollection('payment_methods')
          .doc(method.id)
          .set(method.toFirestore(), options);
   }

   Stream<List<PaymentMethod>> getPaymentMethods() {
      if (currentUserId == null) {
           //print("ADVERTENCIA: getPaymentMethods llamado sin usuario autenticado."); // DEBUG
           return Stream.value([]);
       }
      return _userCollection('payment_methods')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => PaymentMethod.fromFirestore(doc)).toList());
   }

    Future<PaymentMethod?> getPaymentMethodById(String methodId) async {
       if (currentUserId == null) {
           //print("Error: getPaymentMethodById llamado sin usuario autenticado."); // DEBUG
           return null;
       }
       try {
          DocumentSnapshot doc = await getDocumentById('payment_methods', methodId);
          if (!doc.exists) return null;
          return PaymentMethod.fromFirestore(doc);
       } catch (e) {
           //print("Error fetching payment method by ID: $e"); // DEBUG
           return null;
       }
    }
*/

   Future<void> deletePaymentMethod(String methodId) async {
       if (currentUserId == null) {
          //print("Error: deletePaymentMethod llamado sin usuario autenticado."); // DEBUG
          throw StateError("Usuario no autenticado.");
       }
       // TODO: Considerar qué hacer con los movimientos asociados a este método de pago.
      return _userCollection('payment_methods').doc(methodId).delete();
   }


  // --- Métodos para Movimientos ---

   // --- Método para añadir un movimiento y actualizar el saldo de la cuenta(s) (Atómico) ---
   Future<void> addMovementAndUpdateAccount(Movement movement) async {
      if (currentUserId == null) {
         //print("Error: addMovementAndUpdateAccount llamado sin usuario autenticado."); // DEBUG
         throw StateError("Usuario no autenticado.");
      }
      if (movement.id != null) {
         //print("ADVERTENCIA: Intentando añadir un movimiento que ya tiene ID. Esto debería ser una actualización, no una adición."); // DEBUG
         throw ArgumentError("Cannot add a movement that already has an ID. Use updateMovementAndAccount instead.");
      }

      // Validaciones previas a la transacción si son complejas
      if (movement.type == 'transfer' && movement.destinationAccountId == null) {
           throw ArgumentError("Transfer movements require a destinationAccountId.");
      }
       if (movement.type == 'transfer' && movement.accountId == movement.destinationAccountId) {
           throw ArgumentError("Source and destination accounts for a transfer cannot be the same.");
       }
        if (movement.type == 'payment' && movement.destinationAccountId == null) {
           throw ArgumentError("Payment movements require a destinationAccountId (the credit card being paid).");
      }


      await _db.runTransaction((Transaction transaction) async {
         // Obtener referencia y snapshot de la cuenta de origen (accountId)
         DocumentReference sourceAccountRef = _userCollection('accounts').doc(movement.accountId);
         DocumentSnapshot sourceAccountSnapshot = await transaction.get(sourceAccountRef);

         if (!sourceAccountSnapshot.exists || sourceAccountSnapshot.data() == null) {
             //print("Error de transacción: La cuenta de origen con ID ${movement.accountId} no existe."); // DEBUG
            throw Exception("La cuenta de origen no fue encontrada.");
         }
         Account sourceAccount = Account.fromFirestore(sourceAccountSnapshot);

         // Obtener referencia y snapshot de la cuenta de destino si aplica (transfer, payment)
         DocumentReference? destinationAccountRef;
         DocumentSnapshot? destinationAccountSnapshot;
         Account? destinationAccount;

         if (movement.type == 'transfer' || movement.type == 'payment') {
             destinationAccountRef = _userCollection('accounts').doc(movement.destinationAccountId); // Usar destinationAccountId del modelo
             destinationAccountSnapshot = await transaction.get(destinationAccountRef);

              if (!destinationAccountSnapshot.exists || destinationAccountSnapshot.data() == null) {
                 //print("Error de transacción: La cuenta de destino con ID ${movement.destinationAccountId} no existe."); // DEBUG
                throw Exception("La cuenta de destino no fue encontrada.");
             }
             destinationAccount = Account.fromFirestore(destinationAccountSnapshot);
         }


         // --- Lógica de actualización de saldo/adeudado según el tipo de movimiento ---
         switch (movement.type) {
            case 'expense':
               if (sourceAccount.isCreditCard) {
                  // Usar FieldValue.increment para actualizar de forma atómica el adeudado
                  transaction.update(sourceAccountRef, {'currentStatementBalance': FieldValue.increment(movement.amount)});
                  //print("DEBUG Add: Gasto en CC. Adeudado incrementado por ${movement.amount}"); // DEBUG

                  // --- NUEVO: Actualizar el cupo disponible (currentBalance) ---
                   transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(-movement.amount)});
                   //print("DEBUG Add: Gasto en CC. Cupo disponible decrementado por ${movement.amount}"); // DEBUG
                  // ----------------------------------------------------------

               } else {
                  // Usar FieldValue.increment para actualizar de forma atómica el saldo
                  transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(-movement.amount)});
                  //print("DEBUG Add: Gasto en cuenta no CC. Saldo decrementado por ${movement.amount}"); // DEBUG
               }
               break;

            case 'income':
               // Ingreso siempre suma al saldo de la cuenta (no aplica a CC adeudado)
               if (!sourceAccount.isCreditCard) {
                  // Usar FieldValue.increment para actualizar de forma atómica
                  transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(movement.amount)});
                   //print("DEBUG Add: Ingreso en cuenta no CC. Saldo incrementado por ${movement.amount}"); // DEBUG
               } else {
                   //print("ADVERTENCIA Add: Intentando registrar un ingreso en una Tarjeta de Crédito. Esto no afecta el saldo adeudado."); // DEBUG
                   // Podrías lanzar un error si no quieres permitirlo.
               }
               break;

            case 'transfer':
               // Transferencia: Resta de la cuenta de origen, suma a la cuenta de destino
               if (destinationAccount == null) throw StateError("Destination account is required for transfer."); // Doble check

               // Resta de la cuenta de origen
               if (sourceAccount.isCreditCard) {
                   // Si es CC, suma al adeudado (currentStatementBalance) y resta al cupo disponible (currentBalance)
                   transaction.update(sourceAccountRef, {'currentStatementBalance': FieldValue.increment(movement.amount)}); // Suma al adeudado
                   transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(-movement.amount)}); // Resta del cupo disponible
                   //print("DEBUG Add: Transferencia desde CC. Adeudado incrementado y Cupo disponible decrementado por ${movement.amount}"); // DEBUG
               } else {
                   // Si no es CC, resta del saldo (currentBalance)
                   transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(-movement.amount)});
                   //print("DEBUG Add: Transferencia desde cuenta no CC. Saldo de origen decrementado por ${movement.amount}"); // DEBUG
               }


               // Suma a la cuenta de destino (nunca CC adeudado)
               if (!destinationAccount.isCreditCard) { // Check null destinationAccount
                   // Usar FieldValue.increment para actualizar de forma atómica
                   transaction.update(destinationAccountRef!, {'currentBalance': FieldValue.increment(movement.amount)});
                   //print("DEBUG Add: Transferencia. Saldo de destino incrementado por ${movement.amount}"); // DEBUG
               } else {
                   // Si la cuenta de destino es CC, no se suma al saldo adeudado.
                   // Podrías manejar un caso específico si una transferencia a CC significa un abono,
                   // pero el tipo 'payment' ya está diseñado para eso.
                   //print("ADVERTENCIA Add: Intentando transferir a una Tarjeta de Crédito. Esto no afecta el saldo adeudado de la CC."); // DEBUG
               }
               break;

            case 'payment': // Pago de Tarjeta de Crédito
               // Pago: Resta de la cuenta de origen (ej. cuenta de ahorro), resta del saldo adeudado de la CC (cuenta de destino)
               if (destinationAccount == null) throw StateError("Destination account (credit card) is required for payment."); // Doble check
               if (!destinationAccount.isCreditCard) throw ArgumentError("Destination account for payment must be a credit card."); // Validar que destino es CC

               // Resta de la cuenta de origen (nunca CC adeudado)
               if (!sourceAccount.isCreditCard) {
                   // Usar FieldValue.increment para actualizar de forma atómica
                   transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(-movement.amount)});
                   //print("DEBUG Add: Pago CC. Saldo de origen decrementado por ${movement.amount}"); // DEBUG
               } else {
                   //print("ADVERTENCIA Add: Intentando pagar una CC desde otra Tarjeta de Crédito. Esto no está manejado explícitamente."); // DEBUG
                   // Podrías lanzar un error.
               }

               // Resta del saldo adeudado de la Tarjeta de Crédito (cuenta de destino)
               // Usar FieldValue.increment para actualizar de forma atómica
               if (destinationAccountRef != null) { // Check null destinationAccountRef
                   transaction.update(destinationAccountRef, {'currentStatementBalance': FieldValue.increment(-movement.amount)});
                   //print("DEBUG Add: Pago CC. Adeudado de destino (CC) decrementado por ${movement.amount}"); // DEBUG

                   // --- NUEVO: Actualizar el cupo disponible (currentBalance) de la cuenta de destino CC ---
                   // Al pagar, el adeudado disminuye, por lo tanto el cupo disponible aumenta.
                   transaction.update(destinationAccountRef, {'currentBalance': FieldValue.increment(movement.amount)});
                   //print("DEBUG Add: Pago CC. Cupo disponible de destino CC incrementado por ${movement.amount}"); // DEBUG
                   // ------------------------------------------------------------------------------------
               } else {
                   //print("ADVERTENCIA Add: destinationAccountRef es null al procesar pago."); // DEBUG
               }

               break;

            default:
               //print("ADVERTENCIA Add: Tipo de movimiento '${movement.type}' no manejado para actualización de saldo al añadir."); // DEBUG
               // No se actualiza el saldo para tipos no manejados explícitamente.
               break;
         }
         // -----------------------------------------------------------------------


         CollectionReference movementsRef = _userCollection('expenses'); // Colección sigue llamándose 'expenses' por ahora
         transaction.set(movementsRef.doc(), movement.toFirestore()); // Añadir el nuevo documento

      });

      //print("Transacción de añadir movimiento y actualizar cuenta(s) completada."); // DEBUG
   }


  // --- Método para obtener todos los movimientos del usuario actual ---
   Stream<List<Movement>> getMovements({String typeFilter = 'all'}) {
      if (currentUserId == null) {
         //print("ADVERTENCIA: getMovements llamado sin usuario autenticado."); // DEBUG
         return Stream.value([]);
       }
      Query<Map<String, dynamic>> query = _userCollection('expenses'); // Colección sigue llamándose 'expenses'

      // Aplicar filtro por tipo si no es 'all'
      if (typeFilter != 'all') {
         query = query.where('type', isEqualTo: typeFilter);
      }

      // Opcional: ordenar movimientos por fecha descendente
      query = query.orderBy('dateTime', descending: true);

      return query
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Movement.fromFirestore(doc)).toList());
   }
// --- Método para obtener movimientos por rango de fechas y tipo (opcional) ---
    Stream<List<Movement>> getMovementsByDateRange(DateTime startDate, DateTime endDate, {String? typeFilter}) {
      if (currentUserId == null) {
         //print("ADVERTENCIA: getMovementsByDateRange llamado sin usuario autenticado."); // DEBUG
         return Stream.value([]);
       }

       // --- CAMBIO: Usar la colección 'expenses' en lugar de 'movements' ---
       Query query = _userCollection('expenses'); // Colección 'expenses'

       // Filtrar por rango de fechas (Timestamp)
       query = query.where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
       // --- CAMBIO: Usar isLessThanOrEqualTo para incluir movimientos hasta el final del día endDate ---
       // Para incluir el final del día endDate, necesitamos un Timestamp que represente el final del día.
       // Una forma común es usar isLessThan del inicio del DÍA SIGUIENTE.
       DateTime endOfEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999); // Fin del día
       query = query.where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfEndDate));


       // Aplicar filtro por tipo si se especifica
       if (typeFilter != null && typeFilter.isNotEmpty) {
           query = query.where('type', isEqualTo: typeFilter);
       }

       // Opcional: ordenar movimientos por fecha ascendente para procesarlos cronológicamente si es necesario
       // Para este caso, solo necesitamos la suma, el orden no es crítico para la suma total.
       // query = query.orderBy('dateTime', ascending: true);


       return query
           .snapshots()
           .map((snapshot) => snapshot.docs.map((doc) => Movement.fromFirestore(doc)).toList());
    }

  // --- Método para eliminar un movimiento (requiere actualizar saldo de cuenta(s) - Atómico) ---
   Future<void> deleteMovement(String movementId) async {
      if (currentUserId == null) {
          //print("Error: deleteMovement llamado sin usuario autenticado."); // DEBUG
          throw StateError("Usuario no autenticado.");
       }

       DocumentReference movementRef = _userCollection('expenses').doc(movementId); // Colección sigue llamándose 'expenses'

       await _db.runTransaction((Transaction transaction) async {
           DocumentSnapshot movementSnapshot = await transaction.get(movementRef);

           if (!movementSnapshot.exists || movementSnapshot.data() == null) {
              //print("Error de transacción: El movimiento con ID $movementId no existe."); // DEBUG
               throw Exception("El movimiento a eliminar no fue encontrado.");
           }

           Movement movementToDelete = Movement.fromFirestore(movementSnapshot);

           // Obtener referencia y snapshot de la cuenta de origen (accountId)
           DocumentReference sourceAccountRef = _userCollection('accounts').doc(movementToDelete.accountId);
           DocumentSnapshot sourceAccountSnapshot = await transaction.get(sourceAccountRef);

            if (!sourceAccountSnapshot.exists || sourceAccountSnapshot.data() == null) {
               //print("ADVERTENCIA Delete: La cuenta de origen con ID ${movementToDelete.accountId} asociada al movimiento $movementId no existe. No se revertirá el saldo original."); // DEBUG
            } else {
                Account associatedSourceAccount = Account.fromFirestore(sourceAccountSnapshot);

                // --- Lógica de reversión de saldo/adeudado según el tipo de movimiento ---
                switch (movementToDelete.type) {
                   case 'expense':
                      if (associatedSourceAccount.isCreditCard) {
                          // Usar FieldValue.increment para revertir (restar) al adeudado
                          transaction.update(sourceAccountRef, {'currentStatementBalance': FieldValue.increment(-movementToDelete.amount)});
                          //print("DEBUG Delete: Eliminando movimiento (Gasto) en CC. Adeudado revertido (restado) por ${movementToDelete.amount}"); // DEBUG

                          // --- NUEVO: Revertir la actualización del cupo disponible (currentBalance) ---
                          // Al eliminar un gasto de CC, el cupo disponible debe aumentar.
                          transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(movementToDelete.amount)});
                          //print("DEBUG Delete: Eliminando movimiento (Gasto) en CC. Cupo disponible revertido (sumado) por ${movementToDelete.amount}"); // DEBUG
                          // ------------------------------------------------------------------------

                      } else {
                          // Usar FieldValue.increment para revertir (sumar) al saldo
                          transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(movementToDelete.amount)});
                          //print("DEBUG Delete: Eliminando movimiento (Gasto) en cuenta no CC. Saldo revertido (sumado) por ${movementToDelete.amount}"); // DEBUG
                      }
                      break;

                   case 'income':
                      // Reversión de ingresos: restar del saldo de la cuenta (no aplica a CC adeudado)
                       if (!associatedSourceAccount.isCreditCard) {
                          // Usar FieldValue.increment para revertir (restar) al saldo
                          // double newBalance = associatedSourceAccount.currentBalance - movementToDelete.amount; // Esta línea no es necesaria con increment
                          transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(-movementToDelete.amount)});
                           //print("DEBUG Delete: Eliminando movimiento (Ingreso) en cuenta no CC. Saldo revertido (restado) por ${movementToDelete.amount}"); // DEBUG
                       } else {
                           //print("ADVERTENCIA Delete: Intentando revertir un ingreso en una Tarjeta de Crédito."); // DEBUG
                       }
                      break;

                   case 'transfer':
                      // Reversión de transferencia: Suma de vuelta a la cuenta de origen, resta de la cuenta de destino
                      // Obtener referencia y snapshot de la cuenta de destino
                      if (movementToDelete.destinationAccountId != null) {
                          DocumentReference destinationAccountRef = _userCollection('accounts').doc(movementToDelete.destinationAccountId);
                          DocumentSnapshot destinationAccountSnapshot = await transaction.get(destinationAccountRef);

                          if (!destinationAccountSnapshot.exists || destinationAccountSnapshot.data() == null) {
                             //print("ADVERTENCIA Delete: La cuenta de destino con ID ${movementToDelete.destinationAccountId} asociada al movimiento $movementId no existe. No se revertirá el saldo de destino."); // DEBUG
                          } else {
                              Account associatedDestinationAccount = Account.fromFirestore(destinationAccountSnapshot);
                              // Suma de vuelta a la cuenta de origen
                              if (associatedSourceAccount.isCreditCard) {
                                  // Si es CC, suma de vuelta al adeudado (currentStatementBalance) y resta del cupo disponible (currentBalance)
                                  transaction.update(sourceAccountRef, {'currentStatementBalance': FieldValue.increment(movementToDelete.amount)});
                                  transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(-movementToDelete.amount)}); // Cupo disponible disminuye
                                  //print("DEBUG Delete: Eliminando movimiento (Transferencia desde CC). Adeudado revertido (sumado) y Cupo disponible revertido (restado) por ${movementToDelete.amount}"); // DEBUG
                              } else {
                                  // Si no es CC, suma de vuelta al saldo (currentBalance)
                                  transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(movementToDelete.amount)});
                                  //print("DEBUG Delete: Eliminando movimiento (Transferencia desde cuenta no CC). Saldo de origen revertido (sumado) por ${movementToDelete.amount}"); // DEBUG
                              }


                              // Resta de la cuenta de destino (nunca CC adeudado)
                              if (!associatedDestinationAccount.isCreditCard) {
                                  // Usar FieldValue.increment para revertir (restar) al saldo de destino
                                  transaction.update(destinationAccountRef, {'currentBalance': FieldValue.increment(-movementToDelete.amount)});
                                  //print("DEBUG Delete: Eliminando movimiento (Transferencia). Saldo de destino revertido (restado) por ${movementToDelete.amount}"); // DEBUG
                              } else {
                                  //print("ADVERTENCIA Delete: Intentando revertir transferencia a una Tarjeta de Crédito."); // DEBUG
                              }
                          }
                      } else {
                           //print("ADVERTENCIA Delete: Movimiento de transferencia sin destinationAccountId al eliminar."); // DEBUG
                      }
                      break;

                   case 'payment': // Reversión de Pago de Tarjeta de Crédito
                      // Reversión de pago: Suma de vuelta a la cuenta de origen, suma de vuelta al saldo adeudado de la CC (cuenta de destino)
                       if (movementToDelete.destinationAccountId != null) {
                          DocumentReference destinationAccountRef = _userCollection('accounts').doc(movementToDelete.destinationAccountId);
                          DocumentSnapshot destinationAccountSnapshot = await transaction.get(destinationAccountRef);

                           if (!destinationAccountSnapshot.exists || destinationAccountSnapshot.data() == null) {
                              //print("ADVERTENCIA Delete: La cuenta de destino (CC) con ID ${movementToDelete.destinationAccountId} asociada al movimiento $movementId no existe. No se revertirá el adeudado."); // DEBUG
                           } else {
                               Account associatedDestinationAccount = Account.fromFirestore(destinationAccountSnapshot);
                               if (!associatedDestinationAccount.isCreditCard) {
                                   //print("ADVERTENCIA Delete: La cuenta de destino para este pago original no era una Tarjeta de Crédito."); // DEBUG
                               } else {
                                   // Suma de vuelta a la cuenta de origen (nunca CC adeudado)
                                   if (!associatedSourceAccount.isCreditCard) {
                                       // Usar FieldValue.increment para revertir (sumar) al saldo de origen
                                       transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(movementToDelete.amount)});
                                       //print("DEBUG Delete: Eliminando movimiento (Pago CC). Saldo de origen revertido (sumado) por ${movementToDelete.amount}"); // DEBUG
                                   } else {
                                       //print("ADVERTENCIA Delete: Intentando revertir pago de CC desde otra Tarjeta de Crédito."); // DEBUG
                                   }

                                   // Suma de vuelta al saldo adeudado de la Tarjeta de Crédito (cuenta de destino)
                                   // Usar FieldValue.increment para revertir (sumar) al adeudado de destino
                                   transaction.update(destinationAccountRef, {'currentStatementBalance': FieldValue.increment(movementToDelete.amount)});
                                   //print("DEBUG Delete: Eliminando movimiento (Pago CC). Adeudado de destino (CC) revertido (sumado) por ${movementToDelete.amount}"); // DEBUG

                                   // --- NUEVO: Revertir la actualización del cupo disponible (currentBalance) de la cuenta de destino CC ---
                                   // Al eliminar un pago a CC, el adeudado aumenta, por lo tanto el cupo disponible debe disminuir.
                                   transaction.update(destinationAccountRef, {'currentBalance': FieldValue.increment(-movementToDelete.amount)});
                                   //print("DEBUG Delete: Eliminando movimiento (Pago CC). Cupo disponible de destino CC revertido (restado) por ${movementToDelete.amount}"); // DEBUG
                                   // ----------------------------------------------------------------------------------------------------
                               }
                           }
                       } else {
                            //print("ADVERTENCIA Delete: Movimiento de pago sin destinationAccountId al eliminar."); // DEBUG
                       }
                      break;


                   default:
                       //print("ADVERTENCIA Delete: Tipo de movimiento '${movementToDelete.type}' no manejado para reversión de saldo al eliminar."); // DEBUG
                       // No se revierte el saldo para tipos no manejados explícitamente.
                       break;
                }
            }
           // ---------------------------------------------------------------------


           transaction.delete(movementRef); // Eliminar el documento del movimiento
       });

        //print("Transacción de eliminar movimiento y actualizar cuenta(s) completada."); // DEBUG
   }

  // --- Método para actualizar un movimiento y sus cuentas asociadas (Atómico) ---
   Future<void> updateMovementAndAccount(Movement originalMovement, Movement updatedMovement) async {
      if (currentUserId == null) {
          //print("Error: updateMovementAndAccount llamado sin usuario autenticado."); // DEBUG
          throw StateError("Usuario no autenticado.");
       }
       if (originalMovement.id == null || updatedMovement.id == null || originalMovement.id != updatedMovement.id) {
           //print("Error: updateMovementAndAccount requiere un movimiento original y uno actualizado con el mismo ID válido."); // DEBUG
           throw ArgumentError("Invalid movement IDs for update.");
       }
       if (originalMovement.userId != currentUserId || updatedMovement.userId != currentUserId) {
            //print("Error: Intentando actualizar movimiento de otro usuario."); // DEBUG
            throw StateError("Cannot update movement belonging to another user.");
       }

        // Por ahora, no permitimos cambiar el tipo de movimiento durante la edición.
       if (originalMovement.type != updatedMovement.type) {
            //print("Error: Cambiar el tipo de movimiento durante la edición no está soportado actualmente."); // DEBUG
             throw ArgumentError("Changing movement type during edit is not supported.");
       }

       // Validaciones previas a la transacción para el movimiento ACTUALIZADO
       if (updatedMovement.type == 'transfer' && updatedMovement.destinationAccountId == null) {
           throw ArgumentError("Updated transfer movement requires a destinationAccountId.");
      }
        if (updatedMovement.type == 'transfer' && updatedMovement.accountId == updatedMovement.destinationAccountId) {
           throw ArgumentError("Source and destination accounts for an updated transfer cannot be the same.");
       }
        if (updatedMovement.type == 'payment' && updatedMovement.destinationAccountId == null) {
           throw ArgumentError("Payment movements require a destinationAccountId (the credit card being paid).");
      }


       await _db.runTransaction((Transaction transaction) async {
           //print("DEBUG Update Transaction: Iniciando transacción para actualizar movimiento ${originalMovement.id}"); // DEBUG
           //print("DEBUG Update Transaction: Original Movement: Account: ${originalMovement.accountId}, Dest: ${originalMovement.destinationAccountId}, Type: ${originalMovement.type}, Amount: ${originalMovement.amount}"); // DEBUG
           //print("DEBUG Update Transaction: Updated Movement: Account: ${updatedMovement.accountId}, Dest: ${updatedMovement.destinationAccountId}, Type: ${updatedMovement.type}, Amount: ${updatedMovement.amount}"); // DEBUG


           // --- PASO 1: OBTENER TODOS LOS DOCUMENTOS NECESARIOS AL PRINCIPIO ---

           // Obtener referencia y snapshot de la cuenta de origen original
           DocumentReference originalSourceAccountRef = _userCollection('accounts').doc(originalMovement.accountId);
           DocumentSnapshot originalSourceAccountSnapshot = await transaction.get(originalSourceAccountRef);
           Account? originalSourceAccount = originalSourceAccountSnapshot.exists && originalSourceAccountSnapshot.data() != null
               ? Account.fromFirestore(originalSourceAccountSnapshot) : null;


           // Obtener referencia y snapshot de la cuenta de destino original si aplica
           DocumentReference? originalDestinationAccountRef;
           DocumentSnapshot? originalDestinationAccountSnapshot;
           Account? originalDestinationAccount;
           if ((originalMovement.type == 'transfer' || originalMovement.type == 'payment') && originalMovement.destinationAccountId != null) {
               originalDestinationAccountRef = _userCollection('accounts').doc(originalMovement.destinationAccountId);
               originalDestinationAccountSnapshot = await transaction.get(originalDestinationAccountRef);
               originalDestinationAccount = originalDestinationAccountSnapshot.exists && originalDestinationAccountSnapshot.data() != null
                   ? Account.fromFirestore(originalDestinationAccountSnapshot) : null;
           }

           // Obtener referencia y snapshot de la cuenta de origen actualizada
           DocumentReference updatedSourceAccountRef = _userCollection('accounts').doc(updatedMovement.accountId);
           DocumentSnapshot updatedSourceAccountSnapshot = await transaction.get(updatedSourceAccountRef);
           if (!updatedSourceAccountSnapshot.exists || updatedSourceAccountSnapshot.data() == null) {
               //print("Error de transacción: La cuenta NUEVA de origen con ID ${updatedMovement.accountId} asociada al movimiento ${updatedMovement.id} no existe."); // DEBUG
               throw Exception("Updated source account not found.");
           }
           Account updatedSourceAccount = Account.fromFirestore(updatedSourceAccountSnapshot);


           // Obtener referencia y snapshot de la cuenta de destino actualizada si aplica
           DocumentReference? updatedDestinationAccountRef;
           DocumentSnapshot? updatedDestinationAccountSnapshot;
           Account? updatedDestinationAccount;
           if (updatedMovement.type == 'transfer' || updatedMovement.type == 'payment') {
               updatedDestinationAccountRef = _userCollection('accounts').doc(updatedMovement.destinationAccountId);
               updatedDestinationAccountSnapshot = await transaction.get(updatedDestinationAccountRef);
               if (!updatedDestinationAccountSnapshot.exists || updatedDestinationAccountSnapshot.data() == null) {
                  //print("Error de transacción: La cuenta NUEVA de destino con ID ${updatedMovement.destinationAccountId} no existe."); // DEBUG
                 throw Exception("Updated destination account not found.");
              }
              updatedDestinationAccount = Account.fromFirestore(updatedDestinationAccountSnapshot);
              // Validar que la cuenta de destino para pago sea una CC
              if (updatedMovement.type == 'payment' && !updatedDestinationAccount.isCreditCard) {
                  throw ArgumentError("Updated destination account for payment must be a credit card.");
              }
           }

           //print("DEBUG Update Transaction: Todas las lecturas completadas."); // DEBUG
           // --- FIN PASO 1 ---


           // --- PASO 2: REVERTIR EL EFECTO DEL MOVIMIENTO ORIGINAL ---
           if (originalSourceAccount != null) {
               //print("DEBUG Update Revert: Original Source Account ID: ${originalMovement.accountId}, isCreditCard: ${originalSourceAccount.isCreditCard}, Original Amount: ${originalMovement.amount}"); // DEBUG
               // Lógica de reversión en la cuenta de origen original
                if (originalMovement.type == 'expense') {
                   // Gasto: Revertir resta en cuenta de origen
                    if (!originalSourceAccount.isCreditCard) {
                       transaction.update(originalSourceAccountRef, {'currentBalance': FieldValue.increment(originalMovement.amount)});
                        //print("DEBUG Update Revert: Sumando ${originalMovement.amount} a currentBalance de origen para revertir gasto."); // DEBUG
                    } else if (originalSourceAccount.isCreditCard) {
                        // Revertir gasto en CC: Restar del adeudado (sumar)
                         transaction.update(originalSourceAccountRef, {'currentStatementBalance': FieldValue.increment(-originalMovement.amount)});
                         //print("DEBUG Update Revert: Restando ${originalMovement.amount} de currentStatementBalance de origen CC para revertir gasto."); // DEBUG

                         // Revertir la actualización del cupo disponible (currentBalance)
                         transaction.update(originalSourceAccountRef, {'currentBalance': FieldValue.increment(originalMovement.amount)});
                         //print("DEBUG Update Revert: Sumando ${originalMovement.amount} a currentBalance de origen CC para revertir gasto (cupo disponible)."); // DEBUG

                    } else {
                         //print("ADVERTENCIA Update Revert: Intentando revertir movimiento de tipo ${originalMovement.type} desde una Tarjeta de Crédito (origen) no manejado explícitamente."); // DEBUG
                    }
                } else if (originalMovement.type == 'income') {
                   // Ingreso: Revertir suma (restar) en cuenta de origen (si no es CC adeudado)
                    if (!originalSourceAccount.isCreditCard) {
                       transaction.update(originalSourceAccountRef, {'currentBalance': FieldValue.increment(-originalMovement.amount)});
                        //print("DEBUG Update Revert: Restando ${originalMovement.amount} de currentBalance de origen para revertir ingreso."); // DEBUG
                    } else {
                         //print("ADVERTENCIA Update Revert: Intentando revertir movimiento de tipo ${originalMovement.type} en una Tarjeta de Crédito (origen) no manejado explícitamente."); // DEBUG
                    }
                } else if (originalMovement.type == 'transfer') {
                    // Transferencia: Revertir el efecto original
                    if (originalSourceAccount.isCreditCard) {
                        // Si origen era CC, revertir la suma al adeudado (restar) y la resta al cupo disponible (sumar)
                        transaction.update(originalSourceAccountRef, {'currentStatementBalance': FieldValue.increment(-originalMovement.amount)}); // Restar al adeudado
                        transaction.update(originalSourceAccountRef, {'currentBalance': FieldValue.increment(originalMovement.amount)}); // Sumar al cupo disponible
                        //print("DEBUG Update Revert: Revertiendo Transferencia desde CC. Adeudado restado y Cupo disponible sumado por ${originalMovement.amount}"); // DEBUG
                    } else if (!originalSourceAccount.isCreditCard) {
                        // Si origen no era CC, revertir la resta del saldo (sumar)
                        transaction.update(originalSourceAccountRef, {'currentBalance': FieldValue.increment(originalMovement.amount)});
                        //print("DEBUG Update Revert: Revertiendo Transferencia desde cuenta no CC. Saldo de origen sumado por ${originalMovement.amount}"); // DEBUG
                    } else {
                         //print("ADVERTENCIA Update Revert: Intentando revertir transferencia desde cuenta de origen desconocida."); // DEBUG
                    }
                } else if (originalMovement.type == 'payment') {
                     // Pago: Revertir el efecto original
                     if (!originalSourceAccount.isCreditCard) { // Origen no era CC
                        transaction.update(originalSourceAccountRef, {'currentBalance': FieldValue.increment(originalMovement.amount)});
                         //print("DEBUG Update Revert: Revertiendo Pago CC. Saldo de origen revertido (sumado) por ${originalMovement.amount}"); // DEBUG
                     } else {
                         //print("ADVERTENCIA Update Revert: Intentando revertir pago CC desde cuenta de origen CC."); // DEBUG
                     }
                }
                 else {
                    //print("ADVERTENCIA Update Revert: Tipo de movimiento original '${originalMovement.type}' no manejado para reversión de saldo."); // DEBUG
                }
           } else {
               //print("ADVERTENCIA Update Revert: Cuenta de origen original no encontrada. No se pudo revertir el saldo."); // DEBUG
           }


           // Revertir el efecto en la cuenta de destino original si aplica (transfer, payment)
           if (originalDestinationAccount != null && originalDestinationAccountRef != null) {
               //print("DEBUG Update Revert: Original Destination Account ID: ${originalMovement.destinationAccountId}, isCreditCard: ${originalDestinationAccount.isCreditCard}, Original Amount: ${originalMovement.amount}"); // DEBUG
               // Lógica de reversión en la cuenta de destino original
               if (originalMovement.type == 'transfer') {
                       // Transferencia: Revertir suma (restar) en cuenta de destino (si no es CC adeudado)
                       if (!originalDestinationAccount.isCreditCard) {
                           transaction.update(originalDestinationAccountRef, {'currentBalance': FieldValue.increment(-originalMovement.amount)});
                            //print("DEBUG Update Revert: Restando ${originalMovement.amount} de currentBalance de destino para revertir transferencia."); // DEBUG
                       } else {
                            //print("ADVERTENCIA Update Revert: Intentando revertir transferencia a una Tarjeta de Crédito (destino) no manejado explícitamente."); // DEBUG
                       }
                   } else if (originalMovement.type == 'payment') {
                       // Pago: Revertir resta de adeudado (sumar) en cuenta de destino (si es CC)
                       if (originalDestinationAccount.isCreditCard) {
                           transaction.update(originalDestinationAccountRef, {'currentStatementBalance': FieldValue.increment(originalMovement.amount)});
                            //print("DEBUG Update Revert: Sumando ${originalMovement.amount} a currentStatementBalance de destino CC para revertir pago."); // DEBUG

                            // Revertir la actualización del cupo disponible (currentBalance) de la cuenta de destino CC
                            transaction.update(originalDestinationAccountRef, {'currentBalance': FieldValue.increment(-originalMovement.amount)});
                            //print("DEBUG Update Revert: Restando ${originalMovement.amount} de currentBalance de destino CC para revertir pago (cupo disponible)."); // DEBUG

                       } else {
                            //print("ADVERTENCIA Update Revert: La cuenta de destino para este pago original no era una Tarjeta de Crédito."); // DEBUG
                       }
                   } else {
                        //print("ADVERTENCIA Update Revert: Tipo de movimiento original '${originalMovement.type}' no manejado para reversión de saldo en destino."); // DEBUG
                   }
           } else if ((originalMovement.type == 'transfer' || originalMovement.type == 'payment') && originalMovement.destinationAccountId != null) {
                 //print("ADVERTENCIA Update Revert: Cuenta de destino original no encontrada para movimiento de tipo ${originalMovement.type}. No se pudo revertir el saldo."); // DEBUG
           }
            //print("DEBUG Update Transaction: Reversión completada."); // DEBUG
           // --- FIN PASO 2 ---


           // --- PASO 3: APLICAR EL EFECTO DEL MOVIMIENTO ACTUALIZADO ---
           //print("DEBUG Update Apply: Updated Source Account ID: ${updatedMovement.accountId}, isCreditCard: ${updatedSourceAccount.isCreditCard}, Updated Amount: ${updatedMovement.amount}"); // DEBUG;

           // Aplicar el efecto del movimiento ACTUALIZADO en la cuenta de origen actualizada
           switch (updatedMovement.type) { // Usamos el tipo del movimiento actualizado (que es el mismo que el original por ahora)
              case 'expense':
                 if (updatedSourceAccount.isCreditCard) {
                    // Usar FieldValue.increment para aplicar (sumar) al adeudado
                    transaction.update(updatedSourceAccountRef, {'currentStatementBalance': FieldValue.increment(updatedMovement.amount)});
                    //print("DEBUG Update Apply: Aplicando Gasto en CC. Sumando ${updatedMovement.amount} a currentStatementBalance de origen CC."); // DEBUG

                    // Actualizar el cupo disponible (currentBalance)
                    transaction.update(updatedSourceAccountRef, {'currentBalance': FieldValue.increment(-updatedMovement.amount)});
                    //print("DEBUG Update Apply: Aplicando Gasto en CC. Restando ${updatedMovement.amount} de currentBalance de origen CC (cupo disponible)."); // DEBUG

                 } else {
                    // Usar FieldValue.increment para aplicar (restar) al saldo
                    transaction.update(updatedSourceAccountRef, {'currentBalance': FieldValue.increment(-updatedMovement.amount)});
                    //print("DEBUG Update Apply: Aplicando Gasto en no CC. Restando ${updatedMovement.amount} de currentBalance de origen."); // DEBUG
                 }
                 break;

              case 'income':
                 if (!updatedSourceAccount.isCreditCard) {
                    // Usar FieldValue.increment para aplicar (sumar) al saldo
                    transaction.update(updatedSourceAccountRef, {'currentBalance': FieldValue.increment(updatedMovement.amount)});
                     //print("DEBUG Update Apply: Aplicando Ingreso en no CC. Sumando ${updatedMovement.amount} a currentBalance de origen."); // DEBUG
                 } else {
                      //print("ADVERTENCIA Update Apply: Intentando aplicar un ingreso en una Tarjeta de Crédito (origen) durante la edición."); // DEBUG
                 }
                 break;

              case 'transfer':
                 if (updatedDestinationAccount == null || updatedDestinationAccountRef == null) throw StateError("Destination account is required for updated transfer."); // Doble check

                 // Resta de la cuenta de origen
                 if (updatedSourceAccount.isCreditCard) {
                     // Si es CC, suma al adeudado (currentStatementBalance) y resta al cupo disponible (currentBalance)
                     transaction.update(updatedSourceAccountRef, {'currentStatementBalance': FieldValue.increment(updatedMovement.amount)}); // Suma al adeudado
                     transaction.update(updatedSourceAccountRef, {'currentBalance': FieldValue.increment(-updatedMovement.amount)}); // Resta del cupo disponible
                     //print("DEBUG Update Apply: Aplicando Transferencia desde CC. Adeudado incrementado y Cupo disponible decrementado por ${updatedMovement.amount}"); // DEBUG
                 } else {
                     // Si no es CC, resta del saldo (currentBalance)
                     transaction.update(updatedSourceAccountRef, {'currentBalance': FieldValue.increment(-updatedMovement.amount)});
                     //print("DEBUG Update Apply: Aplicando Transferencia desde cuenta no CC. Saldo de origen decrementado por ${updatedMovement.amount}"); // DEBUG
                 }

                 // Suma a la cuenta de destino (nunca CC adeudado)
                 if (!updatedDestinationAccount.isCreditCard) {
                     // Usar FieldValue.increment para aplicar (sumar) al saldo de destino
                     transaction.update(updatedDestinationAccountRef, {'currentBalance': FieldValue.increment(updatedMovement.amount)});
                     //print("DEBUG Update Apply: Aplicando Transferencia. Sumando ${updatedMovement.amount} a currentBalance de destino."); // DEBUG
                 } else {
                     //print("ADVERTENCIA Update Apply: Intentando transferir a una Tarjeta de Crédito (destino) durante la edición."); // DEBUG
                 }
                 break;

              case 'payment': // Aplicación de Pago de Tarjeta de Crédito
                 if (updatedDestinationAccount == null || updatedDestinationAccountRef == null) throw StateError("Destination account (credit card) is required for updated payment."); // Doble check
                 if (!updatedDestinationAccount.isCreditCard) throw ArgumentError("Updated destination account for payment must be a credit card."); // Validar que destino es CC

                 // Resta de la cuenta de origen (nunca CC adeudado)
                 if (!updatedSourceAccount.isCreditCard) {
                     // Usar FieldValue.increment para aplicar (restar) al saldo de origen
                     transaction.update(updatedSourceAccountRef, {'currentBalance': FieldValue.increment(-updatedMovement.amount)});
                     //print("DEBUG Update Apply: Aplicando Pago CC. Restando ${updatedMovement.amount} de currentBalance de origen."); // DEBUG
                 } else {
                     //print("ADVERTENCIA Update Apply: Intentando pagar una CC desde otra Tarjeta de Crédito (origen) durante la edición."); // DEBUG
                 }

                 // Resta del saldo adeudado de la Tarjeta de Crédito (cuenta de destino)
                 transaction.update(updatedDestinationAccountRef, {'currentStatementBalance': FieldValue.increment(-updatedMovement.amount)});
                 //print("DEBUG Update Apply: Aplicando Pago CC. Restando ${updatedMovement.amount} de currentStatementBalance de destino CC."); // DEBUG

                 // Actualizar el cupo disponible (currentBalance) de la cuenta de destino CC
                 transaction.update(updatedDestinationAccountRef, {'currentBalance': FieldValue.increment(updatedMovement.amount)});
                 //print("DEBUG Update Apply: Aplicando Pago CC. Sumando ${updatedMovement.amount} a currentBalance de destino CC (cupo disponible)."); // DEBUG

                 break;

              default:
                 //print("ADVERTENCIA Update Apply: Tipo de movimiento '${updatedMovement.type}' no manejado para actualización de saldo al actualizar."); // DEBUG
                 // No se actualiza el saldo para tipos no manejados explícitamente.
                 break;
           }
            //print("DEBUG Update Transaction: Aplicación completada."); // DEBUG
           // --- FIN PASO 3 ---


           // --- PASO 4: ACTUALIZAR EL DOCUMENTO DEL MOVIMIENTO ---
           DocumentReference movementRef = _userCollection('expenses').doc(updatedMovement.id); // Colección sigue llamándose 'expenses'
           transaction.set(movementRef, updatedMovement.toFirestore(), SetOptions(merge: true)); // Usar set con merge para actualizar
           //print("DEBUG Update Transaction: Actualizando documento de movimiento ${updatedMovement.id} con nuevos datos."); // DEBUG
           // --- FIN PASO 4 ---


       });

        //print("Transacción de actualizar movimiento y cuentas completada."); // DEBUG
   }


  // --- Métodos para Presupuestos ---
  // ... (saveBudget, getBudgets, getBudgetByMonthYear, deleteBudget - Mantener los anteriores) ...

   Future<void> saveBudget(Budget budget) async {
        if (currentUserId == null) {
           //print("Error: saveBudget llamado sin usuario autenticado."); // DEBUG
           throw StateError("Usuario no autenticado.");
       }
      var options = SetOptions(merge: true);
      // Usamos budget.toFirestore() que ya incluye monthYear, totalBudgeted y categoryBudgets
      return _userCollection('budgets') // <-- Colección 'budgets'
          .doc(budget.id) // Usamos el ID del presupuesto
          .set(budget.toFirestore(), options);
   }

   Stream<List<Budget>> getBudgets() {
        if (currentUserId == null) {
           //print("ADVERTENCIA: getBudgets llamado sin usuario autenticado."); // DEBUG
           return Stream.value([]);
       }
      return _userCollection('budgets') // <-- Colección 'budgets'
          .orderBy('monthYear', descending: true) // Opcional: ordenar por período más reciente
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Budget.fromFirestore(doc)).toList()); // Usamos Budget.fromFirestore()
   }

    Future<Budget?> getBudgetByMonthYear(String monthYear) async {
       if (currentUserId == null) {
           //print("Error: getBudgetByMonthYear llamado sin usuario autenticado."); // DEBUG
           return null;
       }
       try {
           QuerySnapshot snapshot = await _userCollection('budgets') // <-- Colección 'budgets'
               .where('monthYear', isEqualTo: monthYear)
               .limit(1) // Solo esperamos un presupuesto por mes/año por usuario
               .get();

           if (snapshot.docs.isEmpty) {
              return null; // No se encontró presupuesto para ese mes/año
           } else {
              return Budget.fromFirestore(snapshot.docs.first); // Retornar el primer (y único) presupuesto encontrado
           }
       } catch (e) {
           //print("Error fetching budget by month/year: $e"); // DEBUG
           return null;
       }
    }


   Future<void> deleteBudget(String budgetId) async {
       if (currentUserId == null) {
          //print("Error: deleteBudget llamado sin usuario autenticado."); // DEBUG
          throw StateError("Usuario no autenticado.");
       }
      return _userCollection('budgets').doc(budgetId).delete(); // <-- Colección 'budgets'
   }

  // --- Métodos para Deudas ---


   Future<void> saveDebt(Debt debt) async {
       if (currentUserId == null) {
           //print("Error: saveDebt llamado sin usuario autenticado."); // DEBUG
           throw StateError("Usuario no autenticado.");
       }
      var options = SetOptions(merge: true);
      return _userCollection('debts') // <-- Nueva colección 'debts'
          .doc(debt.id)
          .set(debt.toFirestore(), options);
   }

   Stream<List<Debt>> getDebts() {
       if (currentUserId == null) {
           //print("ADVERTENCIA: getDebts llamado sin usuario autenticado."); // DEBUG
           return Stream.value([]);
       }
      return _userCollection('debts') // <-- Colección 'debts'
          .orderBy('creationDate', descending: true) // Ordenar por fecha de creación
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Debt.fromFirestore(doc)).toList());
   }

    Future<Debt?> getDebtById(String debtId) async {
       if (currentUserId == null) {
           //print("Error: getDebtById llamado sin usuario autenticado."); // DEBUG
           return null;
       }
       try {
          DocumentSnapshot doc = await getDocumentById('debts', debtId); // <-- Colección 'debts'
          if (!doc.exists) return null;
          return Debt.fromFirestore(doc);
       } catch (e) {
            //print("Error fetching debt by ID: $e"); // DEBUG
            return null;
       }
    }


   Future<void> deleteDebt(String debtId) async {
       if (currentUserId == null) {
          //print("Error: deleteDebt llamado sin usuario autenticado."); // DEBUG
          throw StateError("Usuario no autenticado.");
       }
       // TODO: Considerar qué hacer con los pagos de deuda asociados a esta deuda.
      return _userCollection('debts').doc(debtId).delete(); // <-- Colección 'debts'
   }

    // Helper function to calculate interest, capital, and insurance portion for a single normal installment.

    Map<String, double> _calculateAmortizationPortions(
        double outstandingBalance, // Saldo pendiente antes de aplicar este pago
        double annualEffectiveRate,
        double installmentValue, // Valor total de la cuota normal
        double insuranceValue // Valor de seguros por cuota
    ) {
        // Convertir tasa efectiva anual a tasa efectiva mensual
        // (1 + i_annual) = (1 + i_monthly)^12
        // i_monthly = (1 + i_annual)^(1/12) - 1
        double monthlyEffectiveRate = annualEffectiveRate > 0
            ? (pow(1 + annualEffectiveRate, 1 / 12) - 1)
            : 0.0;

        // Calcular el interés sobre el saldo pendiente
        double interestPortion = outstandingBalance * monthlyEffectiveRate;

        // Asegurarse de que el interés calculado no sea mayor que el valor de la cuota menos seguros.
        // Esto puede ocurrir si el saldo pendiente es muy bajo.
        double maxInterestPortion = installmentValue - insuranceValue;
        if (interestPortion > maxInterestPortion) {
            interestPortion = maxInterestPortion > 0 ? maxInterestPortion : 0;
        }
         if (interestPortion < 0) interestPortion = 0; // Asegurar que el interés no sea negativo


        // Calcular la porción de capital
        double capitalPortion = installmentValue - interestPortion - insuranceValue;

        // Asegurar que la porción de capital no sea negativa (puede ocurrir con pagos muy pequeños o redondeo)
        if (capitalPortion < 0) capitalPortion = 0;

        // Asegurar que la porción de capital no exceda el saldo pendiente
         if (capitalPortion > outstandingBalance) {
             capitalPortion = outstandingBalance;
             // Ajustar interés si el capital pagado se limitó al saldo pendiente
             interestPortion = installmentValue - capitalPortion - insuranceValue;
             if (interestPortion < 0) interestPortion = 0; // Asegurar que el interés ajustado no sea negativo
             insuranceValue = installmentValue - capitalPortion - interestPortion; // Ajustar seguro también por si acaso
             if (insuranceValue < 0) insuranceValue = 0;
         }


        return {
            'capital': capitalPortion,
            'interest': interestPortion,
            'insurance': insuranceValue,

        };




    }


   // --- Método para añadir un pago a una deuda con lógica de amortización ---
   Future<void> addDebtPayment(String debtId, Map<String, dynamic> paymentData, double paymentAmount) async {
       if (currentUserId == null) {
           //print("Error: addDebtPayment llamado sin usuario autenticado."); // DEBUG
           throw StateError("Usuario no autenticado.");
       }

       DocumentReference debtRef = _userCollection('debts').doc(debtId);

       await _db.runTransaction((Transaction transaction) async {
           DocumentSnapshot debtSnapshot = await transaction.get(debtRef);

           if (!debtSnapshot.exists || debtSnapshot.data() == null) {
               //print("Error de transacción: La deuda con ID $debtId no existe."); // DEBUG
               throw Exception("La deuda no fue encontrada.");
           }

           Debt debt = Debt.fromFirestore(debtSnapshot);

           // 1. Crear una copia mutable del historial existente y añadir el nuevo pago
           List<Map<String, dynamic>> updatedPaymentHistory = List.from(debt.paymentHistory ?? []); // Copiar historial existente o crear lista vacía
           Map<String, dynamic> paymentToAdd = Map.from(paymentData); // Copia mutable del nuevo pago

           // Añadir el nuevo pago a la lista
           updatedPaymentHistory.add(paymentToAdd);

           // --- MODIFICADO: Recalcular currentAmount y interestPaid iterando el historial COMPLETO y ORDENADO ---
           // Ordenar el historial por fecha para aplicar los pagos en orden cronológico
           updatedPaymentHistory.sort((a, b) {
               Timestamp dateA = a['date'];
               Timestamp dateB = b['date'];
               return dateA.compareTo(dateB);
           });

           double recalculatedCurrentAmount = debt.initialAmount;
           double recalculatedInterestPaid = 0.0;
           int recalculatedPaidInstallments = 0;

           // Lista para guardar el historial con los desgloses recalculados
           List<Map<String, dynamic>> finalPaymentHistory = [];

           //print("\n[DEBUG-AMORTIZACION] initialAmount (NO SE TOCA): "+debt.initialAmount.toString());
           //print("[DEBUG-AMORTIZACION] currentAmount (Monto Restante antes de pagos): "+debt.currentAmount.toString());
           //print("[DEBUG-AMORTIZACION] --- INICIO RECALCULO PAGOS ---");
           for (var payment in updatedPaymentHistory) {
               Map<String, dynamic> currentPayment = Map.from(payment); // Copia mutable para modificar el desglose
               double paidAmount = (currentPayment['amount'] as num?)?.toDouble() ?? 0.0;
               String paymentType = (currentPayment['paymentType'] as String? ?? 'normal');

               //print("\n[DEBUG-AMORTIZACION] Procesando pago. Tipo: $paymentType, Monto: $paidAmount, Fecha: "+(currentPayment['date']?.toString() ?? 'null'));
               //print("[DEBUG-AMORTIZACION] Saldo previo al pago (currentAmount): $recalculatedCurrentAmount");

               if (paymentType == 'normal') {
                   // Para pagos normales, recalcular el desglose basado en el saldo actual
                   // --- CORRECCIÓN: Asegurar que la tasa anual se use como decimal ---
                   double annualRateDecimal = debt.annualEffectiveInterestRate!;
                   if (annualRateDecimal > 1.0) {
                       //print("ADVERTENCIA: annualEffectiveInterestRate > 1. Corrigiendo de ${annualRateDecimal} a ${annualRateDecimal / 100.0}");
                       annualRateDecimal = annualRateDecimal / 100.0;
                   }
                   Map<String, double> portions = _calculateAmortizationPortions(
                       recalculatedCurrentAmount, // Usar el saldo acumulado hasta el pago anterior
                       annualRateDecimal,
                       (currentPayment['amount'] as num?)?.toDouble() ?? 0.0, // Usar el monto del pago
                       debt.insuranceValue! // Usar el valor de seguro de la deuda
                   );

                    //print("[DEBUG-AMORTIZACION] Pago NORMAL: Capital a restar: "+portions['capital'].toString()+", Interés: "+portions['interest'].toString()+", Seguro: "+portions['insurance'].toString());
                    recalculatedCurrentAmount -= portions['capital']!;
                    //print("[DEBUG-AMORTIZACION] Saldo después de pago NORMAL (currentAmount): $recalculatedCurrentAmount");

                   // Ajustar el desglose si el monto del pago real es diferente al valor de cuota esperado
                   double actualPaymentAmount = (currentPayment['amount'] as num?)?.toDouble() ?? 0.0;
                   double calculatedTotal = portions['capital']! + portions['interest']! + portions['insurance']!;

                   if ((actualPaymentAmount - calculatedTotal).abs() > 0.01) { // Permitir pequeña tolerancia por redondeo
                        //print("ADVERTENCIA Recalculate (Add): Monto de pago normal (${actualPaymentAmount}) difiere del valor de cuota calculado (${calculatedTotal}). Ajustando porciones."); // DEBUG
                        double difference = actualPaymentAmount - calculatedTotal;
                        // Distribuir la diferencia, por ejemplo, ajustando capital e interés proporcionalmente
                        double totalPrincipalInterest = (portions['capital'] ?? 0.0) + (portions['interest'] ?? 0.0);
                        if (totalPrincipalInterest > 0) {
                            double capitalRatio = (portions['capital'] ?? 0.0) / totalPrincipalInterest;
                            double interestRatio = (portions['interest'] ?? 0.0) / totalPrincipalInterest;
                            portions['capital'] = (portions['capital'] ?? 0.0) + difference * capitalRatio;
                            portions['interest'] = (portions['interest'] ?? 0.0) + difference * interestRatio;
                        } else {
                            // Si no hay capital ni interés (ej. solo seguros), añadir la diferencia al capital
                            portions['capital'] = (portions['capital'] ?? 0.0) + difference;
                        }
                        //print("DEBUG [Pago-Normal]: Porciones ajustadas: capital=${portions['capital']}, interes=${portions['interest']}, seguro=${portions['insurance']}");
                    }
                    // Asegurar que el capital ajustado no sea negativo ni mayor que el saldo pendiente
                    if (portions['capital']! < 0) portions['capital'] = 0.0;
                    if (portions['capital']! > recalculatedCurrentAmount) {
                        portions['capital'] = recalculatedCurrentAmount;
                        // Recalcular interés y seguro si el capital se limitó
                        portions['interest'] = actualPaymentAmount - portions['capital']! - (portions['insurance'] ?? 0.0);
                        if (portions['interest']! < 0) portions['interest'] = 0.0;
                        portions['insurance'] = actualPaymentAmount - portions['capital']! - portions['interest']!;
                        if (portions['insurance']! < 0) portions['insurance'] = 0.0;
                    }
                    // Asegurar que el interés ajustado no sea negativo
                    if (portions['interest']! < 0) portions['interest'] = 0.0;

                   //print("DEBUG [Pago-Normal]: Porciones finales: capital=${portions['capital']}, interes=${portions['interest']}, seguro=${portions['insurance']}");

                   currentPayment['capital_paid'] = portions['capital'];
                   currentPayment['interest_paid'] = portions['interest'];
                   currentPayment['insurance_paid'] = portions['insurance'];                   //print("DEBUG Recalculate (Add): Pago Normal. Desglose recalculado y ajustado: Capital=${currentPayment['capital_paid']}, Interés=${currentPayment['interest_paid']}, Seguro=${currentPayment['insurance_paid']}"); // DEBUG
               } else if (paymentType == 'abono_capital') { // Asumiendo 'abono_capital' como otro tipo
                   // Para abonos a capital, el monto total reduce el capital directamente
                   currentPayment['capital_paid'] = paidAmount; // Guardar también en el historial para consistencia
                   currentPayment['interest_paid'] = 0.0;
                   currentPayment['insurance_paid'] = 0.0;
                   recalculatedCurrentAmount -= paidAmount;
                    //print("DEBUG Recalculate (Add): Abono a Capital. Monto pagado: $paidAmount. Nuevo Saldo: $recalculatedCurrentAmount"); // DEBUG

               } else {
                    // Otros tipos de pago que no afectan capital ni interés acumulado de la deuda principal
                    currentPayment['capital_paid'] = 0.0; // Asegurar que estos campos existen aunque sean 0
                    currentPayment['interest_paid'] = 0.0;
                    currentPayment['insurance_paid'] = 0.0;
                    //print("DEBUG Recalculate (Add): Pago tipo '$paymentType' no afecta saldo/interés acumulado."); // DEBUG
               }

               // Asegurar que el saldo no sea negativo
               if (recalculatedCurrentAmount < 0) recalculatedCurrentAmount = 0;
               //print("DEBUG [Pago]: Historial parcial tras este pago: $finalPaymentHistory");
               finalPaymentHistory.add(currentPayment); // Añadir el pago (con el desglose recalculado si es normal) a la lista final
           }
           //print("[DEBUG-AMORTIZACION] --- FIN RECALCULO PAGOS ---");
           //print("[DEBUG-AMORTIZACION] Saldo final (currentAmount) tras todos los pagos: $recalculatedCurrentAmount");
           // 4. Actualizar el documento de la deuda en Firestore
           transaction.update(debtRef, {
               'currentAmount': recalculatedCurrentAmount, // Usar el saldo recalculado
               'paymentHistory': finalPaymentHistory, // Guardar la lista actualizada con desglose recalculado
               'paidInstallments': recalculatedPaidInstallments, // Guardar cuotas pagadas (recalculado)
               'interestPaid': recalculatedInterestPaid, // --- NUEVO: Guardar interés acumulado ---
               // Puedes añadir lógica para actualizar el estado a 'paid' si newCurrentAmount es 0
               if (recalculatedCurrentAmount <= 0 && debt.status != 'paid') 'status': 'paid', // Marcar como pagada si el saldo es 0 o menos
           });

       });

       //print("Transacción de añadir pago de deuda con amortización y actualizar deuda completada."); // DEBUG
   }

   // --- Método: Actualizar un pago específico en el historial de una deuda con lógica de amortización ---
   Future<void> updateDebtPayment(String debtId, int paymentIndex, double originalPaymentAmount, Map<String, dynamic> updatedPaymentData) async {
       if (currentUserId == null) {
           //print("Error: updateDebtPayment llamado sin usuario autenticado."); // DEBUG
           throw StateError("Usuario no autenticado.");
       }

       DocumentReference debtRef = _userCollection('debts').doc(debtId);

       await _db.runTransaction((Transaction transaction) async {
           DocumentSnapshot debtSnapshot = await transaction.get(debtRef);

           if (!debtSnapshot.exists || debtSnapshot.data() == null) {
               //print("Error de transacción: La deuda con ID $debtId no existe."); // DEBUG
               throw Exception("La deuda no fue encontrada.");
           }

           Debt debt = Debt.fromFirestore(debtSnapshot);

           // Asegurarse de que el índice del pago es válido
           if (debt.paymentHistory == null || paymentIndex < 0 || paymentIndex >= debt.paymentHistory!.length) {
               //print("Error de transacción: Índice de pago inválido ($paymentIndex) para la deuda $debtId."); // DEBUG
               throw ArgumentError("Invalid payment index.");
           }

           // Crear una copia mutable del historial de pagos
           List<Map<String, dynamic>> updatedPaymentHistory = List.from(debt.paymentHistory!);

           // Reemplazar el pago original con los datos actualizados
           updatedPaymentHistory[paymentIndex] = Map.from(updatedPaymentData); // Usar copia mutable


           // --- MODIFICADO: Recalcular currentAmount y interestPaid iterando el historial COMPLETO y ORDENADO ---
           // Ordenar el historial por fecha para aplicar los pagos en orden cronológico
           // Esto es CRUCIAL para que la amortización se calcule correctamente después de una edición.
           updatedPaymentHistory.sort((a, b) {
               Timestamp dateA = a['date'];
               Timestamp dateB = b['date'];
               return dateA.compareTo(dateB);
           });

           double recalculatedCurrentAmount = debt.initialAmount;
           double recalculatedInterestPaid = 0.0;
           int recalculatedPaidInstallments = 0;

            // Lista para guardar el historial con los desgloses recalculados
           List<Map<String, dynamic>> finalPaymentHistory = [];


           //print("\n[DEBUG-AMORTIZACION] initialAmount (NO SE TOCA): "+debt.initialAmount.toString());
           //print("[DEBUG-AMORTIZACION] currentAmount (Monto Restante antes de pagos): "+debt.currentAmount.toString());
           //print("[DEBUG-AMORTIZACION] --- INICIO RECALCULO PAGOS ---");
           for (var payment in updatedPaymentHistory) {
               Map<String, dynamic> currentPayment = Map.from(payment); // Copia mutable para modificar el desglose
               double paidAmount = (currentPayment['amount'] as num?)?.toDouble() ?? 0.0;
               String paymentType = (currentPayment['paymentType'] as String? ?? 'normal');

               //print("\n[DEBUG-AMORTIZACION] Procesando pago. Tipo: $paymentType, Monto: $paidAmount, Fecha: "+(currentPayment['date']?.toString() ?? 'null'));
               //print("[DEBUG-AMORTIZACION] Saldo previo al pago (currentAmount): $recalculatedCurrentAmount");

               if (paymentType == 'normal') {
                   // Para pagos normales, recalcular el desglose basado en el saldo actual
                   // --- CORRECCIÓN: Asegurar que la tasa anual se use como decimal ---
                   double annualRateDecimal = debt.annualEffectiveInterestRate!;
                   if (annualRateDecimal > 1.0) {
                       //print("ADVERTENCIA: annualEffectiveInterestRate > 1. Corrigiendo de ${annualRateDecimal} a ${annualRateDecimal / 100.0}");
                       annualRateDecimal = annualRateDecimal / 100.0;
                   }
                   Map<String, double> portions = _calculateAmortizationPortions(
                       recalculatedCurrentAmount, // Usar el saldo acumulado hasta el pago anterior
                       annualRateDecimal,
                       (currentPayment['amount'] as num?)?.toDouble() ?? 0.0, // Usar el monto del pago
                       debt.insuranceValue! // Usar el valor de seguro de la deuda
                   );

                    //print("[DEBUG-AMORTIZACION] Pago NORMAL: Capital a restar: "+portions['capital'].toString()+", Interés: "+portions['interest'].toString()+", Seguro: "+portions['insurance'].toString());
                    recalculatedCurrentAmount -= portions['capital']!;
                    //print("[DEBUG-AMORTIZACION] Saldo después de pago NORMAL (currentAmount): $recalculatedCurrentAmount");

                   // Ajustar el desglose si el monto del pago real es diferente al valor de cuota esperado
                   double actualPaymentAmount = (currentPayment['amount'] as num?)?.toDouble() ?? 0.0;
                   double calculatedTotal = portions['capital']! + portions['interest']! + portions['insurance']!;

                   if ((actualPaymentAmount - calculatedTotal).abs() > 0.01) { // Permitir pequeña tolerancia por redondeo
                        //print("ADVERTENCIA Recalculate (Add): Monto de pago normal (${actualPaymentAmount}) difiere del valor de cuota calculado (${calculatedTotal}). Ajustando porciones."); // DEBUG
                        double difference = actualPaymentAmount - calculatedTotal;
                        // Distribuir la diferencia, por ejemplo, ajustando capital e interés proporcionalmente
                        double totalPrincipalInterest = (portions['capital'] ?? 0.0) + (portions['interest'] ?? 0.0);
                        if (totalPrincipalInterest > 0) {
                            double capitalRatio = (portions['capital'] ?? 0.0) / totalPrincipalInterest;
                            double interestRatio = (portions['interest'] ?? 0.0) / totalPrincipalInterest;
                            portions['capital'] = (portions['capital'] ?? 0.0) + difference * capitalRatio;
                            portions['interest'] = (portions['interest'] ?? 0.0) + difference * interestRatio;
                        } else {
                            // Si no hay capital ni interés (ej. solo seguros), añadir la diferencia al capital
                            portions['capital'] = (portions['capital'] ?? 0.0) + difference;
                        }
                        //print("DEBUG [Pago-Normal]: Porciones ajustadas: capital=${portions['capital']}, interes=${portions['interest']}, seguro=${portions['insurance']}");
                    }
                    // Asegurar que el capital ajustado no sea negativo ni mayor que el saldo pendiente
                    if (portions['capital']! < 0) portions['capital'] = 0.0;
                    if (portions['capital']! > recalculatedCurrentAmount) {
                        portions['capital'] = recalculatedCurrentAmount;
                        // Recalcular interés y seguro si el capital se limitó
                        portions['interest'] = actualPaymentAmount - portions['capital']! - (portions['insurance'] ?? 0.0);
                        if (portions['interest']! < 0) portions['interest'] = 0.0;
                        portions['insurance'] = actualPaymentAmount - portions['capital']! - portions['interest']!;
                        if (portions['insurance']! < 0) portions['insurance'] = 0.0;
                    }
                    // Asegurar que el interés ajustado no sea negativo
                    if (portions['interest']! < 0) portions['interest'] = 0.0;

                   //print("DEBUG [Pago-Normal]: Porciones finales: capital=${portions['capital']}, interes=${portions['interest']}, seguro=${portions['insurance']}");

                   currentPayment['capital_paid'] = portions['capital'];
                   currentPayment['interest_paid'] = portions['interest'];
                   currentPayment['insurance_paid'] = portions['insurance'];
                   //print("DEBUG Recalculate (Add): Pago Normal. Desglose recalculado y ajustado: Capital=${currentPayment['capital_paid']}, Interés=${currentPayment['interest_paid']}, Seguro=${currentPayment['insurance_paid']}"); // DEBUG
                   // --- FIX: Restar solo el capital al saldo pendiente ---
                   recalculatedCurrentAmount -= portions['capital']!;
                   //print("DEBUG Recalculate (Add): Pago Normal. Nuevo saldo tras restar capital: $recalculatedCurrentAmount"); // DEBUG
              
               } else if (paymentType == 'abono_capital') { // Asumiendo 'abono_capital' como otro tipo
                   // Para abonos a capital, el monto total reduce el capital directamente
                   currentPayment['capital_paid'] = paidAmount; // Guardar también en el historial para consistencia
                   currentPayment['interest_paid'] = 0.0;
                   currentPayment['insurance_paid'] = 0.0;
                   recalculatedCurrentAmount -= paidAmount;
                    //print("DEBUG Recalculate (Add): Abono a Capital. Monto pagado: $paidAmount. Nuevo Saldo: $recalculatedCurrentAmount"); // DEBUG

               } else {
                    // Otros tipos de pago que no afectan capital ni interés acumulado de la deuda principal
                    currentPayment['capital_paid'] = 0.0; // Asegurar que estos campos existen aunque sean 0
                    currentPayment['interest_paid'] = 0.0;
                    currentPayment['insurance_paid'] = 0.0;
                    //print("DEBUG Recalculate (Add): Pago tipo '$paymentType' no afecta saldo/interés acumulado."); // DEBUG
               }

               // Asegurar que el saldo no sea negativo
               if (recalculatedCurrentAmount < 0) recalculatedCurrentAmount = 0;
               //print("DEBUG [Pago]: Historial parcial tras este pago: $finalPaymentHistory");
               finalPaymentHistory.add(currentPayment); // Añadir el pago (con el desglose recalculado si es normal) a la lista final
           }
           //print("[DEBUG-AMORTIZACION] --- FIN RECALCULO PAGOS ---");
           //print("[DEBUG-AMORTIZACION] Saldo final (currentAmount) tras todos los pagos: $recalculatedCurrentAmount");
           // 3. Actualizar el documento de la deuda en Firestore
           transaction.update(debtRef, {
               'currentAmount': recalculatedCurrentAmount, // Usar el saldo recalculado
               'paymentHistory': finalPaymentHistory, // Guardar la lista actualizada con desglose recalculado
               'paidInstallments': recalculatedPaidInstallments, // Guardar cuotas pagadas (recalculado)
               'interestPaid': recalculatedInterestPaid, // --- NUEVO: Guardar interés acumulado ---
               // Puedes añadir lógica para actualizar el estado
                // Si el monto restante es > 0 y el estado era 'paid', cambiarlo a 'active'
               if (recalculatedCurrentAmount > 0 && debt.status == 'paid') 'status': 'active',
               // Si el monto restante es <= 0 && el estado no era 'paid', cambiarlo a 'paid'
               if (recalculatedCurrentAmount <= 0 && debt.status != 'paid') 'status': 'paid',
           });

       });

       //print("Transacción de actualizar pago de deuda con amortización y deuda completada."); // DEBUG
   }

   // --- NUEVO MÉTODO: Eliminar un pago específico del historial de una deuda con lógica de amortización ---
   Future<void> deleteDebtPayment(String debtId, int paymentIndex) async {
       if (currentUserId == null) {
           //print("Error: deleteDebtPayment llamado sin usuario autenticado."); // DEBUG
           throw StateError("Usuario no autenticado.");
       }

       DocumentReference debtRef = _userCollection('debts').doc(debtId);

       await _db.runTransaction((Transaction transaction) async {
           DocumentSnapshot debtSnapshot = await transaction.get(debtRef);

           if (!debtSnapshot.exists || debtSnapshot.data() == null) {
               //print("Error de transacción: La deuda con ID $debtId no existe."); // DEBUG
               throw Exception("La deuda no fue encontrada.");
           }

           Debt debt = Debt.fromFirestore(debtSnapshot);

           // Asegurarse de que el historial de pagos existe y el índice es válido
           if (debt.paymentHistory == null || paymentIndex < 0 || paymentIndex >= debt.paymentHistory!.length) {
               //print("Error de transacción: Índice de pago inválido ($paymentIndex) para la deuda $debtId."); // DEBUG
               throw ArgumentError("Invalid payment index.");
           }

           // Crear una copia mutable del historial de pagos
           List<Map<String, dynamic>> updatedPaymentHistory = List.from(debt.paymentHistory!);

           // Eliminar el pago específico de la lista
           updatedPaymentHistory.removeAt(paymentIndex);

           // --- MODIFICADO: Recalcular currentAmount y interestPaid iterando el historial COMPLETO y ORDENADO ---
           // Ordenar el historial por fecha para aplicar los pagos en orden cronológico
           // Esto es CRUCIAL para que la amortización se calcule correctamente después de una eliminación.
           updatedPaymentHistory.sort((a, b) {
               Timestamp dateA = a['date'];
               Timestamp dateB = b['date'];
               return dateA.compareTo(dateB);
           });

           double recalculatedCurrentAmount = debt.initialAmount;
           double recalculatedInterestPaid = 0.0;
           int recalculatedPaidInstallments = 0;

           // Lista para guardar el historial con los desgloses recalculados
           List<Map<String, dynamic>> finalPaymentHistory = [];

           //print("\n[DEBUG-AMORTIZACION] initialAmount (NO SE TOCA): "+debt.initialAmount.toString());
           //print("[DEBUG-AMORTIZACION] currentAmount (Monto Restante antes de pagos): "+debt.currentAmount.toString());
           //print("[DEBUG-AMORTIZACION] --- INICIO RECALCULO PAGOS ---");
           for (var payment in updatedPaymentHistory) {
               Map<String, dynamic> currentPayment = Map.from(payment); // Copia mutable para modificar el desglose
               double paidAmount = (currentPayment['amount'] as num?)?.toDouble() ?? 0.0;
               String paymentType = (currentPayment['paymentType'] as String? ?? 'normal');

               //print("\n[DEBUG-AMORTIZACION] Procesando pago. Tipo: $paymentType, Monto: $paidAmount, Fecha: "+(currentPayment['date']?.toString() ?? 'null'));
               //print("[DEBUG-AMORTIZACION] Saldo previo al pago (currentAmount): $recalculatedCurrentAmount");

               if (paymentType == 'normal') {
                   // Para pagos normales, recalcular el desglose basado en el saldo actual
                   // --- CORRECCIÓN: Asegurar que la tasa anual se use como decimal ---
                   double annualRateDecimal = debt.annualEffectiveInterestRate!;
                   if (annualRateDecimal > 1.0) {
                       //print("ADVERTENCIA: annualEffectiveInterestRate > 1. Corrigiendo de ${annualRateDecimal} a ${annualRateDecimal / 100.0}");
                       annualRateDecimal = annualRateDecimal / 100.0;
                   }
                   Map<String, double> portions = _calculateAmortizationPortions(
                       recalculatedCurrentAmount, // Usar el saldo acumulado hasta el pago anterior
                       annualRateDecimal,
                       (currentPayment['amount'] as num?)?.toDouble() ?? 0.0, // Usar el monto del pago
                       debt.insuranceValue! // Usar el valor de seguro de la deuda
                   );

                    //print("[DEBUG-AMORTIZACION] Pago NORMAL: Capital a restar: "+portions['capital'].toString()+", Interés: "+portions['interest'].toString()+", Seguro: "+portions['insurance'].toString());
                    recalculatedCurrentAmount -= portions['capital']!;
                    //print("[DEBUG-AMORTIZACION] Saldo después de pago NORMAL (currentAmount): $recalculatedCurrentAmount");

                   // Ajustar el desglose si el monto del pago real es diferente al valor de cuota esperado
                   double actualPaymentAmount = (currentPayment['amount'] as num?)?.toDouble() ?? 0.0;
                   double calculatedTotal = portions['capital']! + portions['interest']! + portions['insurance']!;

                   if ((actualPaymentAmount - calculatedTotal).abs() > 0.01) { // Permitir pequeña tolerancia por redondeo
                        //print("ADVERTENCIA Recalculate (Add): Monto de pago normal (${actualPaymentAmount}) difiere del valor de cuota calculado (${calculatedTotal}). Ajustando porciones."); // DEBUG
                        double difference = actualPaymentAmount - calculatedTotal;
                        // Distribuir la diferencia, por ejemplo, ajustando capital e interés proporcionalmente
                        double totalPrincipalInterest = (portions['capital'] ?? 0.0) + (portions['interest'] ?? 0.0);
                        if (totalPrincipalInterest > 0) {
                            double capitalRatio = (portions['capital'] ?? 0.0) / totalPrincipalInterest;
                            double interestRatio = (portions['interest'] ?? 0.0) / totalPrincipalInterest;
                            portions['capital'] = (portions['capital'] ?? 0.0) + difference * capitalRatio;
                            portions['interest'] = (portions['interest'] ?? 0.0) + difference * interestRatio;
                        } else {
                            // Si no hay capital ni interés (ej. solo seguros), añadir la diferencia al capital
                            portions['capital'] = (portions['capital'] ?? 0.0) + difference;
                        }
                        //print("DEBUG [Pago-Normal]: Porciones ajustadas: capital=${portions['capital']}, interes=${portions['interest']}, seguro=${portions['insurance']}");
                    }
                    // Asegurar que el capital ajustado no sea negativo ni mayor que el saldo pendiente
                    if (portions['capital']! < 0) portions['capital'] = 0.0;
                    if (portions['capital']! > recalculatedCurrentAmount) {
                        portions['capital'] = recalculatedCurrentAmount;
                        // Recalcular interés y seguro si el capital se limitó
                        portions['interest'] = actualPaymentAmount - portions['capital']! - (portions['insurance'] ?? 0.0);
                        if (portions['interest']! < 0) portions['interest'] = 0.0;
                        portions['insurance'] = actualPaymentAmount - portions['capital']! - portions['interest']!;
                        if (portions['insurance']! < 0) portions['insurance'] = 0.0;
                    }
                    // Asegurar que el interés ajustado no sea negativo
                    if (portions['interest']! < 0) portions['interest'] = 0.0;

                   //print("DEBUG [Pago-Normal]: Porciones finales: capital=${portions['capital']}, interes=${portions['interest']}, seguro=${portions['insurance']}");

                   currentPayment['capital_paid'] = portions['capital'];
                   currentPayment['interest_paid'] = portions['interest'];
                   currentPayment['insurance_paid'] = portions['insurance'];
                   //print("DEBUG Recalculate (Add): Pago Normal. Desglose recalculado y ajustado: Capital=${currentPayment['capital_paid']}, Interés=${currentPayment['interest_paid']}, Seguro=${currentPayment['insurance_paid']}"); // DEBUG
                   // --- FIX: Restar solo el capital al saldo pendiente ---
                   recalculatedCurrentAmount -= portions['capital']!;
                   //print("DEBUG Recalculate (Add): Pago Normal. Nuevo saldo tras restar capital: $recalculatedCurrentAmount"); // DEBUG
               } else if (paymentType == 'abono_capital') { // Asumiendo 'abono_capital' como otro tipo
                   // Para abonos a capital, el monto total reduce el capital directamente
                   currentPayment['capital_paid'] = paidAmount; // Guardar también en el historial para consistencia
                   currentPayment['interest_paid'] = 0.0;
                   currentPayment['insurance_paid'] = 0.0;
                   recalculatedCurrentAmount -= paidAmount;
                    //print("DEBUG Recalculate (Add): Abono a Capital. Monto pagado: $paidAmount. Nuevo Saldo: $recalculatedCurrentAmount"); // DEBUG

               } else {
                    // Otros tipos de pago que no afectan capital ni interés acumulado de la deuda principal
                    currentPayment['capital_paid'] = 0.0; // Asegurar que estos campos existen aunque sean 0
                    currentPayment['interest_paid'] = 0.0;
                    currentPayment['insurance_paid'] = 0.0;
                    //print("DEBUG Recalculate (Add): Pago tipo '$paymentType' no afecta saldo/interés acumulado."); // DEBUG
               }

               // Asegurar que el saldo no sea negativo
               if (recalculatedCurrentAmount < 0) recalculatedCurrentAmount = 0;
               //print("DEBUG [Pago]: Historial parcial tras este pago: $finalPaymentHistory");
               finalPaymentHistory.add(currentPayment); // Añadir el pago (con el desglose recalculado si es normal) a la lista final
           }
           //print("[DEBUG-AMORTIZACION] --- FIN RECALCULO PAGOS ---");
           //print("[DEBUG-AMORTIZACION] Saldo final (currentAmount) tras todos los pagos: $recalculatedCurrentAmount");
           // 3. Actualizar el documento de la deuda en Firestore
           transaction.update(debtRef, {
               'currentAmount': recalculatedCurrentAmount, // Usar el saldo recalculado
               'paymentHistory': finalPaymentHistory, // Guardar la lista actualizada con desglose recalculado
               'paidInstallments': recalculatedPaidInstallments, // Guardar cuotas pagadas (recalculado)
               'interestPaid': recalculatedInterestPaid, // --- NUEVO: Guardar interés acumulado ---
               // Puedes añadir lógica para actualizar el estado
                // Si el monto restante es > 0 y el estado era 'paid', cambiarlo a 'active'
               if (recalculatedCurrentAmount > 0 && debt.status == 'paid') 'status': 'active',
               // Si el monto restante es <= 0 && el estado no era 'paid', cambiarlo a 'paid'
               if (recalculatedCurrentAmount <= 0 && debt.status != 'paid') 'status': 'paid',
           });

       });

       //print("Transacción de eliminar pago de deuda y actualizar deuda completada."); // DEBUG
   }


  // --- Métodos para Inversiones ---
  // ... (saveInvestment, getInvestments, getInvestmentById, deleteInvestment - Mantener los anteriores) ...

    Future<void> saveInvestment(Investment investment) async {
       if (currentUserId == null) {
           //print("Error: saveInvestment llamado sin usuario autenticado."); // DEBUG
           throw StateError("Usuario no autenticado.");
       }
      var options = SetOptions(merge: true);
      // Usamos investment.toFirestore() que ya incluye totalQuantity y history
      return _userCollection('investments') // <-- Colección 'investments'
          .doc(investment.id)
          .set(investment.toFirestore(), options);
   }

   Stream<List<Investment>> getInvestments() {
        if (currentUserId == null) {
           //print("ADVERTENCIA: getInvestments llamado sin usuario autenticado."); // DEBUG
           return Stream.value([]);
       }
      return _userCollection('investments') // <-- Colección 'investments'
          .orderBy('startDate', descending: true) // Opcional: ordenar por fecha de inicio
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Investment.fromFirestore(doc)).toList()); // Usamos Investment.fromFirestore() que ya lee totalQuantity y history
   }

    Future<Investment?> getInvestmentById(String investmentId) async {
       if (currentUserId == null) {
           //print("Error: getInvestmentById llamado sin usuario autenticado."); // DEBUG
           return null;
       }
        try {
           DocumentSnapshot doc = await getDocumentById('investments', investmentId); // <-- Colección 'investments'
           if (!doc.exists) return null;
           return Investment.fromFirestore(doc); // Usamos Investment.fromFirestore()
        } catch (e) {
             //print("Error fetching investment by ID: $e"); // DEBUG
             return null;
        }
    }


   Future<void> deleteInvestment(String investmentId) async {
       if (currentUserId == null) {
          //print("Error: deleteInvestment llamado sin usuario autenticado."); // DEBUG
          throw StateError("Usuario no autenticado.");
       }
       // TODO: Considerar qué hacer con los movimientos de historial asociados a esta inversión.
      return _userCollection('investments').doc(investmentId).delete(); // <-- Colección 'investments'
   }

   // --- Métodos relacionados con Intereses (Opcional aquí o en lógica de negocio) ---
   // ... (getYieldBearingAccounts - Mantener el anterior si lo añadiste) ...

   Stream<List<Account>> getYieldBearingAccounts() {
       if (currentUserId == null) {
           //print("ADVERTENCIA: getYieldBearingAccounts llamado sin usuario autenticado."); // DEBUG
           return Stream.value([]);
       }
       return _userCollection('accounts')
           .where('yieldRate', isGreaterThan: 0) // Filtrar por tasa mayor a 0
           .snapshots()
           .map((snapshot) => snapshot.docs.map((doc) => Account.fromFirestore(doc)).toList());
   }
  // Método para obtener movimientos por ID de cuenta (origen o destino)
  Stream<List<Movement>> getMovementsByAccountId(String accountId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //print("ADVERTENCIA: getMovementsByAccountId llamado sin usuario autenticado."); // DEBUG
      return Stream.value([]);
    }

    // Consulta para movimientos donde la cuenta es la cuenta de origen
    Stream<List<Movement>> sourceMovements = _db
        .collection('users')
        .doc(user.uid)
        .collection('expenses') // Asume que 'expenses' es la colección de movimientos
        .where('accountId', isEqualTo: accountId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Movement.fromFirestore(doc)).toList());

    // Consulta para movimientos donde la cuenta es la cuenta de destino (solo para transferencias y pagos)
    // Es importante que destinationAccountId exista para evitar errores de consulta en Firestore
    Stream<List<Movement>> destinationMovements = _db
        .collection('users')
        .doc(user.uid)
        .collection('expenses') // Asume que 'expenses' es la colección de movimientos
        .where('destinationAccountId', isEqualTo: accountId)
        // Opcional: Filtrar por tipos que usan destinationAccountId si es necesario,
        // aunque la consulta por destinationAccountId ya debería ser suficiente si solo esos tipos lo usan.
        // .where('type', whereIn: ['transfer', 'payment'])
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Movement.fromFirestore(doc)).toList());


    // Combinar los dos streams
    // Usamos combineLatest para obtener el último valor de ambos streams y combinarlos.
    // Esto asegura que cuando cualquiera de los streams emita un nuevo valor,
    // la lista combinada se actualizará.
    return Rx.combineLatest2(
      sourceMovements,
      destinationMovements,
      (List<Movement> sourceList, List<Movement> destinationList) {
        // Combinar las dos listas y eliminar duplicados (aunque no debería haberlos por diseño, es buena práctica)
        // Usamos un Set para eliminar duplicados basados en el ID del movimiento
        Set<String> movementIds = {};
        List<Movement> combinedList = [];

        for (var movement in sourceList) {
          if (!movementIds.contains(movement.id)) {
            combinedList.add(movement);
            movementIds.add(movement.id!);
          }
        }
         for (var movement in destinationList) {
           if (!movementIds.contains(movement.id)) {
             combinedList.add(movement);
             movementIds.add(movement.id!);
           }
         }


        // Opcional: Ordenar la lista combinada por fecha descendente
        combinedList.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        return combinedList;
      },
    );
  }

} // Fin de la clase FirestoreService
*/