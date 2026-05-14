import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../widgets/currency_formatter.dart';
import '../theme/app_theme.dart';

class ItemManagementScreen extends StatelessWidget {
  const ItemManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_rounded,
                color: AppTheme.primaryYellow, size: 24),
            const SizedBox(width: 8),
            const Text('Kelola Barang'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: Consumer<ItemProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_shopping_cart_rounded,
                      size: 72, color: Colors.grey.shade600),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada barang',
                    style:
                        TextStyle(fontSize: 18, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tekan + untuk menambahkan',
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 8),
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              final item = provider.items[index];
              return AnimatedContainer(
                duration: Duration(milliseconds: 200 + index * 30),
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: _buildItemAvatar(item),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      formatRupiah(item.price),
                      style: TextStyle(
                        color: AppTheme.primaryYellow,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded,
                              color: Colors.blueAccent),
                          onPressed: () =>
                              _showItemDialog(context, item: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded,
                              color: Colors.redAccent),
                          onPressed: () => _confirmDelete(context, item),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildItemAvatar(Item item) {
    if (item.imagePath != null && File(item.imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(item.imagePath!),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      );
    }
    return CircleAvatar(
      backgroundColor: AppTheme.primaryYellow.withValues(alpha: 0.15),
      child: Text(
        item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppTheme.primaryYellow,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showItemDialog(BuildContext context, {Item? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController = TextEditingController(
      text: item != null ? item.price.toStringAsFixed(0) : '',
    );
    final isEditing = item != null;
    final formKey = GlobalKey<FormState>();
    String? selectedImagePath = item?.imagePath;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit_rounded : Icons.add_circle_rounded,
                color: AppTheme.primaryYellow,
              ),
              const SizedBox(width: 8),
              Text(isEditing ? 'Edit Barang' : 'Tambah Barang'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image picker
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 85,
                      );
                      if (picked != null) {
                        final appDir = await getApplicationDocumentsDirectory();
                        final fileName =
                            'item_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
                        final savedFile =
                            await File(picked.path).copy('${appDir.path}/$fileName');
                        setDialogState(() {
                          selectedImagePath = savedFile.path;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryYellow.withValues(alpha: 0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: selectedImagePath != null &&
                              File(selectedImagePath!).existsSync()
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(selectedImagePath!),
                                    width: double.infinity,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedImagePath = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded,
                                    size: 32,
                                    color: AppTheme.primaryYellow
                                        .withValues(alpha: 0.6)),
                                const SizedBox(height: 8),
                                Text(
                                  'Tambah Foto (Opsional)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.primaryYellow
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Barang',
                      prefixIcon: Icon(Icons.label_rounded),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama barang wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Harga',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Harga wajib diisi';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Harga harus lebih dari 0';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final provider = context.read<ItemProvider>();
                final newItem = Item(
                  id: item?.id,
                  name: nameController.text.trim(),
                  price: double.parse(priceController.text),
                  imagePath: selectedImagePath,
                );
                if (isEditing) {
                  provider.updateItem(newItem);
                } else {
                  provider.addItem(newItem);
                }
                Navigator.pop(ctx);
              },
              child: Text(isEditing ? 'Simpan' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Hapus Barang'),
          ],
        ),
        content: Text('Hapus "${item.name}" dari daftar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<ItemProvider>().deleteItem(item.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
