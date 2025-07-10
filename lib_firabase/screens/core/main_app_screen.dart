// lib/screens/core/main_app_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Para el logout
import 'package:google_sign_in/google_sign_in.dart'; // Para el logout

// Importar las pantallas de los módulos
import 'package:mis_finanza/screens/dashboard/dashboard_screen.dart'; // Importar DashboardScreen
import 'package:mis_finanza/screens/accounts/accounts_screen.dart'; // Pantalla de Cuentas
import 'package:mis_finanza/screens/movements/movements_screen.dart'; // Importar MovementsScreen
import 'package:mis_finanza/screens/budgets/budgets_screen.dart'; // Importar BudgetsScreen
import 'package:mis_finanza/screens/investments/investments_screen.dart'; // Importar InvestmentsScreen
import 'package:mis_finanza/screens/debts/debts_screen.dart'; // Importar DebtsScreen
import 'package:mis_finanza/screens/categories/categories_screen.dart'; // Importar CategoriesScreen
import 'package:mis_finanza/screens/settings/settings_screen.dart'; // <-- NUEVO: Importar SettingsScreen
import 'package:mis_finanza/screens/notifications/notifications_screen.dart'; // Importar NotificationsScreen
import 'package:mis_finanza/screens/investments/investment_update_screen.dart'; // Importar la nueva pantalla


// Importar las pantallas para añadir/editar (para el FAB)
import 'package:mis_finanza/screens/auth/login_screen.dart'; // Para navegar al cerrar sesión
import 'package:mis_finanza/screens/accounts/add_account_screen.dart'; // Add Account screen
import 'package:mis_finanza/screens/movements/add_movement_screen.dart'; // Add Movement screen
import 'package:mis_finanza/screens/budgets/add_edit_budget_screen.dart'; // Importar AddEditBudgetScreen
import 'package:mis_finanza/screens/investments/add_edit_investment_screen.dart'; // Importar AddEditInvestmentScreen
import 'package:mis_finanza/screens/debts/add_edit_debt_screen.dart'; // Importar AddEditDebtScreen
import 'package:mis_finanza/screens/categories/add_edit_category_screen.dart'; // Importar AddCategoryScreen (para FAB si aplica)

// Importar los nuevos widgets animados
import 'package:mis_finanza/screens/core/widgets/animated_drawer_header.dart';
import 'package:mis_finanza/screens/core/widgets/animated_drawer_section.dart';
import 'package:mis_finanza/screens/core/widgets/animated_drawer_tile.dart';


