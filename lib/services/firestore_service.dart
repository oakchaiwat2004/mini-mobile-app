import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/book.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('กรุณาเข้าสู่ระบบก่อน');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _loanRef =>
      _db.collection('users').doc(uid).collection('loans');

  CollectionReference<Map<String, dynamic>> get _reviewRef =>
      _db.collection('reviews');

  // --- ข้อมูลโปรไฟล์ผู้ใช้ ---

  Future<void> createUserProfile({
    required User user,
    String? displayName,
  }) async {
    await _db.collection('users').doc(user.uid).set(
      {
        'email': user.email ?? '',
        'displayName': displayName ?? user.displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<Map<String, dynamic>?> userProfileStream() {
    return _db.collection('users').doc(uid).snapshots().map(
          (snapshot) => snapshot.data(),
        );
  }

  // --- จัดการการยืม-คืนหนังสือ ---

  Future<void> borrowBook(Book book) async {
    final activeLoans = await _loanRef
        .where('status', isEqualTo: 'borrowed')
        .get();

    if (activeLoans.docs.length >= 3) {
      throw Exception('ยืมได้สูงสุด 3 เล่มพร้อมกัน');
    }

    final sameBook = activeLoans.docs.any(
      (doc) => doc.data()['bookId'] == book.id,
    );

    if (sameBook) {
      throw Exception('คุณกำลังยืมหนังสือเล่มนี้อยู่แล้ว');
    }

    final now = DateTime.now();
    final dueDate = now.add(const Duration(days: 7));

    await _loanRef.add({
      ...book.toMap(),
      'status': 'borrowed',
      'borrowedAt': Timestamp.fromDate(now),
      'dueDate': Timestamp.fromDate(dueDate),
      'returnedAt': null,
    });
  }

  Future<void> returnBook(String loanId) async {
    await _loanRef.doc(loanId).update({
      'status': 'returned',
      'returnedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> currentLoansStream() {
    return _loanRef.where('status', isEqualTo: 'borrowed').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> historyStream() {
    return _loanRef.where('status', isEqualTo: 'returned').snapshots();
  }

  // --- ระบบรีวิวและการให้คะแนน (ไม่ต้องใช้ User ID) ---

  /// บันทึกรีวิวหนังสือเล่มใหม่ลง Firestore โดยตรง
  Future<void> submitReview({
    required Book book,
    required double rating,
    required String comment,
    String reviewerName = 'ผู้ใช้งานทั่วไป',
  }) async {
    final name = reviewerName.trim().isEmpty ? 'ผู้ใช้งานทั่วไป' : reviewerName.trim();

    await _reviewRef.add({
      'bookId': book.id,
      'bookTitle': book.title,
      'bookThumbnail': book.imageUrl,
      'bookAuthors': book.authors,
      'userName': name,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// สตรีมดึงรีวิวของหนังสือเฉพาะเล่ม
  Stream<QuerySnapshot<Map<String, dynamic>>> bookReviewsStream(String bookId) {
    return _reviewRef
        .where('bookId', isEqualTo: bookId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// สตรีมดึงรีวิวทั้งหมดของระบบ (สำหรับหน้ารวมรีวิว)
  Stream<QuerySnapshot<Map<String, dynamic>>> allReviewsStream() {
    return _reviewRef
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- ข้อมูลโปรไฟล์ ---

  Future<void> updateDisplayName(String displayName) async {
    final name = displayName.trim();

    if (name.isEmpty) {
      throw Exception('กรุณาระบุชื่อ');
    }

    await _auth.currentUser?.updateDisplayName(name);

    await _db.collection('users').doc(uid).set(
      {
        'displayName': name,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> ensureProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await createUserProfile(user: user);
  }
}