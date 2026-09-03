import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/app_icon.dart';
import '../controllers/medal_controller.dart';
import '../models/medal_model.dart';
import '../theme/app_theme.dart';

class MedalScreen extends StatelessWidget {
  const MedalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.nearBlackPurple,
        appBar: AppBar(
          backgroundColor: AppTheme.nearBlackPurple,
          elevation: 0,
          leading: IconButton(
            icon: AppIcon('Icons.arrow_back_ios', icon: Icons.arrow_back_ios, color: AppTheme.royalGold, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            tr('my_medals'),
            style: TextStyle(
              color: AppTheme.royalGold,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Medal Display Container (The 4 premium slots system)
            const _MedalDisplayContainer(),
            
            const SizedBox(height: 10),
            
            // Browse Medals Tabs
            TabBar(
              indicatorColor: AppTheme.royalGold,
              indicatorWeight: 3,
              labelColor: AppTheme.royalGold,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: tr('vip_medals')),
                Tab(text: tr('milestone_medals')),
                Tab(text: tr('event_medals')),
              ],
            ),
            
            const Expanded(
              child: TabBarView(
                children: [
                  MedalGrid(type: MedalType.vip),
                  MedalGrid(type: MedalType.milestone),
                  MedalGrid(type: MedalType.event),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedalDisplayContainer extends StatelessWidget {
  const _MedalDisplayContainer();

  @override
  Widget build(BuildContext context) {
    final equipped = context.watch<MedalController>().equippedMedals;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.coffeeDark.withValues(alpha: 0.1),
            AppTheme.nearBlackPurple.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon('Icons.stars_rounded', icon: Icons.stars_rounded, color: AppTheme.royalGold, size: 14),
              const SizedBox(width: 8),
              Text(
                'عرض الأوسمة المجهزة'.tr().toUpperCase(),
                style: TextStyle(
                  color: AppTheme.royalGold, 
                  fontSize: 12, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5
                ),
              ),
              const SizedBox(width: 8),
              AppIcon('Icons.stars_rounded', icon: Icons.stars_rounded, color: AppTheme.royalGold, size: 14),
            ],
          ),
          const SizedBox(height: 25),
          // 4 Organized Slots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (index) {
              Medal? medal = index < equipped.length ? equipped[index] : null;
              return _MedalSlot(medal: medal);
            }),
          ),
        ],
      ),
    );
  }
}

class _MedalSlot extends StatelessWidget {
  final Medal? medal;
  const _MedalSlot({this.medal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: AppTheme.nearBlackPurple.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: medal != null ? AppTheme.royalGold : AppTheme.royalGold.withValues(alpha: 0.1),
          width: medal != null ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 5,
            spreadRadius: -2,
            offset: const Offset(2, 2),
          ),
          if (medal != null)
            BoxShadow(
              color: AppTheme.royalGold.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: medal != null
            ? Padding(
                key: ValueKey(medal!.id),
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(medal!.iconPath, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => AppIcon('Icons.military_tech_outlined', icon: Icons.military_tech_outlined, size: 30, color: AppTheme.royalGold)),
              )
            : Center(
                child: AppIcon(
                  'Icons.military_tech_outlined',
                  icon: Icons.military_tech_outlined, 
                  color: AppTheme.royalGold.withValues(alpha: 0.05), 
                  size: 28
                ),
              ),
      ),
    );
  }
}

class MedalGrid extends StatelessWidget {
  final MedalType type;
  const MedalGrid({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedalController>(
      builder: (context, controller, child) {
        final medals = controller.getMedalsByType(type);

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 15,
            mainAxisSpacing: 20,
            childAspectRatio: 0.8,
          ),
          itemCount: medals.length,
          itemBuilder: (context, index) {
            final medal = medals[index];
            final bool isOwned = controller.isOwned(medal.id);
            final bool isEquipped = controller.isEquipped(medal.id);
            final bool isNewlyUnlocked = controller.newlyUnlockedIds.contains(medal.id);

            return _MedalItem(
              medal: medal,
              isOwned: isOwned,
              isEquipped: isEquipped,
              isNewlyUnlocked: isNewlyUnlocked,
              onTap: () {
                if (isOwned) {
                  controller.toggleEquip(medal.id);
                  if (isNewlyUnlocked) {
                    controller.clearNewlyUnlocked(medal.id);
                  }
                } else {
                  _showMedalInfo(context, medal, isOwned);
                }
              },
            );
          },
        );
      },
    );
  }

  void _showMedalInfo(BuildContext context, Medal medal, bool isOwned) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.nearBlackPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.royalGold, width: 0.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              medal.iconPath,
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) => const AppIcon('Icons.military_tech', icon: Icons.military_tech, size: 100, color: Colors.white10),
            ),
            const SizedBox(height: 20),
            Text(
              medal.name,
              style: TextStyle(color: AppTheme.royalGold, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              medal.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            if (!isOwned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tr('how_to_unlock'),
                  style: const TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً', style: TextStyle(color: AppTheme.royalGold)),
          ),
        ],
      ),
    );
  }
}

class _MedalItem extends StatefulWidget {
  final Medal medal;
  final bool isOwned;
  final bool isEquipped;
  final bool isNewlyUnlocked;
  final VoidCallback onTap;

  const _MedalItem({
    required this.medal,
    required this.isOwned,
    required this.isEquipped,
    required this.isNewlyUnlocked,
    required this.onTap,
  });

  @override
  State<_MedalItem> createState() => _MedalItemState();
}

class _MedalItemState extends State<_MedalItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    if (widget.isNewlyUnlocked) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_MedalItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNewlyUnlocked && !oldWidget.isNewlyUnlocked) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (widget.isEquipped)
                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.royalGold, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.royalGold.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ColorFiltered(
                  colorFilter: widget.isOwned
                      ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                      : const ColorFilter.matrix(<double>[
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0,      0,      0,      1, 0,
                        ]),
                  child: Image.asset(
                    widget.medal.iconPath,
                    width: 55,
                    height: 55,
                    errorBuilder: (context, error, stackTrace) => const AppIcon(
                      'Icons.military_tech',
                      icon: Icons.military_tech,
                      size: 55,
                      color: Colors.white10,
                    ),
                  ),
                ),
                if (!widget.isOwned)
                  const AppIcon('Icons.lock', icon: Icons.lock, color: Colors.white24, size: 18),
                if (widget.isNewlyUnlocked)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const AppIcon('Icons.star', icon: Icons.star, color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.medal.name,
              style: TextStyle(
                color: widget.isOwned ? Colors.white : Colors.white38,
                fontSize: 11,
                fontWeight: widget.isOwned ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}