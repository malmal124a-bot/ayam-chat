import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rocket_controller.dart';
import '../constants/rocket_assets.dart';
import '../widgets/alpha_gift_player.dart'; 

class SuperPrizeScreen extends StatelessWidget {
  const SuperPrizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RocketController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Tap outside to close overlay
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(color: Colors.transparent),
              ),

              // Bottom Curved Container (V-Arc 7 Cutout)
              Align(
                alignment: Alignment.bottomCenter,
                child: ClipPath(
                  clipper: SuperPrizeVArcClipper(),
                  child: Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.7,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF2B1D14),
                          Color(0xFF1A100B),
                        ],
                      ),
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                          width: 2.0,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 40),

                              // Centered Rocket + Progress Bar using Stack
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 1. Center Rocket Properly Above Progress Bar
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 180,
                                        width: 180,
                                        child: AlphaGiftPlayer(
                                          key: ValueKey('rocket_level_${controller.selectedLevel}'),
                                          svgaPath: RocketSvgaAssets.getLevelSvga(controller.selectedLevel),
                                          loops: 0, // Infinite loop
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 160,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                                        ),
                                        child: Column(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: LinearProgressIndicator(
                                                value: (controller.progressPercentage / 100.0).clamp(0.0, 1.0),
                                                minHeight: 10,
                                                backgroundColor: Colors.white12,
                                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'تقدم الفوز: ${controller.progressPercentage.toStringAsFixed(0)}%',
                                              style: const TextStyle(
                                                color: Colors.amber, 
                                                fontSize: 10, 
                                                fontWeight: FontWeight.bold,
                                                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Right Level Selector
                                  Positioned(
                                    right: 0,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(5, (index) {
                                        int level = 5 - index;
                                        bool isSelected = controller.selectedLevel == level;
                                        return GestureDetector(
                                          onTap: () => controller.selectLevel(level),
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(vertical: 2),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: isSelected ? const Color(0xFFFFD700) : Colors.black45,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: const Color(0xFFFFD700)),
                                            ),
                                            child: Text(
                                              'LV.$level',
                                              style: TextStyle(
                                                color: isSelected ? Colors.black : Colors.white70,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),

                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10.0),
                                child: Text(
                                  'الجوائز التالية هي فقط للإشارة، والهدايا المخصصة تتحدد بسبب تبرعك ومدى حظك',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              ),

                              // Grid of exactly 6 Reward Cards
                              GridView.count(
                                shrinkWrap: true,
                                crossAxisCount: 3,
                                childAspectRatio: 1.4,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  _buildRewardCard('VIP2', Icons.star, Colors.amber),
                                  _buildRewardCard('إطار الصورة', Icons.portrait, Colors.blue),
                                  _buildRewardCard('السيارة الكلاسيكية', Icons.directions_car, Colors.red),
                                  _buildRewardCard('ماسات مجانية', Icons.diamond, Colors.blueAccent),
                                  _buildRewardCard('الوسام', Icons.military_tech, Colors.orange),
                                  _buildRewardCard('جائزة السوبر', Icons.card_giftcard, Colors.purple),
                                ],
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRewardCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class SuperPrizeVArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height * 0.08);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.16,
      size.width,
      size.height * 0.08,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
