import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'reviews_page.dart';
import 'history_page.dart';
import 'my_borrowed_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showEditNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('แก้ไขชื่อผู้ใช้'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'ชื่อ-นามสกุล หรือชื่อเล่น',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _firestoreService.updateDisplayName(controller.text.trim());
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
            },
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _firestoreService.userProfileStream(),
        builder: (context, snapshot) {
          final profileData = snapshot.data;
          final displayName = profileData?['displayName']?.isNotEmpty == true
              ? profileData!['displayName']
              : (user?.displayName?.isNotEmpty == true ? user!.displayName! : 'ผู้ใช้งานห้องสมุด');
          final email = user?.email ?? 'ไม่มีอีเมล';

          return CustomScrollView(
            slivers: [
              // ส่วน Header แบบ Gradient พร้อม Avatar
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              icon: Icon(Icons.edit, size: 18, color: theme.colorScheme.primary),
                              onPressed: () => _showEditNameDialog(displayName),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ส่วน Stat Cards (แสดงจำนวน กำลังยืม, จองคิว, ประวัติ)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      _buildSummaryCard(
                        title: 'กำลังยืม',
                        stream: _firestoreService.currentLoansStream(),
                        color: Colors.blueAccent,
                        icon: Icons.book_outlined,
                      ),
                      const SizedBox(width: 10),
                      _buildSummaryCard(
                        title: 'การรีวิว',
                        stream: _firestoreService.allReviewsStream(),
                        color: Colors.orangeAccent,
                        icon: Icons.bookmark_added_outlined,
                      ),
                      const SizedBox(width: 10),
                      _buildSummaryCard(
                        title: 'เคยยืมแล้ว',
                        stream: _firestoreService.historyStream(),
                        color: Colors.green,
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                  ),
                ),
              ),

              // รายการเมนูจัดการและทางลัด
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _buildMenuTile(
                          icon: Icons.menu_book_rounded,
                          iconColor: Colors.blue,
                          title: 'หนังสือที่กำลังยืมอยู่',
                          subtitle: 'ตรวจสอบวันกำหนดคืน',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyBorrowedPage()),
                          ),
                        ),
                        const Divider(height: 1, indent: 64),
                        _buildMenuTile(
                          icon: Icons.bookmark_rounded,
                          iconColor: Colors.deepOrange,
                          title: 'คิวหนังสือที่จองไว้',
                          subtitle: 'ดูสถานะการรอรับเล่ม',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ReviewsPage()),
                          ),
                        ),
                        const Divider(height: 1, indent: 64),
                        _buildMenuTile(
                          icon: Icons.history_rounded,
                          iconColor: Colors.teal,
                          title: 'ประวัติการยืม-คืน',
                          subtitle: 'รายการหนังสือทั้งหมดที่เคยอ่าน',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HistoryPage()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ปุ่มแก้ไขโปรไฟล์ & ปุ่มออกจากระบบ
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _buildMenuTile(
                          icon: Icons.person_outline,
                          iconColor: Colors.purple,
                          title: 'แก้ไขชื่อโปรไฟล์',
                          subtitle: 'ปรับปรุงชื่อที่ใช้แสดงผล',
                          onTap: () => _showEditNameDialog(displayName),
                        ),
                        const Divider(height: 1, indent: 64),
                        _buildMenuTile(
                          icon: Icons.logout_rounded,
                          iconColor: Colors.redAccent,
                          title: 'ออกจากระบบ',
                          subtitle: 'ลงชื่อออกจากการใช้งาน',
                          onTap: _confirmSignOut,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required Stream<dynamic> stream,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: StreamBuilder<dynamic>(
        stream: stream,
        builder: (context, snapshot) {
          int count = 0;
          if (snapshot.hasData && snapshot.data != null) {
            count = (snapshot.data.docs as List).length;
          }
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}