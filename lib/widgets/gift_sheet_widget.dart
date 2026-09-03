import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_icon.dart';
import '../controllers/gift_controller.dart';
import '../controllers/room_ui_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/wallet_controller.dart';
import '../screens/charging_screen.dart';
import '../services/gift_box_config_service.dart';
import '../controllers/gift_manager.dart';
import '../services/catalog_service.dart';
import '../utils/image_utils.dart';

/// Formats large numbers into a readable string (e.g., 1.2M, 100K)
String formatBalance(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1).replaceAll(RegExp(r"\.0$"), "")}M';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1).replaceAll(RegExp(r"\.0$"), "")}K';
  }
  return value.toString();
}

/// Renders Gift Icon — always shows static image in the grid.
/// Animations (SVGA/MP4/VAP) only play via AlphaGiftPlayer when the gift is sent.
class GiftIconWidget extends StatelessWidget {
  final GiftItem item;
  final bool isLocked;
  final double size;

  const GiftIconWidget({
    super.key,
    required this.item,
    this.isLocked = false,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final double iconSize = size * 2.5;

    // Static image (always preferred)
    final String? imagePath = (item.animationPath != null && item.animationPath!.endsWith('.gif'))
        ? item.animationPath
        : item.imagePath;
    
    final bool hasImage = imagePath != null && imagePath.isNotEmpty;

    if (hasImage) {
      final bool isNetwork = ImageUtils.isHttpUrl(imagePath!);
      return Opacity(
        opacity: isLocked ? 0.3 : 1.0,
        child: isNetwork
            ? Image.network(
                imagePath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
              )
            : Image.asset(
                imagePath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
              ),
      );
    }

    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    IconData iconData;
    Color themeColor;
    final id = item.id.toLowerCase();

    if (id.contains('rose')) {
      iconData = Icons.local_florist_rounded;
      themeColor = Colors.redAccent;
    } else if (id.contains('heart')) {
      iconData = Icons.favorite_rounded;
      themeColor = Colors.pinkAccent;
    } else if (id.contains('car')) {
      iconData = Icons.directions_car_rounded;
      themeColor = Colors.blueAccent;
    } else if (id.contains('diamond') || id.contains('gem')) {
      iconData = Icons.diamond_rounded;
      themeColor = Colors.cyanAccent;
    } else if (id.contains('crown')) {
      iconData = Icons.military_tech_rounded;
      themeColor = Colors.amber;
    } else {
      iconData = Icons.card_giftcard_rounded;
      themeColor = Colors.amber;
    }

    final Color color = isLocked ? Colors.white10 : themeColor;

    return Container(
      width: size * 1.8,
      height: size * 1.8,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Center(
        child: Icon(iconData, color: color, size: size),
      ),
    );
  }
}

/// Comprehensive Gift Bottom Sheet
Future<void> showComprehensiveGiftSheet(
  BuildContext context,
  GiftController controller,
  void Function(String message, int targetSeat, int comboCount) onGiftSent, {
  String? roomId,
  RoomUiController? roomController,
  String? profileUserId,
  String? profileUserName,
  String? profileUserPhoto,
}) async {
  await GiftBoxConfigService.refresh();
  // Refresh gifts from DB in the background (non-blocking) so the sheet
  // opens immediately with the local hardcoded gifts even if Supabase is slow.
  CatalogService.refreshGifts();
  final giftBoxConfig = GiftBoxConfigService.current;

  if (roomController != null) {
    final occupied = roomController.allSeats
        .where((s) => s.userName != null && s.userName!.isNotEmpty)
        .toList();
    if (occupied.isNotEmpty) {
      final currentValid = controller.targetSeats.any((idx) => occupied.any((s) => s.index == idx));
      if (!currentValid) {
        controller.setTargetSeat(occupied.first.index);
      }
    }
  }

  GiftItem? selectedGift;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: controller),
        if (roomController != null) ChangeNotifierProvider.value(value: roomController),
        ChangeNotifierProvider.value(value: WalletController()),
      ],
      child: StatefulBuilder(
        builder: (context, setState) {
          final giftController = context.watch<GiftController>();
          final roomCtrl = roomController != null ? context.watch<RoomUiController>() : null;
          final walletController = context.watch<WalletController>();
          final userController = UserController();

          const fallbackTabs = ['شائعة', 'CP', 'الأعلام', 'الحظ', 'المطابخ / ارستقراطية', 'الغامض', 'نقاط'];
          final tabs = giftController.categories.isNotEmpty ? giftController.categories : fallbackTabs;

          return DefaultTabController(
            length: tabs.length,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: giftBoxConfig.boxBgColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(giftBoxConfig.boxRadius)),
                image: giftBoxConfig.hasBoxBgImage
                    ? DecorationImage(
                        image: _resolveImageProvider(giftBoxConfig.boxBgImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Column(
                children: [
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),

                  if (roomCtrl != null) 
                    _buildRecipientBar(context, roomCtrl, giftController, userController)
                  else if (profileUserId != null)
                    _buildProfileRecipientBar(context, giftController, profileUserId!, profileUserName ?? 'المستخدم', profileUserPhoto)
                  else
                    _buildSimplifiedRecipientBar(context, giftController, userController),

                  const Divider(color: Colors.white10, height: 1),

                  TabBar(
                    isScrollable: true,
                    indicatorColor: Colors.amber,
                    labelColor: Colors.amber,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
                    tabs: tabs.map((e) => Tab(text: e)).toList(),
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    child: TabBarView(
                      children: tabs.map((tab) {
                        final categoryGifts = giftController.byCategory(tab);
                        if (categoryGifts.isEmpty) {
                          return const Center(child: Text('لا توجد هدايا هنا حالياً', style: TextStyle(color: Colors.white24, fontFamily: 'Cairo')));
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: categoryGifts.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.65,
                          ),
                          itemBuilder: (_, i) {
                            final item = categoryGifts[i];
                            final isSelected = selectedGift?.id == item.id;
                            final locked = giftController.isLocked(item);

                            final tileDecoration = giftBoxConfig.hasTileBgImage
                                ? BoxDecoration(
                                    borderRadius: BorderRadius.circular(giftBoxConfig.tileRadius),
                                    border: Border.all(
                                      color: isSelected ? giftBoxConfig.tileSelectedBorderColor : giftBoxConfig.tileBorderColor,
                                      width: 1.5,
                                    ),
                                    image: DecorationImage(
                                      image: _resolveImageProvider(giftBoxConfig.tileBgImage!),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : BoxDecoration(
                                    color: isSelected ? giftBoxConfig.tileSelectedColor : giftBoxConfig.tileBgColor,
                                    borderRadius: BorderRadius.circular(giftBoxConfig.tileRadius),
                                    border: Border.all(
                                      color: isSelected ? giftBoxConfig.tileSelectedBorderColor : giftBoxConfig.tileBorderColor,
                                      width: 1.5,
                                    ),
                                  );

                            return GestureDetector(
                              onTap: () { if (!locked) setState(() => selectedGift = item); },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: tileDecoration,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 8),
                                    Expanded(child: Center(child: GiftIconWidget(item: item, isLocked: locked))),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Text(item.name, style: TextStyle(color: locked ? Colors.white24 : Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Cairo'), maxLines: 1, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const AppIcon('Icons.diamond', icon: Icons.diamond, color: Colors.blueAccent, size: 10),
                                        const SizedBox(width: 2),
                                        Text('${item.price}', style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    decoration: const BoxDecoration(color: Color(0xFF020617), border: Border(top: BorderSide(color: Colors.white10))),
                    child: Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChargingScreen())),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                   const AppIcon('Icons.diamond', icon: Icons.diamond, color: Colors.blueAccent, size: 20),
                                  const SizedBox(width: 6),
                                  Text(formatBalance(walletController.diamonds), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(width: 8),
                                  const Text('الشحن >', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        _buildQuantityDropdown(context, giftController),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () async {
                            if (selectedGift != null) {
                              final giftToSend = selectedGift!;
                              giftController.tapCombo(giftToSend);
                              String? receiverId;
                              String? receiverName;
                              if (roomController != null && giftController.targetSeats.isNotEmpty) {
                                final targetIdx = giftController.targetSeats.first;
                                final seat = roomController!.allSeats.where((s) => s.index == targetIdx).toList();
                                if (seat.isNotEmpty && seat.first.uid != null) {
                                  receiverId = seat.first.uid;
                                  receiverName = seat.first.userName;
                                }
                              } else if (profileUserId != null) {
                                receiverId = profileUserId;
                                receiverName = profileUserName;
                              }
                              final res = await giftController.sendGift(giftToSend, roomId: roomId, roomName: roomController?.roomName, roomPhoto: roomController?.roomCoverPath, receiverId: receiverId, receiverName: receiverName);
                              if (res['ok']) {
                                onGiftSent(giftToSend.name, giftController.targetSeats.isEmpty ? 1 : giftController.targetSeats.first, giftController.comboCount);
                                Navigator.pop(context);
                                Future.delayed(const Duration(milliseconds: 200), () {
                                  GiftManager().triggerAnimation(context, giftToSend);
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'], style: const TextStyle(fontFamily: 'Cairo'))));
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار هدية أولاً', style: TextStyle(fontFamily: 'Cairo'))));
                            }
                          },
                          child: Container(
                            height: 48, width: 110,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Center(
                              child: Text(giftController.comboCount > 0 ? 'Combo x${giftController.comboCount}' : 'إرسال', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

Widget _buildRecipientBar(BuildContext context, RoomUiController room, GiftController gift, UserController user) {
  final occupiedSeats = room.allSeats.where((s) => s.userName != null && s.userName!.isNotEmpty).toList();

  if (occupiedSeats.isEmpty) {
    return const SizedBox(height: 85, child: Center(child: Text('لا يوجد أحد على المايك', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo'))));
  }

  return Container(
    height: 85, padding: const EdgeInsets.symmetric(vertical: 4),
    child: ListView(
      scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Center(child: Padding(padding: const EdgeInsets.only(right: 12), child: Text('For:', style: TextStyle(color: Colors.amber.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')))),
        if (occupiedSeats.length > 1)
          _recipientAvatar(label: 'الكل', isSelected: gift.targetName == 'الكل', icon: Icons.groups_rounded, onTap: () => gift.setAllTargets(occupiedSeats.map((s) => s.index).toList())),
        ...occupiedSeats.map((seat) {
          final isMe = seat.userId == user.id;
          return _recipientAvatar(label: isMe ? 'لي' : '${seat.index}', isSelected: gift.targetSeats.contains(seat.index) && gift.targetName != 'الكل', image: seat.userProfilePic, onTap: () => gift.setTargetSeat(seat.index));
        }),
      ],
    ),
  );
}

Widget _buildSimplifiedRecipientBar(BuildContext context, GiftController gift, UserController user) {
  return Container(
    height: 85, padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [const SizedBox(width: 16), Text('For:', style: TextStyle(color: Colors.amber.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')), const SizedBox(width: 12), _recipientAvatar(label: 'لي', isSelected: true, image: user.profilePic, onTap: () {})]),
  );
}

Widget _buildProfileRecipientBar(BuildContext context, GiftController gift, String profileUserId, String profileUserName, String? profileUserPhoto) {
  return Container(
    height: 85, padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      const SizedBox(width: 16),
      Text('For:', style: TextStyle(color: Colors.amber.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
      const SizedBox(width: 12),
      _recipientAvatar(label: profileUserName, isSelected: true, image: profileUserPhoto, onTap: () {}),
    ]),
  );
}

Widget _recipientAvatar({required String label, required bool isSelected, required VoidCallback onTap, String? image, IconData? icon}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? Colors.amber : Colors.white10, width: 2)),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 20, backgroundColor: Colors.white.withOpacity(0.05),
                    backgroundImage: image != null ? RoomUiController.getSafeImageProvider(image) : null,
                    child: image == null && icon != null ? Icon(icon, color: isSelected ? Colors.amber : Colors.white38, size: 24) : null,
                  ),
                ),
              ),
              if (isSelected) Positioned(bottom: 0, right: 0, child: Container(decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle), child: const AppIcon('Icons.check', icon: Icons.check, size: 12, color: Colors.black))),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isSelected ? Colors.amber : Colors.white70, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontFamily: 'Cairo')),
        ],
      ),
    ),
  );
}

Widget _buildQuantityDropdown(BuildContext context, GiftController gift) {
  return Container(
    height: 38, padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(19), border: Border.all(color: Colors.white10)),
    child: DropdownButton<int>(
      value: gift.multiplier,
      items: gift.multipliers.map((m) => DropdownMenuItem(value: m, child: Text('$m', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo')))).toList(),
      onChanged: (v) => gift.setMultiplier(v!),
      underline: const SizedBox(), icon: const AppIcon('Icons.keyboard_arrow_down_rounded', icon: Icons.keyboard_arrow_down_rounded, color: Colors.amber, size: 22),
      dropdownColor: const Color(0xFF1E293B), alignment: Alignment.center,
    ),
  );
}

ImageProvider _resolveImageProvider(String url) {
  if (ImageUtils.isHttpUrl(url)) return NetworkImage(url);
  return AssetImage(url);
}
