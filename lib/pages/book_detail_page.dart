import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/network_book_image.dart';

class BookDetailPage extends StatefulWidget {
  final Book book;

  const BookDetailPage({
    super.key,
    required this.book,
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final firestore = FirestoreService();

  bool favorite = false;
  bool loading = false;
  bool borrowed = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
    _checkBorrowed();
  }

  Future<void> _loadFavorite() async {
    try {
      final value = await firestore.isFavorite(widget.book.id);
      if (mounted) setState(() => favorite = value);
    } catch (_) {}
  }

  Future<void> _checkBorrowed() async {
    try {
      final snapshot = await firestore.currentLoansStream().first;
      final exists = snapshot.docs.any(
        (doc) => doc.data()['bookId'] == widget.book.id,
      );
      if (mounted) setState(() => borrowed = exists);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    try {
      await firestore.toggleFavorite(widget.book);
      if (!mounted) return;

      setState(() => favorite = !favorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            favorite ? 'เพิ่มหนังสือในรายการโปรดแล้ว' : 'นำหนังสือออกจากรายการโปรดแล้ว',
          ),
        ),
      );
    } catch (e) {
      _show(e.toString());
    }
  }

  Future<void> _borrow() async {
    setState(() => loading = true);

    try {
      await firestore.borrowBook(widget.book);
      if (!mounted) return;

      setState(() {
        borrowed = true;
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ยืมหนังสือสำเร็จ • กำหนดคืนภายใน 7 วัน'),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        _show(e.toString());
      }
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String get authorText {
    return widget.book.authors.isEmpty
        ? 'ไม่ทราบผู้เขียน'
        : widget.book.authors.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดหนังสือ'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton.filledTonal(
              tooltip: favorite ? 'นำออกจากรายการโปรด' : 'เพิ่มรายการโปรด',
              onPressed: _toggleFavorite,
              icon: Icon(
                favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 12),
        child: FilledButton.icon(
          onPressed: borrowed || loading ? null : _borrow,
          icon: Icon(
            borrowed ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
          ),
          label: Text(
            borrowed ? 'กำลังยืมหนังสือเล่มนี้' : 'ยืมหนังสือเล่มนี้',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        children: [
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: NetworkBookImage.fromBook(
              book,
              fit: BoxFit.contain,
              iconSize: 86,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            book.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.person_outline_rounded, size: 19, color: AppColors.primary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  authorText,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _InfoGrid(book: book),
          if (book.categories.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: book.categories
                  .take(4)
                  .map(
                    (category) => Chip(
                      avatar: const Icon(Icons.sell_outlined, size: 16),
                      label: Text(category),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 24),
          const _DetailSectionTitle(title: 'เกี่ยวกับหนังสือ'),
          const SizedBox(height: 8),
          _DescriptionCard(
            text: book.description.isEmpty
                ? 'ไม่มีคำอธิบายจากแหล่งข้อมูลภายนอก'
                : _stripHtml(book.description),
          ),
          if (book.isbn.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SimpleInfoRow(
              icon: Icons.qr_code_2_rounded,
              title: 'ISBN',
              value: book.isbn,
            ),
          ],
          const SizedBox(height: 12),
          if (book.previewLink.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () {
                _show('ลิงก์ตัวอย่างหนังสือ: ${book.previewLink}');
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('ดูตัวอย่างหนังสือ'),
            ),
        ],
      ),
    );
  }

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&');
  }
}

class _InfoGrid extends StatelessWidget {
  final Book book;

  const _InfoGrid({required this.book});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      _InfoTile(
        icon: Icons.business_outlined,
        label: 'สำนักพิมพ์',
        value: book.publisher,
      ),
      _InfoTile(
        icon: Icons.calendar_month_outlined,
        label: 'เผยแพร่',
        value: book.publishedDate,
      ),
      if (book.pageCount != null)
        _InfoTile(
          icon: Icons.menu_book_outlined,
          label: 'จำนวนหน้า',
          value: '${book.pageCount} หน้า',
        ),
      _InfoTile(
        icon: Icons.source_outlined,
        label: 'แหล่งข้อมูล',
        value: 'Google Books',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 520 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.45,
          children: items,
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  final String title;

  const _DetailSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final String text;

  const _DescriptionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          height: 1.55,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _SimpleInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SimpleInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            '$title: ',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
