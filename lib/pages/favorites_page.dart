import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/book_card.dart';
import '../widgets/network_book_image.dart';
import 'book_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FirestoreService _service = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _listView = false;
  final Set<String> _removingIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Book _bookFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Book(
      id: (data['bookId'] ?? doc.id).toString(),
      title: (data['title'] ?? 'ไม่ระบุชื่อ').toString(),
      authors: ((data['authors'] as List<dynamic>?) ?? [])
          .map((value) => value.toString())
          .toList(),
      description: (data['description'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      publisher: (data['publisher'] ?? '-').toString(),
      publishedDate: (data['publishedDate'] ?? '-').toString(),
      pageCount: data['pageCount'] is int ? data['pageCount'] as int : null,
      categories: ((data['categories'] as List<dynamic>?) ?? [])
          .map((value) => value.toString())
          .toList(),
      isbn: (data['isbn'] ?? '').toString(),
      previewLink: (data['previewLink'] ?? '').toString(),
    );
  }

  Future<void> _removeFavorite(Book book) async {
    setState(() => _removingIds.add(book.id));
    try {
      await _service.toggleFavorite(book);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('นำ “${book.title}” ออกจากรายการโปรดแล้ว'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'ตกลง',
            onPressed: () {},
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('นำออกไม่สำเร็จ: $error')),
      );
    } finally {
      if (mounted) setState(() => _removingIds.remove(book.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.favoritesStream(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final allBooks = docs.map(_bookFromDoc).toList();
          final query = _query.trim().toLowerCase();
          final books = allBooks.where((book) {
            if (query.isEmpty) return true;
            return book.title.toLowerCase().contains(query) ||
                book.authors.any((author) => author.toLowerCase().contains(query));
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('รายการโปรด', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 5),
                          const Text(
                            'เก็บหนังสือเล่มที่ชอบไว้ หยิบกลับมาอ่านได้ทุกเมื่อ',
                            style: TextStyle(color: AppColors.muted, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE9E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded, color: Color(0xFFE45B68), size: 26),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 25),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${snapshot.connectionState == ConnectionState.waiting ? '—' : allBooks.length} เล่มที่บันทึกไว้',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 3),
                            const Text('หนังสือที่คุณสนใจ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD98A), size: 25),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'ค้นหาในรายการโปรด',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'ล้างคำค้นหา',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: IconButton(
                        tooltip: _listView ? 'แสดงแบบตาราง' : 'แสดงแบบรายการ',
                        onPressed: () => setState(() => _listView = !_listView),
                        icon: Icon(_listView ? Icons.grid_view_rounded : Icons.view_agenda_rounded,
                          color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('หนังสือที่บันทึก', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ),
                    if (!snapshot.hasError && snapshot.connectionState != ConnectionState.waiting)
                      Text('${books.length} รายการ', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return AppEmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'โหลดรายการโปรดไม่สำเร็จ',
                        message: 'ตรวจสอบการเชื่อมต่อ Firestore แล้วลองอีกครั้ง',
                        onAction: () => setState(() {}),
                        actionText: 'ลองอีกครั้ง',
                      );
                    }
                    if (allBooks.isEmpty) {
                      return const AppEmptyState(
                        icon: Icons.favorite_border_rounded,
                        title: 'ยังไม่มีหนังสือเล่มโปรด',
                        message: 'ไปที่หน้าหนังสือ แล้วกดปุ่มหัวใจเพื่อบันทึกเล่มที่สนใจไว้ที่นี่',
                      );
                    }
                    if (books.isEmpty) {
                      return const AppEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'ไม่พบหนังสือที่ค้นหา',
                        message: 'ลองค้นด้วยชื่อหนังสือหรือชื่อผู้แต่งอีกครั้ง',
                      );
                    }

                    if (_listView) {
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
                        itemCount: books.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 11),
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 72,
                                    height: 94,
                                    color: AppColors.mint,
                                    child: NetworkBookImage.fromBook(book, fit: BoxFit.cover, iconSize: 30),
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailPage(book: book))),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                          const SizedBox(height: 5),
                                          Text(book.authors.isEmpty ? 'ไม่ทราบผู้เขียน' : book.authors.join(', '),
                                            maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                          const SizedBox(height: 8),
                                          const Text('แตะเพื่อดูรายละเอียด', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'นำออกจากรายการโปรด',
                                  onPressed: _removingIds.contains(book.id) ? null : () => _removeFavorite(book),
                                  icon: _removingIds.contains(book.id)
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.favorite_rounded, color: Color(0xFFE45B68)),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 210,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: .64,
                      ),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return Stack(
                          children: [
                            Positioned.fill(child: BookCard(book: book)),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Material(
                                color: Colors.white.withValues(alpha: .96),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  tooltip: 'นำออกจากรายการโปรด',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _removingIds.contains(book.id) ? null : () => _removeFavorite(book),
                                  icon: _removingIds.contains(book.id)
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.favorite_rounded, color: Color(0xFFE45B68), size: 21),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
