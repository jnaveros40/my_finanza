// lib/screens/settings/notification_settings_screen.dart
/*
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import '../../services/push_notification_service.dart';
import '../../services/notification_manager.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Notification preferences
  bool _pushNotificationsEnabled = true;
  bool _budgetAlertsEnabled = true;
  bool _paymentRemindersEnabled = true;
  bool _creditCardAlertsEnabled = true;
  bool _investmentUpdatesEnabled = true;
  bool _lowBalanceAlertsEnabled = true;
  bool _largeTransactionAlertsEnabled = true;
  bool _weeklyReportsEnabled = true;
  bool _monthlyReportsEnabled = true;
  
  // Alert thresholds
  double _lowBalanceThreshold = 1000;
  double _largeTransactionThreshold = 5000;
  int _budgetWarningPercentage = 80;
  
  bool _isLoading = true;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    if (currentUser == null) return;
    
    try {
      // Load from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('settings')
          .doc('notifications')
          .get();
      
      // Load from SharedPreferences as fallback
      final prefs = await SharedPreferences.getInstance();
      
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _pushNotificationsEnabled = data['pushNotificationsEnabled'] ?? true;
          _budgetAlertsEnabled = data['budgetAlertsEnabled'] ?? true;
          _paymentRemindersEnabled = data['paymentRemindersEnabled'] ?? true;
          _creditCardAlertsEnabled = data['creditCardAlertsEnabled'] ?? true;
          _investmentUpdatesEnabled = data['investmentUpdatesEnabled'] ?? true;
          _lowBalanceAlertsEnabled = data['lowBalanceAlertsEnabled'] ?? true;
          _largeTransactionAlertsEnabled = data['largeTransactionAlertsEnabled'] ?? true;
          _weeklyReportsEnabled = data['weeklyReportsEnabled'] ?? true;
          _monthlyReportsEnabled = data['monthlyReportsEnabled'] ?? true;
          
          _lowBalanceThreshold = (data['lowBalanceThreshold'] as num?)?.toDouble() ?? 1000;
          _largeTransactionThreshold = (data['largeTransactionThreshold'] as num?)?.toDouble() ?? 5000;
          _budgetWarningPercentage = data['budgetWarningPercentage'] ?? 80;
        });
      } else {
        // Use SharedPreferences values
        setState(() {
          _pushNotificationsEnabled = prefs.getBool('pushNotificationsEnabled') ?? true;
          _budgetAlertsEnabled = prefs.getBool('budgetAlertsEnabled') ?? true;
          _paymentRemindersEnabled = prefs.getBool('paymentRemindersEnabled') ?? true;
          _creditCardAlertsEnabled = prefs.getBool('creditCardAlertsEnabled') ?? true;
          _investmentUpdatesEnabled = prefs.getBool('investmentUpdatesEnabled') ?? true;
          _lowBalanceAlertsEnabled = prefs.getBool('lowBalanceAlertsEnabled') ?? true;
          _largeTransactionAlertsEnabled = prefs.getBool('largeTransactionAlertsEnabled') ?? true;
          _weeklyReportsEnabled = prefs.getBool('weeklyReportsEnabled') ?? true;
          _monthlyReportsEnabled = prefs.getBool('monthlyReportsEnabled') ?? true;
          
          _lowBalanceThreshold = prefs.getDouble('lowBalanceThreshold') ?? 1000;
          _largeTransactionThreshold = prefs.getDouble('largeTransactionThreshold') ?? 5000;
          _budgetWarningPercentage = prefs.getInt('budgetWarningPercentage') ?? 80;
        });
      }
    } catch (e) {
      print('[NOTIFICATION_SETTINGS] Error cargando configuración: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar configuración de notificaciones'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotificationSettings() async {
    if (currentUser == null) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final settingsData = {
        'pushNotificationsEnabled': _pushNotificationsEnabled,
        'budgetAlertsEnabled': _budgetAlertsEnabled,
        'paymentRemindersEnabled': _paymentRemindersEnabled,
        'creditCardAlertsEnabled': _creditCardAlertsEnabled,
        'investmentUpdatesEnabled': _investmentUpdatesEnabled,
        'lowBalanceAlertsEnabled': _lowBalanceAlertsEnabled,
        'largeTransactionAlertsEnabled': _largeTransactionAlertsEnabled,
        'weeklyReportsEnabled': _weeklyReportsEnabled,
        'monthlyReportsEnabled': _monthlyReportsEnabled,
        'lowBalanceThreshold': _lowBalanceThreshold,
        'largeTransactionThreshold': _largeTransactionThreshold,
        'budgetWarningPercentage': _budgetWarningPercentage,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('settings')
          .doc('notifications')
          .set(settingsData, SetOptions(merge: true));
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pushNotificationsEnabled', _pushNotificationsEnabled);
      await prefs.setBool('budgetAlertsEnabled', _budgetAlertsEnabled);
      await prefs.setBool('paymentRemindersEnabled', _paymentRemindersEnabled);
      await prefs.setBool('creditCardAlertsEnabled', _creditCardAlertsEnabled);
      await prefs.setBool('investmentUpdatesEnabled', _investmentUpdatesEnabled);
      await prefs.setBool('lowBalanceAlertsEnabled', _lowBalanceAlertsEnabled);
      await prefs.setBool('largeTransactionAlertsEnabled', _largeTransactionAlertsEnabled);
      await prefs.setBool('weeklyReportsEnabled', _weeklyReportsEnabled);
      await prefs.setBool('monthlyReportsEnabled', _monthlyReportsEnabled);
      await prefs.setDouble('lowBalanceThreshold', _lowBalanceThreshold);
      await prefs.setDouble('largeTransactionThreshold', _largeTransactionThreshold);
      await prefs.setInt('budgetWarningPercentage', _budgetWarningPercentage);
      
      // Apply notification settings
      await _applyNotificationSettings();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuración de notificaciones guardada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('[NOTIFICATION_SETTINGS] Error guardando configuración: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar configuración'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _applyNotificationSettings() async {
    if (currentUser == null) return;
    
    try {
      if (_pushNotificationsEnabled) {
        await NotificationManager.initializeForUser(currentUser!.uid);
      } else {
        await NotificationManager.cleanupForUser(currentUser!.uid);
      }
    } catch (e) {
      print('[NOTIFICATION_SETTINGS] Error aplicando configuración: $e');
    }
  }

  Future<void> _testNotification() async {
    try {
      await NotificationManager.sendCustomNotification(
        userId: currentUser!.uid,
        title: 'Notificación de Prueba',
        message: 'Esta es una notificación de prueba para verificar que todo funciona correctamente.',
        type: 'test_notification',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notificación de prueba enviada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('[NOTIFICATION_SETTINGS] Error enviando notificación de prueba: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar notificación de prueba'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Configuración de Notificaciones'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configuración de Notificaciones',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _buildHeaderCard(),
            SizedBox(height: 20),
            
            // General settings
            _buildGeneralSettings(),
            SizedBox(height: 20),
            
            // Alert types
            _buildAlertTypes(),
            SizedBox(height: 20),
            
            // Thresholds
            _buildThresholds(),
            SizedBox(height: 20),
            
            // Reports
            _buildReportSettings(),
            SizedBox(height: 20),
            
            // Test notification
            _buildTestSection(),
            SizedBox(height: 30),
            
            // Save button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notificaciones Push',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Personaliza cómo y cuándo recibir notificaciones',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return _buildSection(
      title: 'Configuración General',
      icon: Icons.settings,
      children: [
        _buildSwitchTile(
          title: 'Notificaciones Push',
          subtitle: 'Habilitar todas las notificaciones push',
          value: _pushNotificationsEnabled,
          onChanged: (value) => setState(() => _pushNotificationsEnabled = value),
        ),
      ],
    );
  }

  Widget _buildAlertTypes() {
    return _buildSection(
      title: 'Tipos de Alertas',
      icon: Icons.warning_rounded,
      children: [
        _buildSwitchTile(
          title: 'Alertas de Presupuesto',
          subtitle: 'Cuando excedas o te acerques al límite',
          value: _budgetAlertsEnabled,
          onChanged: (value) => setState(() => _budgetAlertsEnabled = value),
          enabled: _pushNotificationsEnabled,
        ),
        _buildSwitchTile(
          title: 'Recordatorios de Pago',
          subtitle: 'Pagos de deudas y tarjetas de crédito',
          value: _paymentRemindersEnabled,
          onChanged: (value) => setState(() => _paymentRemindersEnabled = value),
          enabled: _pushNotificationsEnabled,
        ),
        _buildSwitchTile(
          title: 'Alertas de Tarjetas de Crédito',
          subtitle: 'Fechas de corte y vencimiento',
          value: _creditCardAlertsEnabled,
          onChanged: (value) => setState(() => _creditCardAlertsEnabled = value),
          enabled: _pushNotificationsEnabled,
        ),
        _buildSwitchTile(
          title: 'Actualizaciones de Inversiones',
          subtitle: 'Cambios significativos en tus inversiones',
          value: _investmentUpdatesEnabled,
          onChanged: (value) => setState(() => _investmentUpdatesEnabled = value),
          enabled: _pushNotificationsEnabled,
        ),
        _buildSwitchTile(
          title: 'Alertas de Saldo Bajo',
          subtitle: 'Cuando el saldo esté por debajo del límite',
          value: _lowBalanceAlertsEnabled,
          onChanged: (value) => setState(() => _lowBalanceAlertsEnabled = value),
          enabled: _pushNotificationsEnabled,
        ),
        _buildSwitchTile(
          title: 'Alertas de Transacciones Grandes',
          subtitle: 'Transacciones que superen el monto configurado',
          value: _largeTransactionAlertsEnabled,
          onChanged: (value) => setState(() => _largeTransactionAlertsEnabled = value),
          enabled: _pushNotificationsEnabled,
        ),
      ],
    );
  }

  Widget _buildThresholds() {
    return _buildSection(
      title: 'Umbrales de Alerta',
      icon: Icons.tune,
      children: [
        _buildSliderTile(
          title: 'Saldo Bajo',
          subtitle: '\$${_lowBalanceThreshold.toStringAsFixed(0)}',
          value: _lowBalanceThreshold,
          min: 100,
          max: 10000,
          divisions: 99,
          onChanged: _lowBalanceAlertsEnabled && _pushNotificationsEnabled
              ? (value) => setState(() => _lowBalanceThreshold = value)
              : null,
        ),
        _buildSliderTile(
          title: 'Transacción Grande',
          subtitle: '\$${_largeTransactionThreshold.toStringAsFixed(0)}',
          value: _largeTransactionThreshold,
          min: 1000,
          max: 50000,
          divisions: 49,
          onChanged: _largeTransactionAlertsEnabled && _pushNotificationsEnabled
              ? (value) => setState(() => _largeTransactionThreshold = value)
              : null,
        ),
        _buildSliderTile(
          title: 'Advertencia de Presupuesto',
          subtitle: '${_budgetWarningPercentage}%',
          value: _budgetWarningPercentage.toDouble(),
          min: 50,
          max: 95,
          divisions: 9,
          onChanged: _budgetAlertsEnabled && _pushNotificationsEnabled
              ? (value) => setState(() => _budgetWarningPercentage = value.toInt())
              : null,
        ),
      ],
    );
  }

  Widget _buildReportSettings() {
    return _buildSection(
      title: 'Reportes Automáticos',
      icon: Icons.assessment,
      children: [
        _buildSwitchTile(
          title: 'Reportes Semanales',
          subtitle: 'Resumen semanal de gastos e ingresos',
          value: _weeklyReportsEnabled,
          onChanged: (value) => setState(() => _weeklyReportsEnabled = value),
          enabled: _pushNotificationsEnabled,
        ),
        _buildSwitchTile(
          title: 'Reportes Mensuales',
          subtitle: 'Análisis mensual de tu situación financiera',
          value: _monthlyReportsEnabled,
          onChanged: (value) => setState(() => _monthlyReportsEnabled = value),
          enabled: _pushNotificationsEnabled,
        ),
      ],
    );
  }

  Widget _buildTestSection() {
    return _buildSection(
      title: 'Prueba de Notificaciones',
      icon: Icons.science,
      children: [
        ListTile(
          leading: Icon(Icons.send),
          title: Text('Enviar Notificación de Prueba'),
          subtitle: Text('Verifica que las notificaciones funcionen correctamente'),
          trailing: ElevatedButton(
            onPressed: _pushNotificationsEnabled ? _testNotification : null,
            child: Text('Enviar'),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          color: enabled 
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled 
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          contentPadding: EdgeInsets.zero,
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveNotificationSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isSaving 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.save),
        label: Text(
          _isSaving ? 'Guardando...' : 'Guardar Configuración',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
*/