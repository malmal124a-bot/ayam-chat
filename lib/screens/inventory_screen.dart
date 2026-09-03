import 'package:flutter/material.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/store_controller.dart';
import '../controllers/user_controller.dart';
import '../models/store_item.dart';
import '../widgets/app_icon.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryController inventoryController = InventoryController();
  final StoreController storeController = StoreController();
  final UserController userController = UserController();

  @override
  void initState() {
    super.initState();
    inventoryController.addListener(_refresh);
    userController.addListener(_refresh);
  }

  @override
  void dispose() {
    inventoryController.removeListener(_refresh);
    userController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _equipItem(StoreItem item) {
    switch (item.type) {
      case StoreItemType.frame:
        bool isCurrentlyActive = inventoryController.activeFrameId == item.id;
        inventoryController.setActiveFrame(isCurrentlyActive ? null : item.id);
        break;
      case StoreItemType.entry:
      case StoreItemType.entryEffect:
        bool isCurrentlyActive = inventoryController.activeEntryEffectId == item.id;
        inventoryController.setActiveEntryEffect(isCurrentlyActive ? null : item.id);
        break;
      case StoreItemType.fancyId:
        // For Fancy ID, equipping means setting it as the user's current ID
        userController.setFancyId(item.name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تفعيل الآي دي: ${item.name}')),
        );
        break;
    }
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
          title: Text('حقيبتي', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            indicatorColor: theme.tabBarTheme.indicatorColor,
            labelColor: theme.tabBarTheme.labelColor,
            unselectedLabelColor: theme.tabBarTheme.unselectedLabelColor,
            tabs: const [
              Tab(text: 'إطارات'),
              Tab(text: 'الدخوليات'),
              Tab(text: 'آي دي مميز'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInventoryGrid(StoreItemType.frame, theme),
            _buildInventoryGrid(StoreItemType.entryEffect, theme),
            _buildInventoryGrid(StoreItemType.fancyId, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryGrid(StoreItemType type, ThemeData theme) {
    final ownedIds = inventoryController.ownedItemIds;
    final ownedItems = storeController.items
        .where((item) => item.type == type && ownedIds.contains(item.id))
        .toList();

    if (ownedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon('Icons.inventory_2_outlined', icon: Icons.inventory_2_outlined, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text('لا تملك أي عناصر هنا بعد', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.54))),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('اذهب للمتجر', style: TextStyle(color: theme.colorScheme.secondary)),
            ),
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
        childAspectRatio: 0.8,
      ),
      itemCount: ownedItems.length,
      itemBuilder: (context, index) => _buildInventoryItemCard(ownedItems[index], theme),
    );
  }

  Widget _buildInventoryItemCard(StoreItem item, ThemeData theme) {
    bool isActive = false;
    if (item.type == StoreItemType.frame) {
      isActive = inventoryController.activeFrameId == item.id;
    } else if (item.type == StoreItemType.entryEffect || item.type == StoreItemType.entry) {
      isActive = inventoryController.activeEntryEffectId == item.id;
    } else if (item.type == StoreItemType.fancyId) {
      isActive = userController.id == item.name;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? theme.colorScheme.secondary : theme.colorScheme.secondary.withValues(alpha: 0.1),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(item.imagePath, fit: BoxFit.contain, errorBuilder: (c, e, s) => AppIcon('Icons.stars', icon: Icons.stars, color: theme.colorScheme.secondary, size: 40)),
                  if (isActive)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
                        child: AppIcon('Icons.check', icon: Icons.check, color: theme.colorScheme.onPrimary, size: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Text(item.name, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _equipItem(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2) : theme.colorScheme.secondary,
                  foregroundColor: isActive ? theme.colorScheme.primaryContainer : theme.colorScheme.onSecondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  side: isActive ? BorderSide(color: theme.colorScheme.primaryContainer) : null,
                ),
                child: Text(
                  isActive ? 'تم التجهيز' : 'تجهيز',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
