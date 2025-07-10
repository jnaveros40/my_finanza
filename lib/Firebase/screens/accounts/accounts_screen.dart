/*// lib/screens/accounts/accounts_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/account.dart'; // Importa el modelo Account
import 'package:mis_finanza/services/firestore_service.dart'; // Importa el servicio Firestore
// Importa la pantalla para editar cuentas
import 'package:mis_finanza/screens/auth/login_screen.dart'; // Para navegar al cerrar sesión
import 'package:cloud_firestore/cloud_firestore.dart'; // Necesario para WriteBatch
import 'package:intl/intl.dart'; // Necesario para NumberFormat (formato de moneda)
// --- Importar la pantalla de movimientos de cuenta ---
import 'package:mis_finanza/screens/accounts/account_movements_screen.dart';
// ---------------------------------------------------------


class AccountsScreen extends StatefulWidget { // Usamos StatefulWidget para manejar el estado del filtro
  const AccountsScreen({super.key});

  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> { // Estado para AccountsScreen
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService(); // Instancia del servicio

  // --- Estado para el filtro por tipo de cuenta ---
  String? _selectedAccountTypeFilter; // null para "Todos", o el tipo seleccionado
  // -----------------------------------------------------

  // Lista de tipos de cuenta disponibles para el filtro (debe coincidir con los tipos en Account model)
  final List<String> _accountTypesForFilter = [
    'Cuenta de ahorro',
    //'Renta Fija',
    //'Renta Variable',
    'Efectivo',
    'Tarjeta de credito',

  ];


  Future<void> _signOut(BuildContext context) async {
    await _googleSignIn.signOut(); // Cierra sesión de Google
    await _auth.signOut(); // Cierra sesión de Firebase
    // Navegar de regreso a LoginScreen después de cerrar sesión
      Navigator.pushReplacement( // Usar pushReplacement para limpiar la pila de navegación
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
  }

   // --- Función para confirmar y eliminar cuenta (ahora en el State) ---
  Future<bool> _confirmAndDeleteAccount(BuildContext context, Account account) async {
       // ... (código del diálogo de confirmación y lógica de eliminación - mantener igual) ...
        bool confirm = await showDialog( // Muestra un diálogo de confirmación
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirmar Eliminación'),
            content: Text('¿Estás seguro de que deseas eliminar la cuenta "${account.name}"? Esta acción no se puede deshacer.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // No eliminar
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // Confirmar eliminación
                child: Text('Eliminar', style: TextStyle(color: Colors.red)), // Color rojo fijo para la acción destructiva
              ),
            ],
          );
        },
      ) ?? false; // showDialog puede retornar null si se descarta

      if (confirm) {
        try {
          if (account.id != null) {
            await _firestoreService.deleteAccount(account.id!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cuenta "${account.name}" eliminada.')),
            );
            return true;
          } else {
            //print('Error: Intentando eliminar cuenta sin ID.');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: No se pudo obtener el ID de la cuenta para eliminar.')),
            );
            return false;
          }
        } catch (e) {
          //print('Error al eliminar cuenta: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar la cuenta: ${e.toString()}')),
          );
          return false;
        }
      }
      return false;
  }


   // --- Función para manejar el reordenamiento (ahora en el State) ---
  Future<void> _onReorderAccounts(BuildContext context, List<Account> currentAccounts, int oldIndex, int newIndex) async {

    List<Account> updatedAccountsList = List.from(currentAccounts);

  if (oldIndex < newIndex) {
          newIndex -= 1;
    }

    final Account movedAccount = updatedAccountsList.removeAt(oldIndex);
    updatedAccountsList.insert(newIndex, movedAccount);
    WriteBatch batch = FirebaseFirestore.instance.batch();
      // Obtener la referencia a la subcolección 'accounts' del usuario actual
      // Acceder a la instancia de Auth directamente aquí para obtener el UID
    CollectionReference accountsRef = FirebaseFirestore.instance
        .collection('users')
        // --- CORREGIDO: Acceso a currentUser ---
         .doc(FirebaseAuth.instance.currentUser?.uid) // Usar el ID del usuario autenticado
        // ------------------------------------
        .collection('accounts');

    for (int i = 0; i < updatedAccountsList.length; i++) {
        Account account = updatedAccountsList[i];
        if (account.id != null && account.order != i) {
            batch.set(accountsRef.doc(account.id!), {'order': i}, SetOptions(merge: true));
             //print('Batch: Actualizando orden para ${account.name} a $i'); // DEBUG
        } else if (account.id == null) {
             //print('DEBUG: Ignorando cuenta sin ID en reordenamiento.'); // DEBUG
        } else {
             //print('DEBUG: Orden de ${account.name} no cambió.'); // DEBUG
        }
    }

    try {
        //print('DEBUG: Intentando commitear batch...'); // DEBUG
        await batch.commit();
        //print('DEBUG: Batch commiteado exitosamente.'); // DEBUG
    } catch (e) {
        //print('DEBUG: Error al commitear batch: $e'); // DEBUG
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el orden: ${e.toString()}')),
        );
    }
  }

   // --- Helper para obtener el símbolo de moneda ---
  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'COP': return '\$';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'JPY': return '¥';
      default: return currencyCode;
    }
  }

  // --- Helper para formatear un monto con moneda ---
  String _formatCurrency(double amount, String currencyCode) {
    return NumberFormat.currency(
      locale: 'en_US', // Usa una locale con separador de miles con ',' y decimal '.'
      symbol: _getCurrencySymbol(currencyCode), // Obtiene el símbolo correcto
      decimalDigits: 0, // Dos decimales
    ).format(amount);
  }


  // --- Helper methods for UI styling ---
  IconData _getAccountTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cuenta de ahorro':
        return Icons.savings;
      case 'tarjeta de credito':
        return Icons.credit_card;
      case 'renta fija':
        return Icons.trending_up;
      case 'renta variable':
        return Icons.show_chart;
      case 'efectivo':
        return Icons.account_balance_wallet;
      case 'inversiones':
        return Icons.business_center;
      case 'deuda':
        return Icons.money_off;
      default:
        return Icons.account_balance;
    }
  }

  Color _getAccountTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'cuenta de ahorro':
        return Colors.green;
      case 'tarjeta de credito':
        return Colors.blue;
      case 'renta fija':
        return Colors.teal;
      case 'renta variable':
        return Colors.orange;
      case 'efectivo':
        return Colors.purple;
      case 'inversiones':
        return Colors.indigo;
      case 'deuda':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- CORREGIDO: Acceso a currentUser ---
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('Por favor, inicia sesión para ver tus cuentas.'));
    }
    // ------------------------------------

    return Material(
      color: Colors.transparent, // Usar color transparente en lugar de MaterialType.transparency
      child: Column( // Usamos Column para estructurar el contenido
      crossAxisAlignment: CrossAxisAlignment.start, // Alinear contenido a la izquierda
      children: [
            // Puedes mantener el título "Tus Cuentas" si quieres una sección clara dentro del cuerpo
            Padding( // Título para la sección de cuentas
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
              'Tus Cuentas',
              // Usar un estilo de texto del tema que se adapte
              style: Theme.of(context).textTheme.titleLarge,
              ),
          ),          // --- Enhanced dropdown para filtrar por tipo de cuenta ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String?>(
                decoration: InputDecoration(
                  labelText: 'Filtrar por Tipo',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.filter_list,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                ),
                value: _selectedAccountTypeFilter, // Valor seleccionado (null para "Todos")
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: [
                  // Opción para mostrar todos los tipos
                  DropdownMenuItem<String?>(
                    value: null, // null representa "Todos"
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.all_inclusive,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Todos los Tipos',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Opciones para cada tipo de cuenta disponible
                  ..._accountTypesForFilter.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _getAccountTypeColor(type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              _getAccountTypeIcon(type),
                              size: 16,
                              color: _getAccountTypeColor(type),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            type,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (newValue) {
                  setState(() {
                    _selectedAccountTypeFilter = newValue; // Actualizar el estado del filtro
                  });
                },
              ),
            ),
          ),
          // ----------------------------------------------------

  // --- Lista de Cuentas Reordenable con StreamBuilder ---
  Expanded( // Expanded para que la lista ocupe el espacio restante
  child: StreamBuilder<List<Account>>(
  stream: _firestoreService.getAccounts(), // <-- Escucha el stream de cuentas del servicio (ya ordenado por 'order')
  builder: (context, snapshot) {
  // Muestra un indicador de carga mientras espera datos
  if (snapshot.connectionState == ConnectionState.waiting) {
  return Center(child: CircularProgressIndicator());
  }
  // Si hay un error
  if (snapshot.hasError) {
  //print('Error cargando cuentas: ${snapshot.error}'); // Imprimir error en consola
  return Center(child: Text('Error al cargar las cuentas: ${snapshot.error}'));
  }
  // Si no hay datos (lista vacía)
  if (!snapshot.hasData || snapshot.data!.isEmpty) {
       // Mostrar mensaje incluso si hay un filtro aplicado pero no hay resultados
       return Center(child: Text(_selectedAccountTypeFilter == null
           ? 'No tienes cuentas aún. ¡Agrega una usando el botón "+"!.'
           : 'No se encontraron cuentas del tipo "$_selectedAccountTypeFilter" con el filtro seleccionado.'));
  }

  // Si hay datos, aplicar el filtro por tipo antes de construir la lista
  final allAccounts = snapshot.data!;
  List<Account> filteredAccounts = allAccounts.where((account) {
      // Si no hay filtro seleccionado O si el tipo de la cuenta coincide con el filtro, incluirla.
      return _selectedAccountTypeFilter == null || account.type == _selectedAccountTypeFilter;
  }).toList();

   // --- NUEVO: Ordenar la lista filtrada por currentBalance de forma descendente ---
   filteredAccounts.sort((a, b) => b.currentBalance.compareTo(a.currentBalance));
   // -----------------------------------------------------------------------------


   if (filteredAccounts.isEmpty) {
       // Este caso ya se maneja arriba antes de construir el ReorderableListView
       return Center(child: Text('No se encontraron cuentas del tipo "$_selectedAccountTypeFilter" con el filtro seleccionado.'));
   }


                // --- USAR ReorderableListView.builder ---
                // Requiere que los hijos (los items) tengan una Key única
  return ReorderableListView.builder(
                   // Usar una clave única para el ReorderableListView (por ejemplo, una clave de valor)
                   // Esto ayuda a Flutter a identificar la lista si cambia mucho.
                   key: ValueKey('reorderable_accounts_list_${filteredAccounts.length}'), // Clave basada en el número de elementos filtrados
                   // Usar la lista FILTRADA para el itemCount y los items
                itemCount: filteredAccounts.length,
                   // La función onReorder se llama cuando un elemento se arrastra y se suelta
                   // Le pasamos la lista actual de cuentas (snapshot.data!) a la función de reordenamiento
                   // NOTA IMPORTANTE: El reordenamiento afectará la lista COMPLETA en Firestore,
                   // no solo la lista filtrada. La UI se actualizará para mostrar la lista filtrada
                   // con el nuevo orden de los elementos visibles.
                  onReorder: (oldIndex, newIndex) {
                      // Para manejar el reordenamiento correctamente con una lista filtrada,
                      // la lógica de reordenamiento (_onReorderAccounts) debería operar sobre la lista COMPLETA
                      // y luego recalcular los índices de orden para TODOS los elementos.
                      // Sin embargo, la implementación actual de _onReorderAccounts ya trabaja sobre la lista completa
                      // que recibe. Necesitamos asegurarnos de que reciba la lista COMPLETA y ordenada.
                      // El stream _firestoreService.getAccounts() ya trae la lista completa y ordenada por 'order'.
                      // Pasamos esa lista completa a _onReorderAccounts.
                      _onReorderAccounts(context, List.from(allAccounts), oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                      final account = filteredAccounts[index]; // Usar la cuenta de la lista FILTRADA

                       // --- Mensaje de depuración para CC (fuera del árbol de widgets) ---
                       if (account.isCreditCard) {
                            //print("DEBUG AccountsScreen Account: ID: ${account.id}, Name: ${account.name}, isCreditCard: ${account.isCreditCard}, CreditLimit: ${account.creditLimit}, CurrentStatementBalance: ${account.currentStatementBalance}, CurrentBalance (Cupo Disp): ${account.currentBalance}"); // DEBUG
                       }
                       // ------------------------------------------------------------------                       // --- Cada elemento HIJO de ReorderableListView NECESITA UNA Key ÚNICA ---
                       // El widget padre debe tener la Key para ReorderableListView
                       // El ID de Firestore de la cuenta es la clave perfecta.
                      return Padding(
                        key: Key(account.id!), // La Key debe estar en el widget padre
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Dismissible(
  key: Key('dismissible_${account.id!}'), // Una key diferente para Dismissible
  direction: DismissDirection.endToStart,
  background: Container(
    margin: const EdgeInsets.symmetric(horizontal: 16.0),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.error,
      borderRadius: BorderRadius.circular(20),
    ),
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: Icon(Icons.delete, color: Colors.white),
  ),
  confirmDismiss: (direction) async {
    return await _confirmAndDeleteAccount(context, account);
  },
  onDismissed: (direction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${account.name} deslizada para eliminar.')),
    );
  },
  child: Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AccountMovementsScreen(account: account)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getAccountTypeColor(account.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getAccountTypeIcon(account.type),
                size: 28,
                color: _getAccountTypeColor(account.type),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [                  Text(
                    account.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // --- MOSTRAR CAMPOS PERSONALIZABLES SI TIENEN VALOR ---
                  if (account.customId != null && account.customId!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 14,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ID: ${account.customId}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  if (account.customKey != null && account.customKey!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.key_outlined,
                            size: 14,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Llave: ${account.customKey}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),                    ),
                  ],
                  // -------------------------------------------------------
                  
                  if (account.isCreditCard) ...[Text(
                      'Tarjeta de Crédito - ${account.currency}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Organización vertical de cupo y adeudado
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.credit_card,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Cupo Total: ${_formatCurrency(account.creditLimit, account.currency)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.money_off,
                                size: 16,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Adeudado: ${_formatCurrency(account.currentStatementBalance, account.currency)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        /*Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Disponible: ${_formatCurrency(account.currentBalance, account.currency)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),*/
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getAccountTypeColor(account.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${account.type} - ${account.currency}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _getAccountTypeColor(account.type),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  account.isCreditCard ? 'Disponible' : 'Saldo',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(account.currentBalance, account.currency),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: account.isCreditCard 
                        ? Colors.green
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  /*child: IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: 'Editar Cuenta',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditAccountScreen(account: account),
                        ),
                      );
                    },
                  ),*/
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
),
                      );
                  }, // itemBuilder
                ); // ReorderableListView.builder
              }, // StreamBuilder builder
            ), // StreamBuilder
          ), // Expanded
        ], // Column children
      ), // Column
    ); // Material
  } // build method
} // _AccountsScreenState class
*/