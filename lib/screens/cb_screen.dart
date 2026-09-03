import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import '../widgets/app_icon.dart';

class CBScreen extends StatelessWidget {
  const CBScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserController>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('العلاقات والمرافقين', style: TextStyle(color: Color(0xFF1B0F0B))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1B0F0B)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'رابطة العلاقات',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildProfileCircle(user.profilePic, user.name),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: AppIcon('Icons.favorite', icon: Icons.favorite, color: Colors.red, size: 50),
                ),
                _buildProfileCircle('', 'شريكك'),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              'لم تقم بالارتباط بأحد بعد',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
              ),
              child: const Text('إرسال طلب ارتباط'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCircle(String image, String label) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: image.isEmpty 
            ? const AppIcon('Icons.person', icon: Icons.person, size: 40, color: Colors.grey)
            : (image.startsWith('http') 
                ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) => const AppIcon('Icons.error', icon: Icons.error),
                  )
                : Image.asset(image, fit: BoxFit.cover)),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
