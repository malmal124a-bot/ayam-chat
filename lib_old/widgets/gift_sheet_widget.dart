import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import '../controllers/gift_controller.dart';
import '../controllers/room_ui_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/wallet_controller.dart';
import '../screens/charging_screen.dart';

/// Formats large numbers into a readable string (e.g., 1.2M, 100K)
String formatBalance(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1).replaceAll(RegExp(r"\.0$"), "")}M';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1).replaceAll(RegExp(r"\.0$"), "")}K';
  }
  return value.toString();
}

/// Renders Gift Icon (SVGA, GIF, Image or Fallback Icon)
class GiftIconWidget extends StatefulWidget {
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
  State<GiftIconWidget> createState() => _GiftIconWidgetState();
}

class _GiftIconWidgetState extends State<GiftIconWidget> with SingleTickerProviderStateMixin {
  SVGAAnimationController? _svgaController;
  bool _isSvga = false;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  @override
  void didUpdateWidget(GiftIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.id != oldWidget.item.id) {
      _svgaController?.dispose();
      _svgaController = null;
      _isSvga = false;
      _initAnimation();
    }
  }

  void _initAnimation() {
    if (widget.item.svgaPath != null && widget.item.svgaPath!.isNotEmpty) {
      _svgaController = SVGAAnimationController(vsync: this);
      _isSvga = true;
      _loadSvga();
    }
  }

  Future<void> _loadSvga() async {
    final cached = GiftController.getCachedSvga(widget.item.svgaPath!);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _svgaController?.videoItem = cached;
          _svgaController?.forward();
        });
      }
      return;
    }

    final parser = SVGAParser();
    try {
      final videoItem = await parser.decodeFromAssets(widget.item.svgaPath!);
      if (mounted) {
        setState(() {
          _svgaController?.videoItem = videoItem;
          _svgaController?.forward();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSvga = false);
    }
  }

  @override
  void dispose() {
    _svgaController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSvga && _svgaController != null && _svgaController!.videoItem != null) {
      return Opacity(
        opacity: widget.isLocked ? 0.3 : 1.0,
        child: SizedBox(
          width: widget.size * 2.5,
          height: widget.size * 2.5,
          child: SVGAImage(_svgaController!, fit: BoxFit.contain),
        ),
      );
    }

    final String? imagePath = (widget.item.animationPath != null && widget.item.animationPath!.endsWith('.gif'))
        ? widget.item.animationPath
        : widget.item.imagePath;
    
    final bool hasImage = imagePath != null && imagePath.isNotEmpty;

    if (hasImage) {
      return Opacity(
        opacity: widget.isLocked ? 0.3 : 1.0,
        child: Image.asset(
          imagePath,
          width: widget.size * 2.5,
          height: widget.size * 2.5,
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
    final id = widget.item.id.toLowerCase();

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

    final Color color = widget.isLocked ? Colors.white10 : themeColor;

    return Container(
      width: widget.size * 1.8,
      height: widget.size * 1.8,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Center(
        child: Icon(iconData, color: color, size: widget.size),
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
}) {
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

  const tabs = ['شائعة', 'CP', 'الأعلام', 'الحظ', 'المطابخ / ارستقراطية', 'الغامض', 'نقاط'];
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

          return DefaultTabController(
            length: tabs.length,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                          // Load default embedded asset gifts when Firestore returns empty
                          return GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: giftController.gifts.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.65,
                            ),
                            itemBuilder: (_, i) {
                              final item = giftController.gifts[i];
                              final isSelected = selectedGift?.id == item.id;
                              final locked = giftController.isLocked(item);
                              
                              return GestureDetector(
                                onTap: () { if (!locked) setState(() => selectedGift = item); },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.amber.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isSelected ? Colors.amber : Colors.white10, width: 1.5),
                                  ),
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
                                          const Icon(Icons.diamond, color: Colors.blueAccent, size: 10),
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
                            
                            return GestureDetector(
                              onTap: () { if (!locked) setState(() => selectedGift = item); },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.amber.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isSelected ? Colors.amber : Colors.white10, width: 1.5),
                                ),
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
                                        const Icon(Icons.diamond, color: Colors.blueAccent, size: 10),
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
                                  const Icon(Icons.diamond, color: Colors.blueAccent, size: 20),
                                  const SizedBox(width: 6),
                                  Text(formatBalance(walletController.diamonds.value.toInt()), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
                          onTap: () {
                            if (selectedGift != null) {
                              giftController.tapCombo(selectedGift);
                              final res = giftController.sendGift(selectedGift!, roomId: roomId);
                              if (res['ok']) {
                                onGiftSent(selectedGift!.name, giftController.targetSeats.isEmpty ? 1 : giftController.targetSeats.first, giftController.comboCount);
                                Navigator.pop(context);
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
                              boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
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
        Center(child: Padding(padding: const EdgeInsets.only(right: 12), child: Text('For:', style: TextStyle(color: Colors.amber.withValues(alpha: 0.8), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')))),
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
    child: Row(children: [const SizedBox(width: 16), Text('For:', style: TextStyle(color: Colors.amber.withValues(alpha: 0.8), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')), const SizedBox(width: 12), _recipientAvatar(label: 'لي', isSelected: true, image: user.profilePic, onTap: () {})]),
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
                    radius: 20, backgroundColor: Colors.white.withValues(alpha: 0.05),
                    backgroundImage: image != null ? RoomUiController.getSafeImageProvider(image) : null,
                    child: image == null && icon != null ? Icon(icon, color: isSelected ? Colors.amber : Colors.white38, size: 24) : null,
                  ),
                ),
              ),
              if (isSelected) Positioned(bottom: 0, right: 0, child: Container(decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle), child: const Icon(Icons.check, size: 12, color: Colors.black))),
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
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(19), border: Border.all(color: Colors.white10)),
    child: DropdownButton<int>(
      value: gift.multiplier,
      items: gift.multipliers.map((m) => DropdownMenuItem(value: m, child: Text('$m', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo')))).toList(),
      onChanged: (v) => gift.setMultiplier(v!),
      underline: const SizedBox(), icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.amber, size: 22),
      dropdownColor: const Color(0xFF1E293B), alignment: Alignment.center,
    ),
  );
}
