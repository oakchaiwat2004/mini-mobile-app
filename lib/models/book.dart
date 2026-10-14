class Book {
  final String id;
  final String title;
  final List<String> authors;
  final String description;
  final String imageUrl;
  final String publisher;
  final String publishedDate;
  final int? pageCount;
  final List<String> categories;
  final String isbn;
  final String previewLink;

  const Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.description,
    required this.imageUrl,
    required this.publisher,
    required this.publishedDate,
    required this.pageCount,
    required this.categories,
    required this.isbn,
    required this.previewLink,
  });

  factory Book.fromGoogleJson(Map<String, dynamic> json) {
    final info = (json['volumeInfo'] as Map<String, dynamic>?) ?? {};
    final imageLinks =
        (info['imageLinks'] as Map<String, dynamic>?) ?? {};

    String imageUrl = (imageLinks['thumbnail'] ??
            imageLinks['smallThumbnail'] ??
            '')
        .toString()
        .replaceFirst('http://', 'https://');

    final bookId = (json['id'] ?? '').toString();

    // บางเล่มไม่มี imageLinks แต่ยังสามารถลองโหลดปกจาก Google Books ด้วย volume id ได้
    if (imageUrl.isEmpty && bookId.isNotEmpty) {
      imageUrl =
          'https://books.google.com/books/content'
          '?id=$bookId'
          '&printsec=frontcover'
          '&img=1'
          '&zoom=2'
          '&source=gbs_api';
    }

    final identifiers =
        (info['industryIdentifiers'] as List<dynamic>?) ?? [];

    String isbn = '';
    if (identifiers.isNotEmpty) {
      final first = identifiers.first as Map<String, dynamic>;
      isbn = (first['identifier'] ?? '').toString();
    }

    return Book(
      id: bookId,
      title: (info['title'] ?? 'ไม่ระบุชื่อ').toString(),
      authors: ((info['authors'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toList(),
      description: (info['description'] ?? '').toString(),
      imageUrl: imageUrl,
      publisher: (info['publisher'] ?? '-').toString(),
      publishedDate: (info['publishedDate'] ?? '-').toString(),
      pageCount: info['pageCount'] is int ? info['pageCount'] as int : null,
      categories: ((info['categories'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toList(),
      isbn: isbn,
      previewLink: (info['previewLink'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': id,
      'title': title,
      'authors': authors,
      'imageUrl': imageUrl,
      'publisher': publisher,
      'publishedDate': publishedDate,
      'isbn': isbn,
    };
  }
}
