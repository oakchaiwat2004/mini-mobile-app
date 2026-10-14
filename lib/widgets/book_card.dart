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
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _FavoriteCardButton(book: book),
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

class _FavoriteCardButton extends StatefulWidget {
  final Book book;

  const _FavoriteCardButton({required this.book});

  @override
  State<_FavoriteCardButton> createState() => _FavoriteCardButtonState();
}

class _FavoriteCardButtonState extends State<_FavoriteCardButton> {
  final FirestoreService _firestore = FirestoreService();
  bool _isLoading = false;

  Future<void> _toggleFavorite(bool currentStatus) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await _firestore.toggleFavorite(widget.book);
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentStatus
                ? 'นำ “${widget.book.title}” ออกจากรายการโปรดแล้ว'
                : 'บันทึก “${widget.book.title}” ลงรายการโปรดแล้ว',
          ),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: StreamBuilder<bool>(
        stream: _firestore.isFavoriteStream(widget.book.id),
        builder: (context, snapshot) {
          final isFav = snapshot.data ?? false;

          if (_isLoading) {
            return const SizedBox(
              width: 32,
              height: 32,
              child: Padding(
                padding: EdgeInsets.all(7),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          return InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _toggleFavorite(isFav),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? const Color(0xFFE45B68) : const Color(0xFF8E8E93),
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }
}