import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/firestore_service.dart';

class FavoriteButton extends StatefulWidget {
  final Book book;
  final Color activeColor;
  final Color inactiveColor;
  final double size;
  final Color? backgroundColor;

  const FavoriteButton({
    super.key,
    required this.book,
    this.activeColor = const Color(0xFFE45B68),
    this.inactiveColor = const Color(0xFF9E9E9E),
    this.size = 20,
    this.backgroundColor,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final FirestoreService _firestore = FirestoreService();
  bool _isLoading = false;

  Future<void> _toggle(bool currentStatus) async {
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buttonContent = StreamBuilder<bool>(
      stream: _firestore.isFavoriteStream(widget.book.id),
      builder: (context, snapshot) {
        final isFav = snapshot.data ?? false;

        if (_isLoading) {
          return SizedBox(
            width: widget.size + 14,
            height: widget.size + 14,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        return IconButton(
          iconSize: widget.size,
          visualDensity: VisualDensity.compact,
          tooltip: isFav ? 'นำออกจากรายการโปรด' : 'เพิ่มในรายการโปรด',
          icon: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFav ? widget.activeColor : widget.inactiveColor,
          ),
          onPressed: () => _toggle(isFav),
        );
      },
    );

    if (widget.backgroundColor != null) {
      return Material(
        color: widget.backgroundColor,
        shape: const CircleBorder(),
        elevation: 2,
        child: buttonContent,
      );
    }

    return buttonContent;
  }
}