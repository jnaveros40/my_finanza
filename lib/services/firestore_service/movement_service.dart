import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/movement.dart';
import '../../models/account.dart';
import 'base_firestore_service.dart';
import '../notification_manager.dart';

/// Servicio especializado para operaciones de movimientos y actualización de cuentas
class MovementService extends BaseFirestoreService {
  /// Añadir un movimiento y actualizar el saldo de la(s) cuenta(s) de forma atómica
  static Future<void> addMovementAndUpdateAccount(Movement movement) async {
    if (BaseFirestoreService.currentUserId == null) {
      throw StateError("Usuario no autenticado.");
    }
    if (movement.id != null) {
      throw ArgumentError("Cannot add a movement that already has an ID. Use updateMovementAndAccount instead.");
    }
    if (movement.type == 'transfer' && movement.destinationAccountId == null) {
      throw ArgumentError("Transfer movements require a destinationAccountId.");
    }
    if (movement.type == 'transfer' && movement.accountId == movement.destinationAccountId) {
      throw ArgumentError("Source and destination accounts for a transfer cannot be the same.");
    }
    if (movement.type == 'payment' && movement.destinationAccountId == null) {
      throw ArgumentError("Payment movements require a destinationAccountId (the credit card being paid).");
    }

    await BaseFirestoreService.db.runTransaction((Transaction transaction) async {
      // Referencia y snapshot de la cuenta de origen
      DocumentReference sourceAccountRef = BaseFirestoreService.userCollection('accounts').doc(movement.accountId);
      DocumentSnapshot sourceAccountSnapshot = await transaction.get(sourceAccountRef);
      if (!sourceAccountSnapshot.exists || sourceAccountSnapshot.data() == null) {
        throw Exception("La cuenta de origen no fue encontrada.");
      }
      Account sourceAccount = Account.fromFirestore(sourceAccountSnapshot);

      // Referencia y snapshot de la cuenta de destino si aplica
      DocumentReference? destinationAccountRef;
      DocumentSnapshot? destinationAccountSnapshot;
      Account? destinationAccount;
      if (movement.type == 'transfer' || movement.type == 'payment') {
        destinationAccountRef = BaseFirestoreService.userCollection('accounts').doc(movement.destinationAccountId);
        destinationAccountSnapshot = await transaction.get(destinationAccountRef);
        if (!destinationAccountSnapshot.exists || destinationAccountSnapshot.data() == null) {
          throw Exception("La cuenta de destino no fue encontrada.");
        }
        destinationAccount = Account.fromFirestore(destinationAccountSnapshot);
      }

      // Lógica de actualización de saldo/adeudado según el tipo de movimiento
      switch (movement.type) {
        case 'expense':
          if (sourceAccount.isCreditCard) {
            transaction.update(sourceAccountRef, {'currentStatementBalance': FieldValue.increment(movement.amount)});
            transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(-movement.amount)});
          } else {
            transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(-movement.amount)});
          }
          break;
        case 'income':
          if (!sourceAccount.isCreditCard) {
            transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(movement.amount)});
          }
          break;
        case 'transfer':
          if (destinationAccount == null) throw StateError("Destination account is required for transfer.");
          if (sourceAccount.isCreditCard) {
            transaction.update(sourceAccountRef, {'currentStatementBalance': FieldValue.increment(movement.amount)});
            transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(-movement.amount)});
          } else {
            transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(-movement.amount)});
          }
          if (destinationAccount.isCreditCard) {
            transaction.update(destinationAccountRef!, {'currentStatementBalance': FieldValue.increment(-movement.amount)});
            transaction.update(destinationAccountRef, {'currentBalance': FieldValue.increment(movement.amount)});
          } else {
            transaction.update(destinationAccountRef!, {'currentBalance': FieldValue.increment(movement.amount)});
          }
          break;
        case 'payment':
          if (destinationAccount == null) throw StateError("Destination account is required for payment.");
          if (!destinationAccount.isCreditCard) {
            throw ArgumentError("Destination account for payment must be a credit card.");
          }
          transaction.update(sourceAccountRef, {'currentBalance': FieldValue.increment(-movement.amount)});
          transaction.update(destinationAccountRef!, {'currentStatementBalance': FieldValue.increment(-movement.amount)});
          transaction.update(destinationAccountRef, {'currentBalance': FieldValue.increment(movement.amount)});
          break;
        default:
          throw ArgumentError("Tipo de movimiento no soportado: ${movement.type}");
      }      // Guardar el movimiento en la colección de movimientos
      final movementsRef = BaseFirestoreService.userCollection('expenses');
      final newMovementRef = movementsRef.doc();
      transaction.set(newMovementRef, movement.copyWith(id: newMovementRef.id).toFirestore());
    });
    
    // Enviar notificación después de que la transacción sea exitosa
    try {
      await NotificationManager.handleMovementCreated(movement);
    } catch (e) {
      // print('Error enviando notificación para movimiento: $e');
      // No lanzamos el error para no afectar la operación principal
    }
  }

  /// Obtener todos los movimientos del usuario actual
  static Stream<List<Movement>> getMovements({String typeFilter = 'all'}) {
    if (BaseFirestoreService.currentUserId == null) {
      return Stream.value([]);
    }
    Query<Map<String, dynamic>> query = BaseFirestoreService.userCollection('expenses');
    if (typeFilter != 'all') {
      query = query.where('type', isEqualTo: typeFilter);
    }
    query = query.orderBy('dateTime', descending: true);
    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) => Movement.fromFirestore(doc)).toList());
  }
  /// Eliminar un movimiento (requiere actualizar saldo de cuenta(s) - Atómico)
  static Future<void> deleteMovement(String movementId) async {
    if (BaseFirestoreService.currentUserId == null) {
      throw StateError("Usuario no autenticado.");
    }
    
    DocumentReference movementRef = BaseFirestoreService.userCollection('expenses').doc(movementId);
    
    await BaseFirestoreService.db.runTransaction((Transaction transaction) async {
      // Obtener el movimiento a eliminar
      DocumentSnapshot movementSnapshot = await transaction.get(movementRef);
      if (!movementSnapshot.exists || movementSnapshot.data() == null) {
        throw Exception("El movimiento a eliminar no fue encontrado.");
      }
      
      Movement movementToDelete = Movement.fromFirestore(movementSnapshot);
      
      // Obtener la cuenta de origen
      DocumentReference sourceAccountRef = BaseFirestoreService.userCollection('accounts').doc(movementToDelete.accountId);
      DocumentSnapshot sourceAccountSnapshot = await transaction.get(sourceAccountRef);
      
      if (!sourceAccountSnapshot.exists || sourceAccountSnapshot.data() == null) {
        throw Exception("La cuenta de origen no fue encontrada.");
      }
      
      Account sourceAccount = Account.fromFirestore(sourceAccountSnapshot);
      
      // Obtener la cuenta de destino si aplica
      DocumentReference? destinationAccountRef;
      DocumentSnapshot? destinationAccountSnapshot;
      Account? destinationAccount;
      
      if (movementToDelete.type == 'transfer' || movementToDelete.type == 'payment') {
        if (movementToDelete.destinationAccountId != null) {
          destinationAccountRef = BaseFirestoreService.userCollection('accounts').doc(movementToDelete.destinationAccountId!);
          destinationAccountSnapshot = await transaction.get(destinationAccountRef);
          
          if (destinationAccountSnapshot.exists && destinationAccountSnapshot.data() != null) {
            destinationAccount = Account.fromFirestore(destinationAccountSnapshot);
          }
        }
      }
      
      // Revertir los efectos del movimiento en las cuentas
      switch (movementToDelete.type) {
        case 'expense':
          if (sourceAccount.isCreditCard) {
            // Revertir gasto en CC: restar del adeudado y sumar al cupo disponible
            transaction.update(sourceAccountRef, {
              'currentStatementBalance': FieldValue.increment(-movementToDelete.amount)
            });
            transaction.update(sourceAccountRef, {
              'currentBalance': FieldValue.increment(movementToDelete.amount)
            });
          } else {
            // Revertir gasto en cuenta normal: sumar al saldo
            transaction.update(sourceAccountRef, {
              'currentBalance': FieldValue.increment(movementToDelete.amount)
            });
          }
          break;
          
        case 'income':
          if (!sourceAccount.isCreditCard) {
            // Revertir ingreso: restar del saldo
            transaction.update(sourceAccountRef, {
              'currentBalance': FieldValue.increment(-movementToDelete.amount)
            });
          }
          break;
          
        case 'transfer':
          if (destinationAccount != null && destinationAccountRef != null) {
            // Revertir en cuenta de origen
            if (sourceAccount.isCreditCard) {
              // Si origen era CC: restar del adeudado y sumar al cupo disponible
              transaction.update(sourceAccountRef, {
                'currentStatementBalance': FieldValue.increment(-movementToDelete.amount)
              });
              transaction.update(sourceAccountRef, {
                'currentBalance': FieldValue.increment(movementToDelete.amount)
              });
            } else {
              // Si origen no era CC: sumar al saldo
              transaction.update(sourceAccountRef, {
                'currentBalance': FieldValue.increment(movementToDelete.amount)
              });
            }
            
            // Revertir en cuenta de destino
            if (!destinationAccount.isCreditCard) {
              // Si destino no es CC: restar del saldo
              transaction.update(destinationAccountRef, {
                'currentBalance': FieldValue.increment(-movementToDelete.amount)
              });
            }
          }
          break;
          
        case 'payment':
          if (destinationAccount != null && destinationAccountRef != null) {
            // Revertir pago a CC
            if (!sourceAccount.isCreditCard) {
              // Revertir en cuenta de origen (no CC): sumar al saldo
              transaction.update(sourceAccountRef, {
                'currentBalance': FieldValue.increment(movementToDelete.amount)
              });
            }
            
            if (destinationAccount.isCreditCard) {
              // Revertir en cuenta de destino (CC): sumar al adeudado y restar del cupo disponible
              transaction.update(destinationAccountRef, {
                'currentStatementBalance': FieldValue.increment(movementToDelete.amount)
              });
              transaction.update(destinationAccountRef, {
                'currentBalance': FieldValue.increment(-movementToDelete.amount)
              });
            }
          }
          break;
      }
      
      // Eliminar el documento del movimiento
      transaction.delete(movementRef);
    });
  }  /// Actualizar un movimiento y la cuenta asociada (Atómico)
  static Future<void> updateMovementAndAccount(Movement updatedMovement) async {
    BaseFirestoreService.validateAuthentication();
    
    if (updatedMovement.id == null) {
      throw ArgumentError("Cannot update a movement without an ID.");
    }
    
    DocumentReference movementRef = BaseFirestoreService.userCollection('expenses').doc(updatedMovement.id);
    
    await BaseFirestoreService.db.runTransaction((Transaction transaction) async {
      // PASO 1: Hacer TODAS las lecturas primero
      
      // Obtener el movimiento original
      DocumentSnapshot originalMovementSnapshot = await transaction.get(movementRef);
      if (!originalMovementSnapshot.exists || originalMovementSnapshot.data() == null) {
        throw Exception("El movimiento original no fue encontrado.");
      }
      
      Movement originalMovement = Movement.fromFirestore(originalMovementSnapshot);
      
      // Validar que no se cambie el tipo de movimiento
      if (originalMovement.type != updatedMovement.type) {
        throw ArgumentError("No se puede cambiar el tipo de movimiento durante la edición.");
      }
      
      // Obtener cuenta de origen original
      DocumentReference originalSourceAccountRef = BaseFirestoreService.userCollection('accounts').doc(originalMovement.accountId);
      DocumentSnapshot originalSourceAccountSnapshot = await transaction.get(originalSourceAccountRef);
      Account? originalSourceAccount;
      if (originalSourceAccountSnapshot.exists && originalSourceAccountSnapshot.data() != null) {
        originalSourceAccount = Account.fromFirestore(originalSourceAccountSnapshot);
      }
      
      // Obtener cuenta de destino original si aplica
      DocumentReference? originalDestinationAccountRef;
      DocumentSnapshot? originalDestinationAccountSnapshot;
      Account? originalDestinationAccount;
      if ((originalMovement.type == 'transfer' || originalMovement.type == 'payment') && 
          originalMovement.destinationAccountId != null) {
        originalDestinationAccountRef = BaseFirestoreService.userCollection('accounts').doc(originalMovement.destinationAccountId!);
        originalDestinationAccountSnapshot = await transaction.get(originalDestinationAccountRef);
        if (originalDestinationAccountSnapshot.exists && originalDestinationAccountSnapshot.data() != null) {
          originalDestinationAccount = Account.fromFirestore(originalDestinationAccountSnapshot);
        }
      }
      
      // Obtener cuenta de origen actualizada
      DocumentReference updatedSourceAccountRef = BaseFirestoreService.userCollection('accounts').doc(updatedMovement.accountId);
      DocumentSnapshot updatedSourceAccountSnapshot = await transaction.get(updatedSourceAccountRef);
      if (!updatedSourceAccountSnapshot.exists || updatedSourceAccountSnapshot.data() == null) {
        throw Exception("La cuenta de origen actualizada no fue encontrada.");
      }
      Account updatedSourceAccount = Account.fromFirestore(updatedSourceAccountSnapshot);
      
      // Obtener cuenta de destino actualizada si aplica
      DocumentReference? updatedDestinationAccountRef;
      DocumentSnapshot? updatedDestinationAccountSnapshot;
      Account? updatedDestinationAccount;
      if ((updatedMovement.type == 'transfer' || updatedMovement.type == 'payment') && 
          updatedMovement.destinationAccountId != null) {
        updatedDestinationAccountRef = BaseFirestoreService.userCollection('accounts').doc(updatedMovement.destinationAccountId!);
        updatedDestinationAccountSnapshot = await transaction.get(updatedDestinationAccountRef);
        if (!updatedDestinationAccountSnapshot.exists || updatedDestinationAccountSnapshot.data() == null) {
          throw Exception("La cuenta de destino actualizada no fue encontrada.");
        }
        updatedDestinationAccount = Account.fromFirestore(updatedDestinationAccountSnapshot);
      }
      
      // PASO 2: Revertir el efecto del movimiento original (solo escrituras)
      if (originalSourceAccount != null) {
        _revertMovementEffectsWriteOnly(
          transaction, 
          originalMovement, 
          originalSourceAccount, 
          originalSourceAccountRef, 
          originalDestinationAccount, 
          originalDestinationAccountRef
        );
      }
      
      // PASO 3: Aplicar el efecto del movimiento actualizado (solo escrituras)
      _applyMovementEffectsWriteOnly(
        transaction, 
        updatedMovement, 
        updatedSourceAccount, 
        updatedSourceAccountRef, 
        updatedDestinationAccount, 
        updatedDestinationAccountRef
      );
      
      // PASO 4: Actualizar el documento del movimiento
      transaction.set(movementRef, updatedMovement.toFirestore(), BaseFirestoreService.mergeOptions);
    });
  }
  
  /// Revertir los efectos de un movimiento en las cuentas (solo escrituras)
  static void _revertMovementEffectsWriteOnly(
    Transaction transaction, 
    Movement movement, 
    Account sourceAccount, 
    DocumentReference sourceAccountRef, 
    Account? destinationAccount, 
    DocumentReference? destinationAccountRef
  ) {
    // Revertir según el tipo de movimiento
    switch (movement.type) {
      case 'expense':
        if (sourceAccount.isCreditCard) {
          // Revertir gasto en CC: restar del adeudado y sumar al cupo disponible
          transaction.update(sourceAccountRef, {
            'currentStatementBalance': FieldValue.increment(-movement.amount)
          });
          transaction.update(sourceAccountRef, {
            'currentBalance': FieldValue.increment(movement.amount)
          });
        } else {
          // Revertir gasto en cuenta normal: sumar al saldo
          transaction.update(sourceAccountRef, {
            'currentBalance': FieldValue.increment(movement.amount)
          });
        }
        break;
        
      case 'income':
        if (!sourceAccount.isCreditCard) {
          // Revertir ingreso: restar del saldo
          transaction.update(sourceAccountRef, {
            'currentBalance': FieldValue.increment(-movement.amount)
          });
        }
        break;
        
      case 'transfer':
        if (destinationAccount != null && destinationAccountRef != null) {
          // Revertir en cuenta de origen
          if (sourceAccount.isCreditCard) {
            transaction.update(sourceAccountRef, {
              'currentStatementBalance': FieldValue.increment(-movement.amount)
            });
            transaction.update(sourceAccountRef, {
              'currentBalance': FieldValue.increment(movement.amount)
            });
          } else {
            transaction.update(sourceAccountRef, {
              'currentBalance': FieldValue.increment(movement.amount)
            });
          }
          
          // Revertir en cuenta de destino
          if (!destinationAccount.isCreditCard) {
            transaction.update(destinationAccountRef, {
              'currentBalance': FieldValue.increment(-movement.amount)
            });
          }
        }
        break;
        
      case 'payment':
        if (destinationAccount != null && destinationAccountRef != null) {
          // Revertir pago a CC
          if (!sourceAccount.isCreditCard) {
            transaction.update(sourceAccountRef, {
              'currentBalance': FieldValue.increment(movement.amount)
            });
          }
          
          if (destinationAccount.isCreditCard) {
            transaction.update(destinationAccountRef, {
              'currentStatementBalance': FieldValue.increment(movement.amount)
            });
            transaction.update(destinationAccountRef, {
              'currentBalance': FieldValue.increment(-movement.amount)
            });
          }
        }
        break;
    }
  }
  
  /// Aplicar los efectos de un movimiento en las cuentas (solo escrituras)
  static void _applyMovementEffectsWriteOnly(
    Transaction transaction, 
    Movement movement, 
    Account sourceAccount, 
    DocumentReference sourceAccountRef, 
    Account? destinationAccount, 
    DocumentReference? destinationAccountRef
  ) {
    // Aplicar según el tipo de movimiento
    switch (movement.type) {
      case 'expense':
        if (sourceAccount.isCreditCard) {
          transaction.update(sourceAccountRef, {
            'currentStatementBalance': FieldValue.increment(movement.amount)
          });
          transaction.update(sourceAccountRef, {
            'currentBalance': FieldValue.increment(-movement.amount)
          });
        } else {
          transaction.update(sourceAccountRef, {
            'currentBalance': FieldValue.increment(-movement.amount)
          });
        }
        break;
        
      case 'income':
        if (!sourceAccount.isCreditCard) {
          transaction.update(sourceAccountRef, {
            'currentBalance': FieldValue.increment(movement.amount)
          });
        }
        break;
        
      case 'transfer':
        if (destinationAccount == null) throw StateError("Destination account is required for transfer.");
        
        // Aplicar en cuenta de origen
        if (sourceAccount.isCreditCard) {
          transaction.update(sourceAccountRef, {
            'currentStatementBalance': FieldValue.increment(movement.amount)
          });
          transaction.update(sourceAccountRef, {
            'currentBalance': FieldValue.increment(-movement.amount)
          });
        } else {
          transaction.update(sourceAccountRef, {
            'currentBalance': FieldValue.increment(-movement.amount)
          });
        }
        
        // Aplicar en cuenta de destino
        if (destinationAccount.isCreditCard) {
          transaction.update(destinationAccountRef!, {
            'currentStatementBalance': FieldValue.increment(-movement.amount)
          });
          transaction.update(destinationAccountRef, {
            'currentBalance': FieldValue.increment(movement.amount)
          });
        } else {
          transaction.update(destinationAccountRef!, {
            'currentBalance': FieldValue.increment(movement.amount)
          });
        }
        break;
        
      case 'payment':
        if (destinationAccount == null) throw StateError("Destination account is required for payment.");
        if (!destinationAccount.isCreditCard) {
          throw ArgumentError("Destination account for payment must be a credit card.");
        }
        
        // Aplicar en cuenta de origen
        transaction.update(sourceAccountRef, {
          'currentBalance': FieldValue.increment(-movement.amount)
        });
        
        // Aplicar en cuenta de destino (CC)
        transaction.update(destinationAccountRef!, {
          'currentStatementBalance': FieldValue.increment(-movement.amount)
        });
        transaction.update(destinationAccountRef, {
          'currentBalance': FieldValue.increment(movement.amount)
        });
        break;
        
      default:
        throw ArgumentError("Tipo de movimiento no soportado: ${movement.type}");
    }
  }
}
