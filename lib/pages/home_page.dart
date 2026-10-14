import 'package:flutter/material.dart';
import 'book_search_page.dart';
import 'my_borrowed_page.dart';
import 'reviews_page.dart';
import 'history_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    BookSearchPage(),
    MyBorrowedPage(),
    ReviewsPage(), // แทนที่ FavoritesPage เดิม
    HistoryPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'ค้นหา',
          ),
          NavigationDestination(
            icon: Icon(Icons.book),
            label: 'กำลังยืม',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_add_outlined),
            selectedIcon: Icon(Icons.bookmark),
            label: 'การรีวิว', 
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'ประวัติ',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}