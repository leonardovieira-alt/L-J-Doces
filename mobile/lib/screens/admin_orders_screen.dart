import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/orders_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/admin_provider.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _filterStatus = 'all';
  String? _loadedToken;
  late final AuthProvider _authProvider;
  final TextEditingController _orderSearchController = TextEditingController();
  String _orderSearchQuery = '';
  bool _scanMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _authProvider = context.read<AuthProvider>();
      _authProvider.addListener(_onAuthChanged);
      _maybeLoadOrders();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoadOrders();
  }

  void _maybeLoadOrders() {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    if (!authProvider.isAuthenticated || token == null) {
      return;
    }

    if (_loadedToken == token) {
      return;
    }

    _loadedToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ordersProvider = context.read<OrdersProvider>();
      final adminProvider = context.read<AdminProvider>();
      // Garantir que produtos estejam carregados para exibir nomes
      if (adminProvider.products.isEmpty) {
        adminProvider.fetchProducts();
      }
      ordersProvider.fetchAllOrders(token);
    });
  }

  void _onAuthChanged() {
    if (!mounted) return;
    _maybeLoadOrders();
  }

  @override
  void dispose() {
    try {
      _authProvider.removeListener(_onAuthChanged);
    } catch (_) {}
    _orderSearchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pendente';
      case 'confirmed':
        return 'Confirmado';
      case 'delivered':
        return 'Entregue';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Gerenciar Pedidos', style: TextStyle(color: Colors.black87)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndScanSection(),
          // Filtros
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', 'all'),
                  _buildFilterChip('Pendentes', 'pending'),
                  _buildFilterChip('Confirmados', 'confirmed'),
                  _buildFilterChip('Entregues', 'delivered'),
                  _buildFilterChip('Cancelados', 'cancelled'),
                ],
              ),
            ),
          ),
          // Lista de pedidos
          Expanded(
            child: Consumer<OrdersProvider>(
              builder: (context, ordersProvider, child) {
                if (ordersProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  );
                }

                if (ordersProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Erro: ${ordersProvider.error}'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            final token = context.read<AuthProvider>().token;
                            if (token != null) context.read<OrdersProvider>().fetchAllOrders(token);
                          },
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }

                var orders = ordersProvider.orders;
                if (_filterStatus != 'all') {
                  orders = orders.where((o) => o.status.toLowerCase() == _filterStatus).toList();
                }

                if (_orderSearchQuery.isNotEmpty) {
                  final query = _orderSearchQuery.toLowerCase();
                  orders = orders.where((o) {
                    final shortId = o.id.length >= 8 ? o.id.substring(0, 8).toLowerCase() : o.id.toLowerCase();
                    final fullId = o.id.toLowerCase();
                    final customerName = (o.customerName ?? '').toLowerCase();
                    return shortId.contains(query) || fullId.contains(query) || customerName.contains(query);
                  }).toList();
                }

                if (orders.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhum pedido encontrado',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(context, order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndScanSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Localizar pedido',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _orderSearchController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar por # ou cliente',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _orderSearchQuery = value.trim();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _orderSearchController.clear();
                    _orderSearchQuery = '';
                    _scanMode = false;
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Limpar'),
              ),
              const Spacer(),
              if (_scanMode)
                const Text(
                  'Modo scan ativo',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openScanner() async {
    setState(() {
      _scanMode = true;
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Stack(
            children: [
              MobileScanner(
                onDetect: (capture) {
                  if (capture.barcodes.isEmpty) return;
                  final barcode = capture.barcodes.first;
                  final value = barcode?.rawValue ?? barcode?.displayValue;
                  if (value == null || value.isEmpty) return;

                  Navigator.of(context).pop();
                  _applyScannedValue(value);
                },
              ),
              Positioned(
                top: 48,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Aponte a câmera para o QR do pedido',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (mounted) {
      setState(() {
        _scanMode = false;
      });
    }
  }

  void _applyScannedValue(String value) {
    final cleaned = value.trim();
    setState(() {
      _orderSearchController.text = cleaned;
      _orderSearchQuery = cleaned;
    });
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _filterStatus == value,
        onSelected: (selected) {
          setState(() {
            _filterStatus = value;
          });
        },
        selectedColor: Colors.orange,
        labelStyle: TextStyle(
          color: _filterStatus == value ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final adminProvider = context.read<AdminProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  if (order.customerName != null)
                    Text(
                      order.customerName!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${order.totalAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusLabel(order.status),
                style: TextStyle(
                  color: _getStatusColor(order.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Itens do Pedido',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) {
                  // Tentar resolver nome do produto a partir do AdminProvider
                  String productName = 'Produto';
                  try {
                    final prod = adminProvider.products.firstWhere((p) => p.id == item.productId);
                    productName = prod.name;
                  } catch (_) {
                    productName = 'Produto';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${item.quantity}x $productName\nR\$ ${item.unitPrice.toStringAsFixed(2).replaceAll('.', ',')} (Subtotal: R\$ ${(item.quantity * item.unitPrice).toStringAsFixed(2).replaceAll('.', ',')})',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
                const Text(
                  'QR Code',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: QrImageView(
                      data: order.id,
                      size: 150.0,
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Ações',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                if (order.status.toLowerCase() != 'delivered' && order.status.toLowerCase() != 'cancelled')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(order.id, 'delivered'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Marcar como Entregue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (order.status.toLowerCase() != 'cancelled' && order.status.toLowerCase() != 'delivered')
                  Column(
                    children: [
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _updateOrderStatus(order.id, 'cancelled'),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancelar Pedido'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateOrderStatus(String orderId, String newStatus) {
    final authProvider = context.read<AuthProvider>();
    final ordersProvider = context.read<OrdersProvider>();

    if (authProvider.token == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Ação'),
        content: Text('Alterar status para ${_getStatusLabel(newStatus)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                final updatedOrder = await ordersProvider.updateOrderStatus(
                  authProvider.token!,
                  orderId,
                  newStatus,
                );

                if (updatedOrder != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status atualizado com sucesso!')),
                  );
                  setState(() {}); // Atualizar UI
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: ${ordersProvider.error}')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao atualizar status: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getStatusColor(newStatus),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
