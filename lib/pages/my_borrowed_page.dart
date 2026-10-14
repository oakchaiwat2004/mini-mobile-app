import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/network_book_image.dart';
import 'history_page.dart';

class MyBorrowedPage extends StatelessWidget {
  const MyBorrowedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('กำลังยืม', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      const Text(
                        'จัดการหนังสือและวันครบกำหนดของคุณ',
                        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'ประวัติยืม–คืน',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryPage()),
                    );
                  },
                  icon: const Icon(Icons.history_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.currentLoansStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const AppEmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'โหลดข้อมูลไม่สำเร็จ',
                    message: 'ตรวจสอบอินเทอร์เน็ตและ Firestore แล้วลองใหม่',
                  );
                }

                final docs = [...(snapshot.data?.docs ?? [])];
                docs.sort((a, b) {
                  final aDate = (a.data()['dueDate'] as Timestamp?)?.toDate();
                  final bDate = (b.data()['dueDate'] as Timestamp?)?.toDate();
                  return (aDate ?? DateTime(9999)).compareTo(bDate ?? DateTime(9999));
                });

                if (docs.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'ยังไม่มีหนังสือที่กำลังยืม',
                    message: 'เลือกหนังสือจากหน้าแรกหรือค้นหา แล้วกด “ยืมหนังสือ”',
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                      child: Row(
                        children: [
                          _CountPill(count: docs.length),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'แตะคืนเมื่ออ่านเสร็จ เพื่อให้ยืมเล่มใหม่ได้',
                              style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 2, 18, 24),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) => _LoanCard(
                          doc: docs[index],
                          service: service,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;

  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.mintStrong,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count / 3 เล่ม',
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LoanCard extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final FirestoreService service;

  const _LoanCard({required this.doc, required this.service});

  @override
  State<_LoanCard> createState() => _LoanCardState();
}

class _LoanCardState extends State<_LoanCard> {
  bool loading = false;

  Future<void> _returnBook() async {
    final shouldReturn = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการคืนหนังสือ'),
        content: Text('ต้องการคืน “${widget.doc.data()['title'] ?? '-'}” ใช่ไหม?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('คืนหนังสือ'),
          ),
        ],
      ),
    );

    if (shouldReturn != true) return;
    setState(() => loading = true);

    try {
      await widget.service.returnBook(widget.doc.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คืนหนังสือสำเร็จ ✓')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());
    final days = dueDate == null ? null : dueDate.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 86,
            height: 116,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: NetworkBookImage(
              imageUrl: (data['imageUrl'] ?? '').toString(),
              fit: BoxFit.cover,
              iconSize: 34,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (data['title'] ?? '-').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, height: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  ((data['authors'] as List<dynamic>?) ?? []).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isOverdue ? const Color(0xFFFFF0EF) : AppColors.mint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOverdue ? Icons.warning_amber_rounded : Icons.event_available_rounded,
                        size: 17,
                        color: isOverdue ? AppColors.danger : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dueDate == null
                            ? 'ไม่ทราบวันครบกำหนด'
                            : isOverdue
                                ? 'เกินกำหนด ${days!.abs()} วัน'
                                : days == 0
                                    ? 'ครบกำหนดวันนี้'
                                    : 'เหลือ $days วัน • ${_formatDate(dueDate)}',
                        style: TextStyle(
                          color: isOverdue ? AppColors.danger : AppColors.primaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 42,
                  child: FilledButton.tonalIcon(
                    onPressed: loading ? null : _returnBook,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.assignment_return_rounded, size: 18),
                    label: Text(loading ? 'กำลังคืน...' : 'คืนหนังสือ'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
