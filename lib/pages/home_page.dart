import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/firestore_service.dart';
import '../services/google_books_service.dart';
import '../theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/book_card.dart';
import 'book_search_page.dart';
import 'favorites_page.dart';
import 'my_borrowed_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(
        onSearch: (query) {
          setState(() {
            searchQuery = query;
            currentIndex = 1;
          });
        },
        onBorrowed: () => setState(() => currentIndex = 2),
      ),
      BookSearchPage(
        key: ValueKey(searchQuery),
        initialQuery: searchQuery,
      ),
      const MyBorrowedPage(),
      const FavoritesPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: currentIndex,
        onChanged: (index) => setState(() => currentIndex = index),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _BottomNav({
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore.currentLoansStream(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        final borrowedIcon = count > 0
            ? Badge(
                label: Text('$count'),
                child: const Icon(Icons.menu_book_outlined),
              )
            : const Icon(Icons.menu_book_outlined);

        return NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onChanged,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'หน้าแรก',
            ),
            const NavigationDestination(
              icon: Icon(Icons.search_rounded),
              label: 'ค้นหา',
            ),
            NavigationDestination(
              icon: borrowedIcon,
              selectedIcon: borrowedIcon,
              label: 'กำลังยืม',
            ),
            const NavigationDestination(
              icon: Icon(Icons.favorite_border_rounded),
              selectedIcon: Icon(Icons.favorite_rounded),
              label: 'รายการโปรด',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'โปรไฟล์',
            ),
          ],
        );
      },
    );
  }
}

class _HomeTab extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final VoidCallback onBorrowed;

  const _HomeTab({
    required this.onSearch,
    required this.onBorrowed,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final service = GoogleBooksService();
  final firestore = FirestoreService();

  late Future<List<Book>> futureBooks;

  @override
  void initState() {
    super.initState();
    futureBooks = service.searchBooks(query: 'programming');
    firestore.ensureProfile();
  }

  Future<void> refreshBooks() async {
    final future = service.searchBooks(query: 'programming');
    setState(() => futureBooks = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'ผู้ใช้';
    final initial = displayName.substring(0, 1).toUpperCase();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: refreshBooks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สวัสดี $displayName 👋',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'วันนี้อยากอ่านเรื่องอะไรดี?',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.mintStrong,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _HeroSearchCard(onTap: () => widget.onSearch('books')),
            const SizedBox(height: 18),
            _QuickSearchRow(onSearch: widget.onSearch),
            const SizedBox(height: 22),
            _LoanSummaryCard(onTap: widget.onBorrowed),
            const SizedBox(height: 24),
            AppSectionTitle(
              title: 'หนังสือแนะนำ',
              actionText: 'ดูทั้งหมด',
              onAction: () => widget.onSearch('books'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 286,
              child: FutureBuilder<List<Book>>(
                future: futureBooks,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _BookHorizontalLoading();
                  }

                  if (snapshot.hasError) {
                    return _InlineError(
                      message: 'โหลดหนังสือไม่สำเร็จ',
                      onRetry: refreshBooks,
                    );
                  }

                  final books = snapshot.data ?? [];
                  if (books.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'ยังไม่พบหนังสือ',
                      message: 'ลองค้นหาหนังสือจากเมนูค้นหาได้เลย',
                    );
                  }

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: books.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, index) => BookCard(book: books[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .16),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'ยืมพร้อมกันได้สูงสุด 3 เล่ม และมีเวลา 7 วันต่อการยืมหนึ่งรายการ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSearchCard extends StatelessWidget {
  final VoidCallback onTap;

  const _HeroSearchCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.mint,
                child: Icon(Icons.search_rounded, color: AppColors.primary),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ค้นหาชื่อหนังสือ หรือผู้แต่ง',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickSearchRow extends StatelessWidget {
  final ValueChanged<String> onSearch;

  const _QuickSearchRow({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    const queries = ['Flutter', 'Java', 'Python', 'Database'];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: queries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final query = queries[index];
          return ActionChip(
            avatar: const Icon(Icons.bolt_rounded, size: 17),
            label: Text(query),
            onPressed: () => onSearch(query),
          );
        },
      ),
    );
  }
}

class _LoanSummaryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LoanSummaryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore.currentLoansStream(),
      builder: (context, snapshot) {
        final docs = [...(snapshot.data?.docs ?? [])];
        docs.sort((a, b) {
          final aDate = (a.data()['dueDate'] as Timestamp?)?.toDate();
          final bDate = (b.data()['dueDate'] as Timestamp?)?.toDate();
          return (aDate ?? DateTime(9999)).compareTo(bDate ?? DateTime(9999));
        });

        final count = docs.length;
        DateTime? dueDate;
        if (docs.isNotEmpty) {
          dueDate = (docs.first.data()['dueDate'] as Timestamp?)?.toDate();
        }

        final daysLeft = dueDate == null
            ? null
            : dueDate.difference(DateTime.now()).inDays;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: AppColors.mint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          count == 0 ? 'ยังไม่มีหนังสือที่กำลังยืม' : 'กำลังยืม $count เล่ม',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          count == 0
                              ? 'ค้นหาหนังสือใหม่ ๆ แล้วเริ่มยืมได้เลย'
                              : daysLeft != null && daysLeft < 0
                                  ? 'มีหนังสือเกินกำหนด กรุณาคืนโดยเร็ว'
                                  : daysLeft != null
                                      ? 'เล่มที่ใกล้ครบกำหนดที่สุดใน $daysLeft วัน'
                                      : 'ตรวจสอบวันครบกำหนดในหน้ากำลังยืม',
                          style: TextStyle(
                            color: daysLeft != null && daysLeft < 0
                                ? AppColors.danger
                                : AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BookHorizontalLoading extends StatelessWidget {
  const _BookHorizontalLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.muted),
          const SizedBox(height: 8),
          Text(message),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('ลองอีกครั้ง'),
          ),
        ],
      ),
    );
  }
}
