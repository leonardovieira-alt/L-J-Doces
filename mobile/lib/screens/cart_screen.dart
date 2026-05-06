import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  final bool isRoot;
  final VoidCallback? onContinueShopping;

  const CartScreen({Key? key, this.isRoot = false, this.onContinueShopping}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items.values.toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: isRoot ? null : AppBar(
        title: const Text('Minha Sacola', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[50],
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Sua sacola está vazia!', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (onContinueShopping != null) {
                        onContinueShopping!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Continuar Comprando', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item.product.images.isNotEmpty ? item.product.images[0] : 'assets/images/app_icon.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.observation.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('Obs: ${item.observation}', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    'R\$ ${(item.product.price * item.quantity).toStringAsFixed(2).replaceAll('.', ',')}',
                                    style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orange[800], fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove, size: 18),
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              padding: EdgeInsets.zero,
                                              onPressed: () {
                                                context.read<CartProvider>().removeSingleItem(item.product.id);
                                              },
                                            ),
                                            Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(Icons.add, size: 18),
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              padding: EdgeInsets.zero,
                                              onPressed: () {
                                                context.read<CartProvider>().addItem(item.product, quantity: 1);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Remover Item'),
                                              content: const Text('Deseja remover este item da sacola?'),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: Text('Não', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    context.read<CartProvider>().removeItem(item.product.id);
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: const Text('Sim, Remover', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                            Text(
                              'R\$ ${cart.totalAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.orange[800]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CheckoutScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Ir para Pagamento',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
