import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/book.dart';
import '../pages/book_detail_page.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import 'network_book_image.dart';

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    final author = book.authors.isEmpty
        ? 'ไม่ทราบผู้เขียน'
        : book.authors.first;

    return SizedBox(
      width: 160,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookDetailPage(book: book),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .035),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: NetworkBookImage.fromBook(
                          book,
                          fit: BoxFit.cover,
                          iconSize: 44,
                        ),
                      ),
                      // ป้ายแสดงคะแนนรีวิวเฉลี่ยที่มุมขวาบน
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _BookRatingBadge(bookId: book.id),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ป้ายแสดงคะแนนดาวเฉลี่ยบนมุมการ์ดหนังสือ
class _BookRatingBadge extends StatelessWidget {
  final String bookId;
  static final FirestoreService _firestore = FirestoreService();

  const _BookRatingBadge({required this.bookId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.bookReviewsStream(bookId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox.shrink(); // หากยังไม่มีรีวิวจะไม่แสดงป้าย
        }

        // คำนวณคะแนนเฉลี่ย
        final totalRating = docs.fold<double>(
          0.0,
          (sum, doc) => sum + ((doc.data()['rating'] as num?)?.toDouble() ?? 0.0),
        );
        final avgRating = totalRating / docs.length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Colors.amber,
                size: 14,
              ),
              const SizedBox(width: 3),
              Text(
                avgRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}