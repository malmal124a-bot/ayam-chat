import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../screens/lucky_77_game_screen.dart';
import 'app_icon.dart';

class GamesSheetWidget extends StatelessWidget {
  const GamesSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            
            // SIDE-BY-SIDE TABS: Betting vs Entertainment
            const TabBar(
              indicatorColor: Colors.amber,
              labelColor: Colors.amber,
              unselectedLabelColor: Colors.white54,
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 16, 
                fontFamily: 'Cairo'
              ),
              tabs: [
                Tab(text: 'ألعاب مراهنات'),
                Tab(text: 'ألعاب ترفيهية'),
              ],
            ),
            
            const Divider(color: Colors.white10, height: 1),

            Expanded(
              child: Consumer<GameController>(
                builder: (context, controller, _) {
                  return TabBarView(
                    children: [
                      // Tab 1: ألعاب مراهنات (Betting Games)
                      _buildGamesGrid(context, controller.bettingGames),
                      
                      // Tab 2: ألعاب ترفيهية (Entertainment Games)
                      _buildGamesGrid(context, controller.entertainmentGames),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Game Center',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo'
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const AppIcon('Icons.close', icon: Icons.close, color: Colors.white54),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildGamesGrid(BuildContext context, List<GameModel> games) {
    if (games.isEmpty) {
      return const Center(
        child: Text(
          'قريباً.. ألعاب جديدة ممتعة',
          style: TextStyle(color: Colors.white24, fontFamily: 'Cairo', fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: games.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final game = games[index];
        return _buildGameCard(context, game);
      },
    );
  }

  Widget _buildGameCard(BuildContext context, GameModel game) {
    return GestureDetector(
      onTap: () => _handleGameTap(context, game),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              game.themeColor.withOpacity(0.15),
              game.themeColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: game.themeColor.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: game.themeColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: game.themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: game.imageAsset != null 
                ? Image.asset(game.imageAsset!, width: 40, height: 40, fit: BoxFit.contain)
                : Icon(game.icon, color: game.themeColor, size: 40),
            ),
            const SizedBox(height: 14),
            Text(
              game.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo'
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              game.category == GameCategory.betting ? 'مراهنات' : 'ترفيه',
              style: TextStyle(
                color: game.themeColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo'
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGameTap(BuildContext context, GameModel game) {
    if (game.id == 'lucky_77') {
      Navigator.pop(context); // Close Game Center
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Lucky77GameScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'اللعبة ${game.title} قيد التحضير.. انتظرونا!',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.indigoAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

// Helper function to show games modal
void showGamesModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black87,
    builder: (context) => const GamesSheetWidget(),
  );
}
