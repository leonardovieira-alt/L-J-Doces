import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import "dart:typed_data";

import "package:image_picker/image_picker.dart";
import "package:http_parser/http_parser.dart";

import "package:dio/dio.dart";

import "package:flutter_dotenv/flutter_dotenv.dart";

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({Key? key}) : super(key: key);

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _searchQuery = '';
  String? _selectedFilterCategoryId;
  String? _selectedFilterSubcategoryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Dispara a busca inicial de dados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchCategories();
      context.read<AdminProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gerenciar Produtos',
          style:
              TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFDA516),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFDA516),
          tabs: const [
            Tab(text: 'Categorias'),
            Tab(text: 'Produtos'),
          ],
        ),
      ),
      body: adminProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFDA516)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCategoriesTab(adminProvider.categories),
                _buildProductsTab(
                    adminProvider.products, adminProvider.categories),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showCategoryDialog(context);
          } else {
            _showProductDialog(context, adminProvider.categories);
          }
        },
        backgroundColor: const Color(0xFFFDA516),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Nova Categoria' : 'Novo Produto',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCategoriesTab(List<Category> categories) {
    if (categories.isEmpty) {
      return const Center(child: Text('Nenhuma categoria cadastrada.'));
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      buildDefaultDragHandles: false,
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        return Material(
          color: Colors.transparent,
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final item = categories.removeAt(oldIndex);
        categories.insert(newIndex, item);
        context.read<AdminProvider>().updateCategoriesOrder(categories);
      },
      itemBuilder: (context, index) {
        final cat = categories[index];
        return _categoryCard(cat, index, key: ValueKey(cat.id));
      },
    );
  }

  Widget _categoryCard(Category cat, int index, {Key? key}) {
    return Card(
      key: key,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title:
            Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(cat.description),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E6),
            borderRadius: BorderRadius.circular(8),
            image: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(cat.imageUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: cat.imageUrl == null || cat.imageUrl!.isEmpty
              ? const Icon(Icons.fastfood, color: Color(0xFFFDA516))
              : null,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () => _editCategory(cat),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _confirmDeleteCategory(cat),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.open_with, color: Colors.grey),
            ),
          ],
        ),
        children: [
          const Divider(),
          if (cat.subcategories.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cat.subcategories.length,
              buildDefaultDragHandles: false,
              proxyDecorator:
                  (Widget child, int index, Animation<double> animation) {
                return Material(
                  color: Colors.transparent,
                  child: child,
                );
              },
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) newIndex -= 1;
                final subs = List<SubCategory>.from(cat.subcategories);
                final item = subs.removeAt(oldIndex);
                subs.insert(newIndex, item);
                context
                    .read<AdminProvider>()
                    .updateSubcategoriesOrder(cat.id, subs);
              },
              itemBuilder: (context, index) {
                final sub = cat.subcategories[index];
                return ListTile(
                  key: ValueKey(sub.id),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(6),
                          image:
                              sub.imageUrl != null && sub.imageUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(sub.imageUrl!),
                                      fit: BoxFit.cover)
                                  : null,
                        ),
                        child: sub.imageUrl == null || sub.imageUrl!.isEmpty
                            ? const Icon(Icons.category,
                                color: Color(0xFFFDA516), size: 20)
                            : null,
                      ),
                    ],
                  ),
                  title: Text(sub.name),
                  subtitle: Text(sub.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.blue, size: 20),
                          onPressed: () => _editSubcategory(cat.id, sub)),
                      IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red, size: 20),
                          onPressed: () => _confirmDeleteSubcategory(sub)),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.open_with,
                            color: Colors.grey, size: 20),
                      ),
                    ],
                  ),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.add, color: Color(0xFFFDA516)),
            title: const Text('Adicionar Subcategoria',
                style: TextStyle(color: Color(0xFFFDA516))),
            onTap: () => _showSubcategoryDialog(context, cat.id),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(List<Product> products, List<Category> categories) {
    final filteredProducts = products.where((p) {
      final matchesSearch =
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedFilterCategoryId == null ||
          _selectedFilterCategoryId == p.categoryId;
      final matchesSub = _selectedFilterSubcategoryId == null ||
          _selectedFilterSubcategoryId == p.subcategoryId;
      return matchesSearch && matchesCat && matchesSub;
    }).toList();

    Category? currentCategory;
    if (_selectedFilterCategoryId != null) {
      currentCategory = categories.firstWhere(
        (c) => c.id == _selectedFilterCategoryId,
        orElse: () => categories.first,
      );
    }

    return Column(
      children: [
        // Filters Section
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Pesquisar produto...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFFDA516)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedFilterCategoryId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Todas')),
                        ...categories.map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedFilterCategoryId = val;
                          _selectedFilterSubcategoryId =
                              null; // reset subcategory filter
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedFilterSubcategoryId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Subcategoria',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Todas')),
                        if (currentCategory != null)
                          ...currentCategory.subcategories.map((s) =>
                              DropdownMenuItem(
                                  value: s.id, child: Text(s.name))),
                      ],
                      onChanged: _selectedFilterCategoryId == null
                          ? null
                          : (val) => setState(
                              () => _selectedFilterSubcategoryId = val),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Product List
        Expanded(
          child: filteredProducts.isEmpty
              ? const Center(child: Text('Nenhum produto encontrado.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final prod = filteredProducts[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                            image: prod.images.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage('${prod.images.first}?v=${DateTime.now().millisecondsSinceEpoch}'),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                          child: prod.images.isEmpty
                              ? const Icon(Icons.cake, color: Colors.grey)
                              : null,
                        ),
                        title: Text(prod.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'R\$ ${prod.price.toStringAsFixed(2).replaceAll('.', ',')} • Estoque: ${prod.stockQuantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.blue, size: 20),
                              onPressed: () => _editProduct(context, prod,
                                  context.read<AdminProvider>().categories),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red, size: 20),
                              onPressed: () => _confirmDeleteProduct(prod),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _ImagePickerModal(
        isSubcategory: false,
        onSave: (name, desc, imageUrl) async {
          final adminProvider = context.read<AdminProvider>();
          await adminProvider.createCategory(Category(
            id: '',
            name: name,
            description: desc,
            imageUrl: imageUrl,
          ));
        },
      ),
    );
  }

  void _showSubcategoryDialog(BuildContext context, String catId) {
    showDialog(
      context: context,
      builder: (ctx) => _ImagePickerModal(
        isSubcategory: true,
        onSave: (name, desc, imageUrl) async {
          final adminProvider = context.read<AdminProvider>();
          await adminProvider.createSubcategory(SubCategory(
            id: '',
            categoryId: catId,
            name: name,
            description: desc,
            imageUrl: imageUrl,
          ));
        },
      ),
    );
  }

  void _editCategory(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => _ImagePickerModal(
        isSubcategory: false,
        initialName: cat.name,
        initialDesc: cat.description,
        initialImageUrl: cat.imageUrl,
        onSave: (name, desc, imageUrl) async {
          final adminProvider = context.read<AdminProvider>();
          await adminProvider.updateCategory(cat.id, Category(
            id: cat.id,
            name: name,
            description: desc,
            imageUrl: imageUrl ?? cat.imageUrl,
          ));
        },
      ),
    );
  }

  void _confirmDeleteCategory(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: Text('Deseja excluir a categoria "${cat.name}"? TUDO associado a ela pode sumir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AdminProvider>().deleteCategory(cat.id);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editSubcategory(String catId, SubCategory sub) {
    showDialog(
      context: context,
      builder: (ctx) => _ImagePickerModal(
        isSubcategory: true,
        initialName: sub.name,
        initialDesc: sub.description,
        initialImageUrl: sub.imageUrl,
        onSave: (name, desc, imageUrl) async {
          final adminProvider = context.read<AdminProvider>();
          await adminProvider.updateSubcategory(sub.id, SubCategory(
            id: sub.id,
            categoryId: catId,
            name: name,
            description: desc,
            imageUrl: imageUrl ?? sub.imageUrl,
          ));
        },
      ),
    );
  }

  void _confirmDeleteSubcategory(SubCategory sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Subcategoria'),
        content: Text('Deseja excluir a subcategoria "${sub.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AdminProvider>().deleteSubcategory(sub.id);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(BuildContext context, List<Category> categories) {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crie uma categoria primeiro.')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _ProductModal(categories: categories),
    );
  }

  void _editProduct(
      BuildContext context, Product product, List<Category> categories) {
    if (categories.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => _ProductModal(categories: categories, product: product),
    );
  }

  void _confirmDeleteProduct(Product prod) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Excluir Produto?'),
              content: Text('Tem certeza que deseja excluir "${prod.name}"?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await context.read<AdminProvider>().deleteProduct(prod.id);
                  },
                  child: const Text('Excluir',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ));
  }
}

