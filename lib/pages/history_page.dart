import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/network_book_image.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติยืม–คืน')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.historyStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const AppEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'โหลดประวัติไม่สำเร็จ',
              message: 'ลองกลับเข้าเมนูนี้ใหม่อีกครั้ง',
            );
          }

          final docs = [...(snapshot.data?.docs ?? [])];
          docs.sort((a, b) {
            final aDate = (a.data()['returnedAt'] as Timestamp?)?.toDate();
            final bDate = (b.data()['returnedAt'] as Timestamp?)?.toDate();
            return (bDate ?? DateTime(1970)).compareTo(aDate ?? DateTime(1970));
          });

          if (docs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.history_rounded,
              title: 'ยังไม่มีประวัติการคืน',
              message: 'รายการที่คืนแล้วจะปรากฏในหน้านี้',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final data = docs[index].data();
              final borrowedAt = (data['borrowedAt'] as Timestamp?)?.toDate();
              final returnedAt = (data['returnedAt'] as Timestamp?)?.toDate();

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 78,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: NetworkBookImage(
                        imageUrl: (data['imageUrl'] ?? '').toString(),
                        fit: BoxFit.cover,
                        iconSize: 25,
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
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ยืม ${borrowedAt == null ? '-' : _formatDate(borrowedAt)}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                          Text(
                            'คืน ${returnedAt == null ? '-' : _formatDate(returnedAt)}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.mintStrong,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