class MainAppScreen extends StatefulWidget {
  final int initialIndex;
  const MainAppScreen({super.key, this.initialIndex = 0});

  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  late int _selectedIndex; // Índice de la pantalla seleccionada en la BottomNavigationBar o Drawer
  bool _isRefreshing = false; // Estado para controlar la actualización de inversiones
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // Inicializar con el índice proporcionado
  }
  // Función para actualizar las inversiones
  Future<void> _refreshInvestments() async {
    if (_isRefreshing) return; // Evitar múltiples actualizaciones simultáneas
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Simular una actualización de 2 segundos
      await Future.delayed(Duration(seconds: 2));
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Inversiones actualizadas'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Error al actualizar: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
  // Lista de pantallas que se mostrarán (ahora 9 pantallas)
  final List<Widget> _screens = [
    DashboardScreen(), // Índice 0
    AccountsScreen(), // Índice 1 (Cuentas)
    MovementsScreen(), // Índice 2
    BudgetsScreen(), // Índice 3
    InvestmentsScreen(), // Índice 4
    DebtsScreen(), // Índice 5
    CategoriesScreen(), // Índice 6 (Categorías)
    SettingsScreen(), // Índice 7 (Configuración)
    NotificationsScreen(), // Índice 8 (Notificaciones) <-- NUEVO
  ];
  // Función que se llama al tocar un ítem de la BottomNavigationBar o Drawer
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Si el tap viene del Drawer, cerramos el Drawer
    // Verificamos si el drawer está abierto antes de intentar cerrarlo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scaffoldState = context.findAncestorStateOfType<ScaffoldState>();
      if (scaffoldState != null && scaffoldState.isDrawerOpen) {
        Navigator.pop(context);
      }
    });
  }

  // Función para cerrar sesión
  Future<void> _signOut(BuildContext context) async {
    try {
      await GoogleSignIn().signOut(); // Cierra sesión de Google si se usó
      await FirebaseAuth.instance.signOut(); // Cierra sesión de Firebase
      // Navegar de regreso a la pantalla de inicio de sesión
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false, // Elimina todas las rutas anteriores
      );
    } catch (e) {
      //print('Error al cerrar sesión: $e');
      // Mostrar un mensaje de error al usuario si falla el cierre de sesión
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión. Inténtalo de nuevo.')),
      );
    }
  }

  // Función para decidir qué pantalla de "añadir" abrir al tocar el FAB
  void _onFabPressed(BuildContext context) {
    Widget screenToAdd;

    switch (_selectedIndex) {
      case 1: // Cuentas
        screenToAdd = AddAccountScreen();
        break;
      case 2: // Movimientos
        screenToAdd = AddMovementScreen();
        break;
      case 3: // Presupuestos
        screenToAdd = AddEditBudgetScreen(); // Se usa la misma pantalla para añadir/editar
        break;
      case 4: // Inversiones
        screenToAdd = AddEditInvestmentScreen(); // Se usa la misma pantalla para añadir/editar
        break;
      case 5: // Deudas
        screenToAdd = AddEditDebtScreen(); // Se usa la misma pantalla para añadir/editar
        break;      case 6: // Categorías
         screenToAdd = AddEditCategoryScreen(); // Pantalla específica para añadir categoría
         break;
      case 7: // Configuración
      case 8: // Notificaciones
      default: // Dashboard u otras pantallas sin FAB de añadir
        return; // No hacer nada si no es una pantalla con FAB de añadir
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screenToAdd),
    );
  }

  // Helper para obtener el índice correcto para la BottomNavigationBar
  // Retorna el índice del BottomNavigationBar si la pantalla actual está en él,
  // de lo contrario, retorna -1 o un valor fuera de rango para no seleccionar nada.
  int _getBottomNavigationBarCurrentIndex() {
    // Mapea los índices de _screens a los índices de la BottomNavigationBar
    switch (_selectedIndex) {
      case 0: // Dashboard
        return 0;
      case 1: // Cuentas
        return 1;
      case 2: // Movimientos
        return 2;
      case 3: // Presupuestos
        return 3;
      case 4: // Inversiones
        return 4;
      case 5: // Deudas
        return 5;
      case 6: // Categorías (No está en la BottomNavigationBar)
      case 7: // Configuración (No está en la BottomNavigationBar)
      default:
        return -1; // Indica que no hay un ítem seleccionado en la BottomNavigationBar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JNFinanza_app'),
        actions: [
          // --- Botón de notificaciones ---
          IconButton(
            icon: Icon(Icons.notifications),
            tooltip: 'Notificaciones',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),          // --- Botón de actualizar inversiones ---
          IconButton(
            onPressed: _isRefreshing ? null : _refreshInvestments,
            icon: _isRefreshing 
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(Icons.refresh),
            tooltip: 'Actualizar inversiones',
          ),
          // ------------------------------------------------------------------------------------
          // Botón de cerrar sesión
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _signOut(context), // Llama a la función de cerrar sesión
          ),
        ],
      ),      // --- Drawer (Menú Lateral) Animado ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // Header animado
            AnimatedDrawerHeader(),
            
            // Sección: PRINCIPALES
            AnimatedDrawerSection(
              title: 'PRINCIPALES',
              icon: Icons.home,
              animationDelay: 200,
              children: [
                AnimatedDrawerTile(
                  leading: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  subtitle: 'Resumen general',
                  onTap: () => _onItemTapped(0),
                  isSelected: _selectedIndex == 0,
                  animationDelay: 300,
                ),
                AnimatedDrawerTile(
                  leading: Icons.account_balance_wallet_outlined,
                  title: 'Cuentas',
                  subtitle: 'Administrar cuentas',
                  onTap: () => _onItemTapped(1),
                  isSelected: _selectedIndex == 1,
                  animationDelay: 350,
                ),
                AnimatedDrawerTile(
                  leading: Icons.receipt_long_outlined,
                  title: 'Movimientos',
                  subtitle: 'Historial de transacciones',
                  onTap: () => _onItemTapped(2),
                  isSelected: _selectedIndex == 2,
                  animationDelay: 400,
                ),
              ],
            ),
            
            // Sección: PLANIFICACIÓN
            AnimatedDrawerSection(
              title: 'PLANIFICACIÓN',
              icon: Icons.timeline,
              animationDelay: 500,
              children: [
                AnimatedDrawerTile(
                  leading: Icons.account_balance_outlined,
                  title: 'Presupuestos',
                  subtitle: 'Control de gastos',
                  onTap: () => _onItemTapped(3),
                  isSelected: _selectedIndex == 3,
                  animationDelay: 600,
                ),
                AnimatedDrawerTile(
                  leading: Icons.trending_up_outlined,
                  title: 'Inversiones',
                  subtitle: 'Portafolio de inversión',
                  onTap: () => _onItemTapped(4),
                  isSelected: _selectedIndex == 4,
                  animationDelay: 650,
                ),
                AnimatedDrawerTile(
                  leading: Icons.money_off_outlined,
                  title: 'Deudas',
                  subtitle: 'Gestión de deudas',
                  onTap: () => _onItemTapped(5),
                  isSelected: _selectedIndex == 5,
                  animationDelay: 700,
                ),
              ],
            ),
            
            // Sección: CONFIGURACIÓN
            AnimatedDrawerSection(
              title: 'CONFIGURACIÓN',
              icon: Icons.tune,
              animationDelay: 800,
              children: [
                AnimatedDrawerTile(
                  leading: Icons.category_outlined,
                  title: 'Categorías',
                  subtitle: 'Organizar transacciones',
                  onTap: () => _onItemTapped(6),
                  isSelected: _selectedIndex == 6,
                  animationDelay: 900,
                ),
                AnimatedDrawerTile(
                  leading: Icons.settings_outlined,
                  title: 'Configuración',
                  subtitle: 'Preferencias de la app',
                  onTap: () => _onItemTapped(7),
                  isSelected: _selectedIndex == 7,
                  animationDelay: 950,
                ),
                AnimatedDrawerTile(
                  leading: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  subtitle: 'Alertas y recordatorios',
                  onTap: () => _onItemTapped(8),
                  isSelected: _selectedIndex == 8,
                  animationDelay: 1000,
                ),
              ],
            ),
            
            // Sección: HERRAMIENTAS
            AnimatedDrawerSection(
              title: 'HERRAMIENTAS',
              icon: Icons.build_outlined,
              animationDelay: 1100,
              children: [
                AnimatedDrawerTile(
                  leading: Icons.update_outlined,
                  title: 'Actualización de inversiones',
                  subtitle: 'Sincronizar datos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InvestmentUpdateScreen(),
                      ),
                    );
                  },
                  isSelected: false,
                  animationDelay: 1200,
                ),
              ],
            ),
            
            // Espaciado final con separador elegante
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 16,
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'JNFinanza v2.1',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // --- Cuerpo de la aplicación: muestra la pantalla seleccionada ---
      body: _screens[_selectedIndex],      // --- BottomNavigationBar ---
      // Solo mostrará los ítems para las pantallas principales
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), // Icono más moderno para Dashboard
            activeIcon: Icon(Icons.home), // Icono filled cuando está activo
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined), // Icono outlined para Cuentas
            activeIcon: Icon(Icons.account_balance_wallet), // Icono filled cuando está activo
            label: 'Cuentas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz), // Icono más dinámico para Movimientos
            label: 'Movimientos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.donut_small), // Icono más visual para Presupuestos
            label: 'Presupuestos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up), // Icono para Inversiones
            label: 'Inversiones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card), // Icono más apropiado para Deudas
            label: 'Deudas',
          ),
           // No incluimos Categorías en la BottomNavigationBar.
        ],
        // Usar el helper para obtener el índice correcto para la BottomNavigationBar
        currentIndex: _getBottomNavigationBarCurrentIndex() == -1 ? 0 : _getBottomNavigationBarCurrentIndex(), // Si no hay un índice válido, selecciona el primero (Dashboard)
        // Usar colores del tema para los ítems seleccionados y no seleccionados
        selectedItemColor: Theme.of(context).colorScheme.primary, // Color del ítem seleccionado (del tema)
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // Color de los ítems no seleccionados (del tema con opacidad)
        // El onTap de la BottomNavigationBar sigue llamando a _onItemTapped con el índice del ítem tocado
        onTap: (index) {
           // Mapear el índice del BottomNavigationBar al índice de la lista _screens
           int screenIndex = -1;
            switch (index) {
              case 0: screenIndex = 0; break; // Dashboard
              case 1: screenIndex = 1; break; // Cuentas
              case 2: screenIndex = 2; break; // Movimientos
              case 3: screenIndex = 3; break; // Presupuestos
              case 4: screenIndex = 4; break; // Inversiones
              case 5: screenIndex = 5; break; // Deudas
            }
            if (screenIndex != -1) {
               _onItemTapped(screenIndex);
            }
        },        type: BottomNavigationBarType.fixed, // O fixed si tienes 4+ ítems
      ),
      // FloatingActionButton en el Scaffold principal
      floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 7 || _selectedIndex == 8) ? null : FloatingActionButton( // No mostrar FAB en Dashboard (0), Configuración (7) y Notificaciones (8)
        onPressed: () => _onFabPressed(context), // Llama a la función que decide la acción
        tooltip: 'Añadir nuevo', // Tooltip genérico
        child: Icon(Icons.add),
      ),
    );
  }
}