class _ProductModal extends StatefulWidget {
  final List<Category> categories;
  final Product? product;

  const _ProductModal({Key? key, required this.categories, this.product})
      : super(key: key);

  @override
  State<_ProductModal> createState() => _ProductModalState();
}

class _ProductModalState extends State<_ProductModal> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ingrCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');

  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  bool _isUploading = false;

  List<Map<String, dynamic>> _selectedImages = []; // store bytes and name
  final Map<int, bool> _availableDays = {
    0: false,
    1: false,
    2: false,
    3: false,
    4: false,
    5: false,
    6: false
  };

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description;
      _ingrCtrl.text = p.ingredients;
      _priceCtrl.text = p.price.toStringAsFixed(2).replaceAll('.', ',');
      _costPriceCtrl.text = p.costPrice.toStringAsFixed(2).replaceAll('.', ',');
      _stockCtrl.text = p.stockQuantity.toString();
      _selectedCategoryId = p.categoryId;
      _selectedSubcategoryId = p.subcategoryId;
      _availableDays.addAll(p.availableDays);
      _selectedImages =
          p.images.map<Map<String, dynamic>>((url) => {'url': '$url?v=${DateTime.now().millisecondsSinceEpoch}'}).toList();
    } else if (widget.categories.isNotEmpty) {
      _selectedCategoryId = widget.categories.first.id;
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Máximo de 5 imagens permitido.')));
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage();
      if (picked.isNotEmpty) {
        for (var image in picked) {
          if (_selectedImages.length >= 5) break;
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImages.add({'bytes': bytes, 'name': image.name});
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao abrir galeria: $e');
    }
  }

  Future<String?> _uploadSingleImageToCloudinary(
      Dio dio, Uint8List bytes, String name) async {
    try {
final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';

      final ext = name.split('.').last.toLowerCase();
      final mimeType = (ext == 'png') ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');

      var formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: name,
            contentType: MediaType('image', mimeType),
          ),
        });

        var response = await dio.post('$baseUrl/upload/image', data: formData);
        return response.data['url'];
      } catch (e) {
        if (e is DioException) {
          debugPrint('Erro upload image API: ${e.response?.data}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Erro no upload: ${e.response?.data?['message'] ?? e.response?.data ?? e.message}')));
          }
        } else {
          debugPrint('Erro upload single image: $e');
        }
        return null;
      }
  }

  Future<void> _handleSave() async {
    if (_nameCtrl.text.trim().isEmpty || _selectedCategoryId == null) return;

    setState(() => _isUploading = true);

    final dio = Dio();
    final StorageService storageService = StorageService();
    await storageService.init();
    final token = storageService.getToken();

    if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';

    List<String> uploadedUrls = [];
    int uploadIndex = 0;

    for (var img in _selectedImages) {
      if (img.containsKey('url')) {
        uploadedUrls.add(img['url']);
      } else {
        final originalName = img['name'] ?? 'image.jpg';
        final uniqueName =
            '${DateTime.now().millisecondsSinceEpoch}_${uploadIndex}_$originalName';
        final url =
            await _uploadSingleImageToCloudinary(dio, img['bytes'], uniqueName);
        if (url != null) uploadedUrls.add(url);
        uploadIndex++;
      }
    }

    final adminProvider = context.read<AdminProvider>();
    final newProduct = Product(
      id: widget.product?.id ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      ingredients: _ingrCtrl.text.trim(),
      categoryId: _selectedCategoryId!,
      subcategoryId: _selectedSubcategoryId,
      images: uploadedUrls,
      stockQuantity: int.tryParse(_stockCtrl.text) ?? 0,
      costPrice: double.tryParse(_costPriceCtrl.text.replaceAll(',', '.')) ?? 0.0,
        price: double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0.0,
      availableDays: _availableDays,
    );

    if (widget.product == null) {
      await adminProvider.createProduct(newProduct);
    } else {
      await adminProvider.updateProduct(widget.product!.id, newProduct);
    }

    if (mounted) {
      setState(() => _isUploading = false);
      Navigator.pop(context);
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0F172A)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayChip(int dayIndex, String label) {
    final bool isSelected = _availableDays[dayIndex] ?? false;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool val) {
        setState(() {
          _availableDays[dayIndex] = val;
        });
      },
      selectedColor: const Color(0xFFFDA516).withOpacity(0.2),
      checkmarkColor: const Color(0xFFFDA516),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFFDA516) : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Category? currentCategory;
    if (_selectedCategoryId != null) {
      currentCategory = widget.categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
          orElse: () => widget.categories.first);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              widget.product == null ? 'Novo Produto' : 'Editar Produto',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader('Fotos do Produto', Icons.photo_library),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Imagens (Mínimo 1, Máximo 5)',
                              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ..._selectedImages.asMap().entries.map((e) {
                                final imgMap = e.value;
                                final isNetwork = imgMap.containsKey('url');

                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                            image: isNetwork
                                                ? NetworkImage(imgMap['url']) as ImageProvider
                                                : MemoryImage(imgMap['bytes']),
                                            fit: BoxFit.cover),
                                      ),
                                    ),
                                    Positioned(
                                      right: -6,
                                      top: -6,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _selectedImages.removeAt(e.key)),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                              color: Colors.red.shade600,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2)),
                                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                              if (_selectedImages.length < 5)
                                GestureDetector(
                                  onTap: _pickImages,
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7E6),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFFDA516), width: 1, style: BorderStyle.solid),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_rounded, color: Color(0xFFFDA516), size: 24),
                                        SizedBox(height: 4),
                                        Text('Adicionar', style: TextStyle(color: Color(0xFFFDA516), fontSize: 11, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSectionHeader('Informações Principais', Icons.info_outline),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                                labelText: 'Nome do Produto',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                prefixIcon: const Icon(Icons.shopping_bag_outlined)),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategoryId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                      labelText: 'Categoria',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      prefixIcon: const Icon(Icons.category_outlined)),
                                  items: widget.categories
                                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedCategoryId = val;
                                      _selectedSubcategoryId = null; // reset subcategory on category change
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedSubcategoryId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                      labelText: 'Subcategoria',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      prefixIcon: const Icon(Icons.subdirectory_arrow_right)),
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('Nenhuma', overflow: TextOverflow.ellipsis)),
                                    if (currentCategory != null)
                                      ...currentCategory.subcategories.map(
                                          (s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))),
                                  ],
                                  onChanged: (val) => setState(() => _selectedSubcategoryId = val),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSectionHeader('Detalhes da Receita', Icons.receipt_long_outlined),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _descCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                                labelText: 'Descrição Curta',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _ingrCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                                labelText: 'Ingredientes (Opcional)',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSectionHeader('Financeiro & Estoque', Icons.attach_money),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _costPriceCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                      labelText: 'Custo',
                                      prefixText: 'R\$ ',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _priceCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                      labelText: 'Venda',
                                      prefixText: 'R\$ ',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                labelText: 'Estoque Atual',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSectionHeader('Disponibilidade', Icons.calendar_today_outlined),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dias que este produto é vendido:',
                              style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _dayChip(0, 'Dom'),
                              _dayChip(1, 'Seg'),
                              _dayChip(2, 'Ter'),
                              _dayChip(3, 'Qua'),
                              _dayChip(4, 'Qui'),
                              _dayChip(5, 'Sex'),
                              _dayChip(6, 'Sáb'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isUploading ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isUploading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDA516),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    elevation: 0,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Salvar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerModal extends StatefulWidget {
  final bool isSubcategory;
  final String? initialName;
  final String? initialDesc;
  final String? initialImageUrl;
  final Future<void> Function(String name, String desc, String? imageUrl) onSave;

  const _ImagePickerModal({
    Key? key,
    required this.isSubcategory,
    this.initialName,
    this.initialDesc,
    this.initialImageUrl,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_ImagePickerModal> createState() => _ImagePickerModalState();
}

class _ImagePickerModalState extends State<_ImagePickerModal> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _existingImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.initialName ?? '';
    _descCtrl.text = widget.initialDesc ?? '';
    _existingImageUrl = widget.initialImageUrl;
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = picked.name;
        });
      }
    } catch (e) {
      debugPrint('Erro ao abrir galeria: $e');
    }
  }

  Future<String?> _uploadToCloudinary() async {
    if (_selectedImageBytes == null) return null;
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
      final dio = Dio();

      final StorageService _storageService = StorageService();
      await _storageService.init();
      final token = _storageService.getToken();

      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final name = _selectedImageName ?? 'image.jpg';
      final ext = name.split('.').last.toLowerCase();
      final mimeType = (ext == 'png') ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');

      var formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          _selectedImageBytes!,
          filename: name,
          contentType: MediaType('image', mimeType),
        ),
      });

      var response = await dio.post('$baseUrl/upload/image', data: formData);
      return response.data['url'];
    } catch (e) {
      if (e is DioException) {
        debugPrint('Erro API Cloudinary: ${e.response?.data}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Erro no upload: ${e.response?.data?['message'] ?? e.response?.data ?? e.message}')));
        }
      } else {
        debugPrint('Erro no upload para a API: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro no upload: $e')));
        }
      }
      return null;
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isUploading = true);

    String? imageUrl = _existingImageUrl;
    if (_selectedImageBytes != null) {
      imageUrl = await _uploadToCloudinary();
    }

    await widget.onSave(_nameCtrl.text.trim(), _descCtrl.text.trim(), imageUrl);

    if (mounted) {
      setState(() => _isUploading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.initialName != null && widget.initialName!.isNotEmpty
                    ? (widget.isSubcategory ? 'Editar Subcategoria' : 'Editar Categoria')
                    : (widget.isSubcategory ? 'Nova Subcategoria' : 'Nova Categoria'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Imagem Principal',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async => await _pickImage(),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFDA516), width: 2, style: BorderStyle.solid),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFFDA516).withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
                          ],
                        ),
                        child: _selectedImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                              )
                            : _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_rounded, color: Color(0xFFFDA516), size: 40),
                                      SizedBox(height: 8),
                                      Text('Adicionar\nImagem',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Color(0xFFFDA516), fontSize: 13, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: const Icon(Icons.label_outline, color: Colors.grey),
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFFDA516), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descrição',
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.description_outlined, color: Colors.grey),
                        ),
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFFDA516), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isUploading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDA516),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Salvar',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}