/*import 'package:flutter/material.dart';
import '../../models/recurring_payment.dart';
import '../../services/recurring_payment_service.dart';
import 'add_edit_recurring_payment_screen.dart';

class RecurringPaymentsScreen extends StatefulWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  State<RecurringPaymentsScreen> createState() => _RecurringPaymentsScreenState();
}

class _RecurringPaymentsScreenState extends State<RecurringPaymentsScreen> {
  final RecurringPaymentService _service = RecurringPaymentService();
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  // Helper methods for modern UI consistency
  IconData _getFrequencyIcon(String frequency) {
    switch (frequency) {
      case 'mensual':
        return Icons.calendar_month;
      case 'semanal':
        return Icons.calendar_view_week;
      case 'quincenal':
        return Icons.date_range;
      case 'personalizada':
        return Icons.schedule;
      default:
        return Icons.repeat;
    }
  }

  Color _getFrequencyColor(String frequency) {
    switch (frequency) {
      case 'mensual':
        return Colors.blue.shade500;
      case 'semanal':
        return Colors.green.shade500;
      case 'quincenal':
        return Colors.orange.shade500;
      case 'personalizada':
        return Colors.purple.shade500;
      default:
        return Colors.grey.shade500;
    }
  }

  Color _getPaymentStatusColor(DateTime nextDate) {
    final now = DateTime.now();
    final difference = nextDate.difference(now).inDays;
    
    if (difference <= 0) {
      return Colors.red.shade500; // Vencido
    } else if (difference <= 3) {
      return Colors.orange.shade500; // Próximo a vencer
    } else if (difference <= 7) {
      return Colors.blue.shade500; // Esta semana
    } else {
      return Colors.green.shade500; // Futuro
    }
  }

  String _getPaymentStatusText(DateTime nextDate) {
    final now = DateTime.now();
    final difference = nextDate.difference(now).inDays;
    
    if (difference <= 0) {
      return 'Vencido';
    } else if (difference <= 3) {
      return 'Próximo';
    } else if (difference <= 7) {
      return 'Esta semana';
    } else {
      return 'Futuro';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _service.updateAllNextPaymentDates();
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
                  'Pagos Recurrentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Gestiona tus pagos automáticos',
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () async {
                final result = await showSearch<String?>(
                  context: context,
                  delegate: _RecurringPaymentSearchDelegate(_service),
                );
                if (result != null && result.isNotEmpty) {
                  setState(() {
                    _searchText = result;
                    _searchController.text = result;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<RecurringPayment>>(
        stream: _service.getRecurringPayments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }
          
          var payments = snapshot.data ?? [];
          if (_searchText.isNotEmpty) {
            payments = payments.where((p) => 
              p.description.toLowerCase().contains(_searchText.toLowerCase())
            ).toList();
          }
          
          if (payments.isEmpty) {
            return _buildEmptyState();
          }
          
          return _buildPaymentsList(payments);
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditRecurringPaymentScreen(),
              ),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add, size: 24),
          label: const Text(
            'Nuevo Pago',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
            'Cargando pagos recurrentes...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Modern empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.purple.shade200,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.repeat_outlined,
              size: 48,
              color: Colors.purple.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchText.isNotEmpty 
                ? 'No se encontraron pagos recurrentes'
                : 'No hay pagos recurrentes registrados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchText.isNotEmpty
                ? 'Intenta con otros términos de búsqueda'
                : 'Agrega tu primer pago recurrente para comenzar',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchText.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchText = '';
                  _searchController.clear();
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar búsqueda'),
            ),
          ],
        ],
      ),
    );
  }

  // Modern payments list
  Widget _buildPaymentsList(List<RecurringPayment> payments) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, i) {
        final payment = payments[i];
        final nextDate = _getNextPaymentDate(payment, DateTime.now());
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildPaymentTile(payment, nextDate),
        );
      },
    );
  }

  // Modern payment tile
  Widget _buildPaymentTile(RecurringPayment payment, DateTime nextDate) {
    final statusColor = _getPaymentStatusColor(nextDate);
    final statusText = _getPaymentStatusText(nextDate);
    
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditRecurringPaymentScreen(payment: payment),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with title and status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getFrequencyColor(payment.frequency).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getFrequencyColor(payment.frequency).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getFrequencyIcon(payment.frequency),
                        color: _getFrequencyColor(payment.frequency),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.description,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Delete button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        onPressed: () => _showDeleteDialog(payment),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Payment details
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.attach_money,
                        label: 'Monto',
                        value: '\$${payment.amount.toStringAsFixed(2)}',
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.schedule,
                        label: 'Frecuencia',
                        value: _getFrequencyText(payment.frequency),
                        color: _getFrequencyColor(payment.frequency),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailItem(
                  icon: Icons.calendar_today,
                  label: 'Próximo pago',
                  value: _formatDate(nextDate),
                  color: statusColor,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          if (fullWidth) ...[
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ] else ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Delete confirmation dialog
  void _showDeleteDialog(RecurringPayment payment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_outlined,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Confirmar eliminación'),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar el pago recurrente "${payment.description}"?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _service.deleteRecurringPayment(payment.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pago recurrente "${payment.description}" eliminado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // Helpers para la UI
  String _getFrequencyText(String freq) {
    switch (freq) {
      case 'mensual': return 'Mensual';
      case 'semanal': return 'Semanal';
      case 'quincenal': return 'Quincenal';
      case 'personalizada': return 'Personalizada';
      default: return freq;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime _getNextPaymentDate(RecurringPayment p, DateTime from) {
    DateTime next = p.startDate;
    while (next.isBefore(from) || next.isAtSameMomentAs(from) == false) {
      switch (p.frequency) {
        case 'mensual':
          next = DateTime(next.year, next.month + 1, next.day);
          break;
        case 'semanal':
          next = next.add(Duration(days: 7));
          break;
        case 'quincenal':
          next = next.add(Duration(days: 15));
          break;
        default:
          return p.startDate;
      }
      if (next.isAfter(from)) break;
    }
    return next;
  }
}

class _RecurringPaymentSearchDelegate extends SearchDelegate<String?> {
  final RecurringPaymentService service;
  _RecurringPaymentSearchDelegate(this.service);

  @override
  String get searchFieldLabel => 'Buscar pago recurrente';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder<List<RecurringPayment>>(
      stream: service.getRecurringPayments(),
      builder: (context, snapshot) {
        final results = (snapshot.data ?? []).where((p) => p.description.toLowerCase().contains(query.toLowerCase())).toList();
        if (results.isEmpty) {
          return Center(child: Text('No se encontraron resultados.'));
        }
        return ListView(
          children: results.map((p) => ListTile(
            title: Text(p.description),
            onTap: () => close(context, p.description),
          )).toList(),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
*/