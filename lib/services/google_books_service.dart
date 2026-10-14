import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/book.dart';

class GoogleBooksService {
  static const String _baseUrl =
      'https://www.googleapis.com/books/v1/volumes';

  // ส่ง API key ผ่าน header และกำหนดค่าตอนรันแอปด้วย
  // --dart-define=GOOGLE_BOOKS_API_KEY=YOUR_KEY
  static const String _apiKey = 'AIzaSyCdiliZRY-Y_e5JuU6KaxR2tjqB2f4ODHU';

  Future<List<Book>> searchBooks({
    String query = 'flutter',
    int startIndex = 0,
    int maxResults = 20,
  }) async {
    final uri = Uri.https(
      'www.googleapis.com',
      '/books/v1/volumes',
      {
        'q': query.trim().isEmpty ? 'books' : query.trim(),
        'startIndex': '$startIndex',
        'maxResults': '$maxResults',
        'printType': 'books',
        'orderBy': 'relevance',
      },
    );

    final response = await http.get(
      uri,
      headers: _apiKey.isEmpty
          ? {}
          : {'x-goog-api-key': _apiKey},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Google Books API error: ${response.statusCode}\n'
        'ตรวจสอบ API key และการเปิด Books API',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>?) ?? [];

    return items
        .map((e) => Book.fromGoogleJson(e as Map<String, dynamic>))
        .where((book) => book.id.isNotEmpty)
        .toList();
  }

  Future<Book> getBook(String bookId) async {
    final uri = Uri.parse('$_baseUrl/$bookId');

    final response = await http.get(
      uri,
      headers: _apiKey.isEmpty
          ? {}
          : {'x-goog-api-key': _apiKey},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Google Books API error: ${response.statusCode}',
      );
    }

    return Book.fromGoogleJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
