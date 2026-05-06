import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/favorites_provider.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../widgets/favorite_icon.dart';
import 'cart_screen.dart';
import '../widgets/favorite_icon.dart';
import 'cart_screen.dart';
import 'product_screen.dart';
import 'orders_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatefulWidget {
  static final GlobalKey<_HomeScreenState> globalKey = GlobalKey<_HomeScreenState>();

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchCategories();
      context.read<AdminProvider>().fetchProducts();
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated && authProvider.token != null) {
        context.read<FavoritesProvider>().fetchFavorites(authProvider.token!);
      }
    });
  }

  Widget _buildGrid(List<Product> products) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final prod = products[index];
          final imageUrl = prod.images.isNotEmpty
              ? '${prod.images.first}?v=${DateTime.now().millisecondsSinceEpoch}'
              : 'assets/images/app_icon.png';

          return Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, child) {
              final isFav = favoritesProvider.isFavorite(prod.id);
              final authProvider = context.read<AuthProvider>();

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductScreen(product: prod),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagem do produto e badges
                      Expanded(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),

                            // Tag de disponibilidade
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: prod.isAvailableToday
                                      ? Colors.green.withOpacity(0.9)
                                      : Colors.red.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  prod.isAvailableToday ? 'Disponível hoje' : 'Indisponível hoje',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                                ),
                              )
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prod.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            // Preço com . em vez de , pra BR
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 6,
                                    children: [
                                      Text(
                                        'R\$ ${prod.price.toStringAsFixed(2).replaceAll('.', ',')}',
                                        style: TextStyle(
                                          color: Colors.orange[600],
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (!prod.isAvailableToday)
                                        Text(
                                          '(${prod.availableDaysString})',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (authProvider.isAuthenticated && authProvider.token != null) {
                                      favoritesProvider.toggleFavorite(authProvider.token!, prod.id);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Faça login para favoritar produtos.')),
                                      );
                                    }
                                  },
                                  child: FavoriteIcon(
                                    isFavorite: isFav,
                                    size: 20,
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
              );
            }
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final adminProvider = context.watch<AdminProvider>();

    final isAuthenticated = authProvider.isAuthenticated;
    final user = authProvider.user;

    final categories = adminProvider.categories;
    var rawProducts = adminProvider.products;

    if (_selectedCategoryId != null) {
      rawProducts = rawProducts
          .where((p) => p.categoryId == _selectedCategoryId)
          .toList();
      if (_selectedSubcategoryId != null) {
        rawProducts = rawProducts
            .where((p) => p.subcategoryId == _selectedSubcategoryId)
            .toList();
      }
    }

    // Identificar categoria atualmente selecionada para resgatar/mostrar subcategorias
    Category? currentSelectedCategory;
    if (_selectedCategoryId != null) {
      currentSelectedCategory = categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
          orElse: () => categories.first);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Logo na esquerda
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Image(
                      image: AssetImage('lib/assets/images/app_icon.png'),
                      height: 45,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Espaço flexível
                  const Expanded(child: SizedBox()),
                  // Ícone de admin (se aplicável)
                  if (isAuthenticated && user != null && user.isAdmin)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.admin_panel_settings, color: Colors.amber, size: 24),
                        tooltip: 'Painel de Administração',
                        onPressed: () {
                          Navigator.pushNamed(context, '/admin');
                        },
                      ),
                    ),
                  // Menu hambúrguer na direita
                  IconButton(
                    icon: const Icon(Icons.menu, color: Color(0xFF0F172A), size: 30),
                    onPressed: () {
                      if (isAuthenticated) {
                        _showProfileBottomSheet(context, authProvider);
                      } else {
                        Navigator.pushNamed(context, '/signin');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          SingleChildScrollView(
        child: Column(
          children: [
            // Banner Section
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 200,
              decoration: const BoxDecoration(
                color: Colors.orange,
              ),
              child: Stack(
                children: [
                  // Imagem de fundo/bolo preenchendo a direita
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Image.network(
                      'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&q=80',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Gradiente para não cortar seco
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange,
                            Colors.orange,
                            Colors.orange.withOpacity(0.8),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.4, 0.6, 1.0],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  // Conteúdo do Banner
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'BOLO DE\nCENOURA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -4),
                          child: const Text(
                            'Vegano',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 24,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.local_fire_department,
                              color: Colors.deepOrange, size: 20),
                          label: const Text(
                            'Peça Agora',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Dots indicator (Estático por enquanto)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.black87, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.black38, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Categorias Horizontais
            if (categories.isNotEmpty)
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1, // +1 para a opção "Todos"
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelectedAll = _selectedCategoryId == null;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = null;
                            _selectedSubcategoryId = null;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: isSelectedAll
                                    ? Colors.orange
                                    : Colors.grey[200],
                                child: Icon(Icons.grid_view,
                                    color: isSelectedAll
                                        ? Colors.white
                                        : Colors.grey[600],
                                    size: 30),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Todos',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelectedAll
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelectedAll
                                        ? Colors.orange
                                        : Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final cat = categories[index - 1];
                    final isSelected = _selectedCategoryId == cat.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = cat.id;
                          _selectedSubcategoryId =
                              null; // reseta subcategoria ao mudar categoria principal
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor:
                                  isSelected ? Colors.orange : Colors.grey[200],
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.orange, width: 3)
                                      : null,
                                  image: cat.imageUrl != null &&
                                          cat.imageUrl!.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(cat.imageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: cat.imageUrl == null ||
                                        cat.imageUrl!.isEmpty
                                    ? Icon(Icons.fastfood,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[500])
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cat.name,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.orange
                                      : Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Subcategorias Dinamicas em Chips abaixo da categoria selecionada
            if (currentSelectedCategory != null &&
                currentSelectedCategory.subcategories.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _selectedSubcategoryId == null,
                        selectedColor: Colors.orange.shade100,
                        onSelected: (val) {
                          setState(() {
                            _selectedSubcategoryId = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...currentSelectedCategory.subcategories.map((sub) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(sub.name),
                            selected: _selectedSubcategoryId == sub.id,
                            selectedColor: Colors.orange.shade100,
                            avatar:
                                sub.imageUrl != null && sub.imageUrl!.isNotEmpty
                                    ? CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(sub.imageUrl!))
                                    : const Icon(Icons.category, size: 16),
                            onSelected: (val) {
                              setState(() {
                                _selectedSubcategoryId = val ? sub.id : null;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

            // Grade de Produtos
            if (adminProvider.isLoading)
              const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: CircularProgressIndicator(color: Colors.orange)))
            else if (rawProducts.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: Text('Nenhum produto cadastrado',
                          style: TextStyle(color: Colors.grey))))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  (() {
                    final dispHoje =
                        rawProducts.where((p) => p.isAvailableToday).toList();
                    if (dispHoje.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                          child: Text(
                            'Disponível hoje',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        _buildGrid(dispHoje),
                      ],
                    );
                  })(),
                  (() {
                    final outrosDias =
                        rawProducts.where((p) => !p.isAvailableToday).toList();
                    if (outrosDias.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                          child: Text(
                            'Programados para outros dias',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        _buildGrid(outrosDias),
                      ],
                    );
                  })(),
                ],
              ),
          ],
        ),
      ),
          CartScreen(
            isRoot: true,
            onContinueShopping: () {
              setState(() {
                _currentIndex = 0;
              });
            },
          ),
          const OrdersScreen(showBackButton: false),
          const Center(child: Text('Configurações em breve', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange[800],
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Catálogo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Sacola',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Compras',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }

  void _showProfileBottomSheet(
      BuildContext context, AuthProvider authProvider) {
    if (authProvider.user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                // Modal Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    children: [
                      // Header do usuário
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFFFDA516).withOpacity(0.2),
                            backgroundImage: authProvider.user!.picture != null
                                ? NetworkImage(authProvider.user!.picture!)
                                : null,
                            child: authProvider.user!.picture == null
                                ? const Icon(Icons.person, size: 30, color: Color(0xFFFDA516))
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authProvider.user!.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                Text(
                                  authProvider.user!.email,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // MINHA CONTA
                      const Text(
                        'MINHA CONTA',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.person_outline, color: Color(0xFF0F172A)),
                        title: const Text('Informações da conta'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.payment, color: Color(0xFF0F172A)),
                        title: const Text('Pagamentos'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.receipt_long, color: Color(0xFF0F172A)),
                        title: const Text('Meus Pedidos'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          Navigator.maybePop(context);
                          setState(() {
                            _currentIndex = 2; // Índice da aba "Compras"
                          });
                        },
                      ),

                      const Divider(height: 32),

                      // USO DE PRIVACIDADE
                      const Text(
                        'USO E PRIVACIDADE',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.tune, color: Color(0xFF0F172A)),
                        title: const Text('Preferências'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.shield_outlined, color: Color(0xFF0F172A)),
                        title: const Text('Direitos e Solicitações'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {},
                      ),

                      const Divider(height: 32),

                      // AJUDA
                      const Text(
                        'AJUDA',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.help_outline, color: Color(0xFF0F172A)),
                        title: const Text('Dúvidas frequentes'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF0F172A)),
                        title: const Text('Fale com a gente'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {},
                      ),

                      const SizedBox(height: 32),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await authProvider.logout();
                          if (context.mounted) {
                            Navigator.maybePop(context);
                          }
                        },
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text('Sair da Conta', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.withOpacity(0.5)),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