// Widgets auxiliares

// Widget mejorado para los ListTiles del Drawer con diseño enhanced
class EnhancedListTile extends StatefulWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isSelected;

  const EnhancedListTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  State<EnhancedListTile> createState() => _EnhancedListTileState();
}

class _EnhancedListTileState extends State<EnhancedListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: widget.isSelected 
                  ? colorScheme.primaryContainer.withOpacity(0.6)
                  : _isPressed 
                    ? colorScheme.primary.withOpacity(0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: widget.isSelected 
                  ? Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
                boxShadow: widget.isSelected 
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isSelected 
                      ? colorScheme.primary.withOpacity(0.15)
                      : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      iconTheme: IconThemeData(
                        color: widget.isSelected 
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    child: widget.leading,
                  ),
                ),
                title: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: widget.isSelected 
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                subtitle: widget.subtitle != null 
                  ? Text(
                      widget.subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.isSelected 
                          ? colorScheme.onPrimaryContainer.withOpacity(0.8)
                          : colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hoverColor: colorScheme.primary.withOpacity(0.08),
                focusColor: colorScheme.primary.withOpacity(0.12),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Widget personalizado para los ListTiles del Drawer para manejar el color de selección
class ListListTile extends StatelessWidget {
  final Icon leading;
  final String title;
  final VoidCallback onTap;
  final bool isSelected;

  const ListListTile({
    super.key,
    required this.leading,
    required this.title,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      // Cambiar el color de fondo si está seleccionado
      tileColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
      // Cambiar el color del texto y el icono si está seleccionado para que contraste
      selectedColor: Theme.of(context).colorScheme.primary, // Color del texto/icono cuando está seleccionado
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1), // Color de fondo cuando está seleccionado
      onTap: onTap,
      selected: isSelected, // Indica si el ListTile está seleccionado
    );
  }
}
