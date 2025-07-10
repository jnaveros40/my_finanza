/*import 'package:flutter/material.dart';
import '../../models/recurring_payment.dart';
import '../../services/recurring_payment_service.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../services/firestore_service/index.dart';
import 'package:mis_finanza/services/firestore_service.dart';

class AddEditRecurringPaymentScreen extends StatefulWidget {
  final RecurringPayment? payment;
  const AddEditRecurringPaymentScreen({super.key, this.payment});

  @override
  State<AddEditRecurringPaymentScreen> createState() => _AddEditRecurringPaymentScreenState();
}

class _AddEditRecurringPaymentScreenState extends State<AddEditRecurringPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = RecurringPaymentService();
  final _firestoreService = FirestoreService();

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  List<Account> _accounts = [];
  List<Category> _categories = [];
  Account? _selectedAccount;
  Category? _selectedCategory;
  String _selectedFrequency = 'mensual';
  DateTime _selectedStartDate = DateTime.now();
  DateTime? _selectedEndDate;

  bool _isLoading = false;
  bool _isSaving = false;

  // Helper methods for modern UI consistency
  IconData _getFrequencyIcon(String frequency) {
    switch (frequency) {
      case 'mensual':
        return Icons.calendar_month;
      case 'semanal':
        return Icons.calendar_view_week;
      case 'quincenal':
        return Icons.calendar_view_day;
      case 'personalizada':
        return Icons.schedule;
      default:
        return Icons.repeat;
    }
  }

  Color _getFrequencyColor(String frequency) {
    switch (frequency) {
      case 'mensual':
        return Colors.blue.shade400;
      case 'semanal':
        return Colors.green.shade400;
      case 'quincenal':
        return Colors.orange.shade400;
      case 'personalizada':
        return Colors.purple.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  String _getFrequencyText(String frequency) {
    switch (frequency) {
      case 'mensual': return 'Mensual';
      case 'semanal': return 'Semanal';
      case 'quincenal': return 'Quincenal';
      case 'personalizada': return 'Personalizada';
      default: return frequency;
    }
  }

  final List<String> _frequencies = ['mensual', 'semanal', 'quincenal', 'personalizada'];

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.payment != null) {
      _descriptionController.text = widget.payment!.description;
      _amountController.text = widget.payment!.amount.toString();
      _notesController.text = widget.payment!.notes ?? '';
      _selectedFrequency = widget.payment!.frequency;
      _selectedStartDate = widget.payment!.startDate;
      _selectedEndDate = widget.payment!.endDate;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    _accounts = await AccountService.getAccounts().first;
    _categories = await CategoryService.getCategories().first;
    setState(() {
      if (widget.payment != null) {
        _selectedAccount = _accounts.firstWhere((a) => a.id == widget.payment!.accountId, orElse: () => _accounts.first);
        _selectedCategory = _categories.firstWhere((c) => c.id == widget.payment!.categoryId, orElse: () => _categories.first);
      } else {
        if (_accounts.isNotEmpty) _selectedAccount = _accounts.first;
        if (_categories.isNotEmpty) _selectedCategory = _categories.first;
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedStartDate = picked);
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? _selectedStartDate,
      firstDate: _selectedStartDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedEndDate = picked);
  }

  Future<DateTime> _calculateNextPaymentDate(DateTime from, String frequency) async {
    switch (frequency) {
      case 'mensual':
        return DateTime(from.year, from.month + 1, from.day);
      case 'semanal':
        return from.add(Duration(days: 7));
      case 'quincenal':
        return from.add(Duration(days: 15));
      case 'personalizada':
        // Puedes personalizar aquí según tu lógica
        return from;
      default:
        return from;
    }
  }
  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedAccount == null || _selectedCategory == null) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final userId = _selectedAccount!.userId;
      final nextPaymentDate = await _calculateNextPaymentDate(_selectedStartDate, _selectedFrequency);
      final payment = RecurringPayment(
        id: widget.payment?.id,
        userId: userId,
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        categoryId: _selectedCategory!.id!,
        accountId: _selectedAccount!.id!,
        frequency: _selectedFrequency,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        nextPaymentDate: nextPaymentDate,
      );
      
      await _service.saveRecurringPayment(payment);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.payment == null 
              ? 'Pago recurrente guardado con éxito' 
              : 'Pago recurrente actualizado con éxito'),
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple.shade200,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.repeat,
                color: Colors.purple.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.payment == null ? 'Nuevo Pago' : 'Editar Pago',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Recurrente',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.purple.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading 
          ? _buildLoadingState()
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section
                  _buildHeaderSection(),
                  // Form Section
                  _buildFormSection(),
                ],
              ),
            ),
    );
  }

  // Modern loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cargando datos...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Header section with frequency selector
  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getFrequencyColor(_selectedFrequency).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.schedule,
                  size: 20,
                  color: _getFrequencyColor(_selectedFrequency),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Frecuencia de Pago',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Frecuencia con diseño mejorado
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Seleccionar Frecuencia',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getFrequencyColor(_selectedFrequency).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFrequencyIcon(_selectedFrequency),
                    size: 20,
                    color: _getFrequencyColor(_selectedFrequency),
                  ),
                ),
              ),
              value: _selectedFrequency,
              items: _frequencies.map((String frequency) {
                return DropdownMenuItem<String>(
                  value: frequency,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getFrequencyColor(frequency).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _getFrequencyIcon(frequency),
                          size: 16,
                          color: _getFrequencyColor(frequency),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_getFrequencyText(frequency)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedFrequency = newValue;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Form section with all fields
  Widget _buildFormSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo Descripción
            _buildDescriptionField(),
            const SizedBox(height: 16),

            // Campo Monto
            _buildAmountField(),
            const SizedBox(height: 16),

            // Campo Cuenta
            _buildAccountField(),
            const SizedBox(height: 16),

            // Campo Categoría
            _buildCategoryField(),
            const SizedBox(height: 16),

            // Campos de Fecha
            _buildDateFields(),
            const SizedBox(height: 16),

            // Campo Notas
            _buildNotesField(),
            const SizedBox(height: 24),

            // Botón Guardar
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // Modern field builders
  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _descriptionController,
        decoration: InputDecoration(
          labelText: 'Descripción',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.description,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),        ),
        validator: (v) => v == null || v.isEmpty ? 'Ingrese una descripción' : null,
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _amountController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Monto',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.attach_money,
              size: 20,
              color: Colors.green.shade600,
            ),
          ),        ),
        validator: (v) => v == null || double.tryParse(v) == null ? 'Ingrese un monto válido' : null,
      ),
    );
  }

  Widget _buildAccountField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<Account>(
        decoration: InputDecoration(
          labelText: 'Cuenta asociada',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              size: 20,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        value: _selectedAccount,
        items: _accounts.map((a) => DropdownMenuItem(
          value: a, 
          child: Text('${a.name} (${a.type})')
        )).toList(),        onChanged: (a) => setState(() => _selectedAccount = a),
        validator: (v) => v == null ? 'Seleccione una cuenta' : null,
      ),
    );
  }

  Widget _buildCategoryField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<Category>(
        decoration: InputDecoration(
          labelText: 'Categoría',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.category,
              size: 20,
              color: Colors.purple.shade600,
            ),
          ),
        ),
        value: _selectedCategory,
        items: _categories.map((c) => DropdownMenuItem(
          value: c, 
          child: Text(c.name)
        )).toList(),        onChanged: (c) => setState(() => _selectedCategory = c),
        validator: (v) => v == null ? 'Seleccione una categoría' : null,
      ),
    );
  }

  Widget _buildDateFields() {
    return Column(
      children: [
        // Fecha de Inicio
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                size: 20,
                color: Colors.orange.shade600,
              ),
            ),
            title: Text(
              'Fecha de inicio',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            subtitle: Text(
              _selectedStartDate.toLocal().toString().split(' ')[0],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
            onTap: () => _selectStartDate(context),
          ),
        ),
        const SizedBox(height: 12),
        // Fecha de Fin
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.event_busy,
                size: 20,
                color: Colors.red.shade600,
              ),
            ),
            title: Text(
              'Fecha de fin',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            subtitle: Text(
              _selectedEndDate == null ? 'Sin fecha de fin' : _selectedEndDate!.toLocal().toString().split(' ')[0],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedEndDate != null)
                  IconButton(
                    icon: Icon(Icons.clear, size: 20),
                    onPressed: () => setState(() => _selectedEndDate = null),
                    color: Theme.of(context).colorScheme.outline,
                  ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ],
            ),
            onTap: () => _selectEndDate(context),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Notas (opcional)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),            child: Icon(
              Icons.note_alt,
              size: 20,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading || _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSaving 
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Guardando...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.payment == null ? Icons.add : Icons.edit,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.payment == null ? 'Guardar Pago' : 'Actualizar Pago',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
*/