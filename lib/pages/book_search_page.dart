import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/google_books_service.dart';
import '../theme.dart';
import '../widgets/book_card.dart';
import '../widgets/app_widgets.dart';

class BookSearchPage extends StatefulWidget {
  final String initialQuery;

  const BookSearchPage({
    super.key,
    this.initialQuery = '',
  });

  @override
  State<BookSearchPage> createState() => _BookSearchPageState();
}

class _BookSearchPageState extends State<BookSearchPage> {
  final service = GoogleBooksService();
  final controller = TextEditingController();
  final focusNode = FocusNode();

  List<Book> books = [];
  bool loading = false;
  String error = '';
  String currentQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) {
      _search(widget.initialQuery);
    } else {
      _search('books');
    }
  }

  Future<void> _search(String query) async {
    final value = query.trim();
    if (value.isEmpty) {
      _show('กรุณาพิมพ์คำค้นหา');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      loading = true;
      error = '';
      currentQuery = value;
      controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    });

    try {
      final result = await service.searchBooks(query: value);
      if (mounted) setState(() => books = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const suggestions = ['Flutter', 'Java', 'Python', 'Database', 'Novel'];

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'ค้นหาหนังสือ',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                SoftIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'ค้นหาอีกครั้ง',
                  onPressed: () => _search(
                    widget.initialQuery.isNotEmpty
                        ? widget.initialQuery
                        : currentQuery.isEmpty
                            ? 'books' : currentQuery,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'ชื่อหนังสือ / ผู้แต่ง / คำสำคัญ',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'ล้างคำค้นหา',
                        onPressed: () {
                          controller.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final text = suggestions[index];
                return ActionChip(
                  label: Text(text),
                  onPressed: () => _search(text),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error.isNotEmpty
                    ? AppEmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'ค้นหาไม่สำเร็จ',
                        message: 'ตรวจสอบอินเทอร์เน็ตหรือ API แล้วลองใหม่',
                        onAction: () => _search(currentQuery),
                        actionText: 'ลองใหม่',
                      )
                    : books.isEmpty
                        ? const AppEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'ไม่พบหนังสือ',
                            message: 'ลองเปลี่ยนคำค้นหา เช่น Flutter หรือ Python',
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                child: Text(
                                  'ผลลัพธ์ ${books.length} รายการสำหรับ “$currentQuery”',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 190,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
                                    childAspectRatio: .64,
                                  ),
                                  itemCount: books.length,
                                  itemBuilder: (_, index) => BookCard(book: books[index]),
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
