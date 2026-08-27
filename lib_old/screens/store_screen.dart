import 'package:flutter/material.dart';
import 'package:ayam_chat/controllers/store_controller.dart';
import 'package:ayam_chat/controllers/wallet_controller.dart';
import 'package:ayam_chat/controllers/inventory_controller.dart';
import 'package:ayam_chat/controllers/user_controller.dart';
import 'package:ayam_chat/models/store_item.dart';
import 'package:ayam_chat/screens/inventory_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final StoreController storeController = StoreController();
  final WalletController walletController = WalletController();
  final InventoryController inventoryController = InventoryController();
  final UserController userController = UserController();

  @override
  void initState() {
    super.initState();
    storeController.addListener(_refresh);
    walletController.addListener(_refresh);
    inventoryController.addListener(_refresh);
    userController.addListener(_refresh);
  }

  @override
  void dispose() {
    storeController.removeListener(_refresh);
    walletController.removeListener(_refresh);
    inventoryController.removeListener(_refresh);
    userController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _handlePurchase(StoreItem item) {
    final theme = Theme.of(context);
    if (inventoryController.isOwned(item.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أنت تملك هذا العنصر بالفعل')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        shape: theme.dialogTheme.shape,
        title: Text('تأكيد الشراء', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
          'هل تريد شراء ${item.name} مقابل ${item.price.toInt()} ماسة؟',
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.54))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              bool success = walletController.buyItem(item);
              if (success) {
                storeController.purchaseItem(item);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم شراء ${item.name} بنجاح! تم إضافتها إلى حقيبتك.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('رصيدك غير كافٍ')),
                );
              }
            },
            child: Text('شراء', style: TextStyle(color: theme.colorScheme.onSecondary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.cardColor,
          elevation: 0,
          title: Text('متجر العناصر', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.diamond, color: theme.colorScheme.secondary, size: 16),
                  const SizedBox(width: 6),
                  Text('${walletController.diamonds}', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
              icon: Image.asset('assets/images/Untitled-1_0033_icon_bag.png', width: 24, height: 24, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_rounded, color: theme.colorScheme.secondary)),
              tooltip: 'حقيبتي',
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: theme.tabBarTheme.indicatorColor,
            labelColor: theme.tabBarTheme.labelColor,
            unselectedLabelColor: theme.tabBarTheme.unselectedLabelColor,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'إطارات'),
              Tab(text: 'الدخوليات'),
              Tab(text: 'آي دي مميز'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGrid(StoreItemType.frame, theme),
            _buildGrid(StoreItemType.entryEffect, theme),
            _buildGrid(StoreItemType.fancyId, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(StoreItemType type, ThemeData theme) {
    final items = storeController.getItemsByType(type);
    
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
            const SizedBox(height: 16),
            Text('هذا القسم فارغ حالياً', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38))),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemCard(items[index], theme),
    );
  }

  Widget _buildItemCard(StoreItem item, ThemeData theme) {
    bool owned = inventoryController.isOwned(item.id);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildItemImage(item.imagePath, theme),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              item.name, 
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: owned ? null : () => _handlePurchase(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: owned ? theme.colorScheme.onSurface.withValues(alpha: 0.05) : theme.colorScheme.secondary,
                  foregroundColor: owned ? theme.colorScheme.onSurface.withValues(alpha: 0.24) : theme.colorScheme.onSecondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                ),
                child: Text(
                  owned ? 'مملوك' : '${item.price.toInt()} ماسة',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(String path, ThemeData theme) {
    if (path.isEmpty) {
      return Icon(Icons.diamond, color: theme.colorScheme.secondary, size: 40);
    }

    final imageProvider = path.startsWith('http') 
        ? NetworkImage(path) as ImageProvider
        : AssetImage(path);

    return Image(
      image: imageProvider,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.diamond, color: theme.colorScheme.secondary.withValues(alpha: 0.5), size: 40),
            const SizedBox(height: 4),
            Text('خطأ في الصورة', style: TextStyle(fontSize: 8, color: theme.colorScheme.onSurface.withValues(alpha: 0.2))),
          ],
        );
      },
    );
  }
}
