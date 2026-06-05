import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vigenesia/controllers/chat_controller.dart';
import 'package:vigenesia/theme/app_theme.dart';
import 'package:vigenesia/views/widgets/message_bubble.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> with WidgetsBindingObserver {
  late final String chatId;
  late final ChatController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ← ini juga hilang sebelumnya
    chatId = Get.arguments?['chatId'] ?? '';

    if (!Get.isRegistered<ChatController>(tag: chatId)) {
      Get.put<ChatController>(ChatController(), tag: chatId);
    }

    // ✅ FIX: dipindah ke luar if, selalu di-assign
    controller = Get.find<ChatController>(tag: chatId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Get.delete<ChatController>(tag: chatId);
            Get.back();
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: Obx(() {
          final otherUser = controller.otherUser;
          if (otherUser == null) return Text('Chat');
          return Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor,
                child: otherUser.photoURL.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          otherUser.photoURL,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, StackTrace) {
                            return Text(
                              otherUser.displayName.isNotEmpty
                                  ? otherUser.displayName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      )
                    : Text(
                        otherUser.displayName.isNotEmpty
                            ? otherUser.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser.displayName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      otherUser.isOnline ? "Online" : 'Offline',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: otherUser.isOnline
                            ? AppTheme.successColor
                            : AppTheme.textSecondaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  controller.deleteChat();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: AppTheme.errorColor,
                  ),
                  title: Text('Hapus Chat'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.messages.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.builder(
                controller: controller.scrollController,
                padding: EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isMyMessage = controller.isMyMessage(message);
                  final showTime =
                      index == 0 ||
                      controller.messages[index - 1].timestamp
                              .difference(message.timestamp)
                              .inMinutes
                              .abs() >
                          5;
                  return MessageBubble(
                    message: message,
                    isMyMessage: isMyMessage,
                    showTime: showTime,
                    timeText: controller.formatMessageTime(message.timestamp),
                    onLongPress: isMyMessage
                        ? () => _showMessageOptions(message)
                        : null,
                  );
                },
              );
            }),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        controller.onChatResume();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        controller.onChatPaused();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderColor.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.messageController,
                        decoration: InputDecoration(
                          hintText: 'Ketik pesan...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => controller.sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8),
            Obx(
              () => Container(
                decoration: BoxDecoration(
                  color: controller.isTyping
                      ? AppTheme.primaryColor
                      : AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  onPressed: controller.isSending
                      ? null
                      : controller.sendMessage,
                  icon: Icon(
                    Icons.send_rounded,
                    color: controller.isTyping
                        ? Colors.white
                        : AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.chat_outlined,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Mulailah percakapan',
              style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kirim pesan untuk memulai obrolan',
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(dynamic message) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: AppTheme.primaryColor),
              title: Text("Edit Pesan"),
              onTap: () {
                Get.back();
                _showEditDialog(message);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: AppTheme.errorColor),
              title: Text("Hapus Pesan"),
              onTap: () {
                Get.back();
                _showDeleteDialog(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(dynamic message) {
    final editController = TextEditingController(text: message.content);

    Get.dialog(
      AlertDialog(
        title: Text("Edit Pesan"),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(hintText: 'Masukkan pesan baru'),
          maxLines: null,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Batal")),
          // ✅ SESUDAH
          TextButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                controller.editMessage(message, editController.text.trim());
                Get.back(); 
              }
            },
            child: Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(dynamic message) {
    Get.dialog(
      AlertDialog(
        title: Text("Hapus Pesan"),
        content: Text(
          "Apakah Anda yakin ingin menghapus pesan ini? Tindakan ini tidak dapat dibatalkan",
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Batal")),
          TextButton(
            onPressed: () {
              controller.deleteMessage(message);
              Get.back();
            },
            child: Text("Hapus"),
          ),
        ],
      ),
    );
  }
}
