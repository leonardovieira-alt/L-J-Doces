import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;

  void _processPayment() async {
    final cartProvider = context.read<CartProvider>();
    final ordersProvider = context.read<OrdersProvider>();
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated || authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para fazer um pedido')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Preparar itens do pedido
      final items = cartProvider.items.values.map((item) {
        return {
          'product_id': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.product.price,
          'observation': item.observation,
        };
      }).toList();

      // Criar pedido
      final order = await ordersProvider.createOrder(
        authProvider.token!,
        items,
        cartProvider.totalPrice,
      );

      if (order != null) {
        // Simular pagamento
        final paidOrder = await ordersProvider.simulatePayment(
          authProvider.token!,
          order.id,
        );

        if (paidOrder != null && mounted) {
          // Limpar carrinho
          cartProvider.clear();

          // Mostrar comprovante
          _showPaymentReceipt(paidOrder);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar pagamento: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showPaymentReceipt(Order order) {
    final payment = order.payment;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Pagamento Confirmado!'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Seu pedido foi realizado com sucesso!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 20),
              _buildReceiptInfo('Número do Pedido:', order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()),
              _buildReceiptInfo(
                'Comprovante:',
                payment?.receiptNumber ?? 'N/A',
              ),
              _buildReceiptInfo(
                'Valor Total:',
                'R\$ ${order.totalAmount.toStringAsFixed(2).replaceAll('.', ',')}',
              ),
              _buildReceiptInfo(
                'Status:',
                order.status.toUpperCase(),
              ),
              const SizedBox(height: 20),
              const Text(
                'Itens do Pedido:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '${item.quantity}x Produto ID: ${item.productId.length >= 8 ? item.productId.substring(0, 8) : item.productId}\nR\$ ${item.unitPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(fontSize: 12),
                ),
              )),
              const SizedBox(height: 20),
              const Text(
                'Você pode acompanhar seu pedido na seção "Minhas Compras"',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Continuar Comprando'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              // Navegar para Minhas Compras
              Navigator.pushNamed(context, '/orders');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Ver Meus Pedidos'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Checkout', style: TextStyle(color: Colors.black87)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo do pedido
            const Text(
              'Resumo do Pedido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ...cartProvider.items.values.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.quantity}x ${item.product.name}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.observation != null && item.observation!.isNotEmpty)
                                Text(
                                  'Obs: ${item.observation}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          'R\$ ${(item.quantity * item.product.price).toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'R\$ ${cartProvider.totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Informações de pagamento
            const Text(
              'Detalhes de Pagamento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Este é um pagamento simulado para teste.',
                          style: TextStyle(color: Colors.orange[600], fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Método: Pagamento Simulado\n\nSeu pedido será confirmado imediatamente após este passo.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botão de pagamento
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text(
                      'Confirmar Pagamento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
