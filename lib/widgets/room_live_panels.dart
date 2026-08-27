import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/room_ui_controller.dart';
import '../controllers/games_manager.dart';
import 'games_sheet_widget.dart';

// Note: This file seems to contain many room UI components. 
// I am replacing the dummy showGamesMenuSheet with a call to the real games modal.

void showRoomPasswordDialog(BuildContext context, RoomUiController controller) {
  final passController = TextEditingController(text: controller.roomPassword);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF0A1931),
      title: Text('room_password'.tr(), style: const TextStyle(color: Colors.white)),
      content: TextField(controller: passController, style: const TextStyle(color: Colors.white)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
        TextButton(onPressed: () { controller.lockRoomWithPassword(passController.text); Navigator.pop(context); }, child: Text('save'.tr())),
      ],
    ),
  );
}

Future<void> showGamesMenuSheet(BuildContext context, GamesManager gamesManager) {
  // Use the new GamesSheetWidget instead of the dummy implementation
  showGamesModal(context);
  return Future.value();
}

// ... existing code ...
