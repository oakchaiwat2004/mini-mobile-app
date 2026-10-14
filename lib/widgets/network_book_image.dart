import 'package:flutter/material.dart';

import '../models/book.dart';

/// Widget กลางสำหรับแสดงรูปหนังสือจาก URL
///
/// Web  : ถ้าโหลด bytes ไม่ได้เพราะ CORS จะ fallback เป็น HTML <img>
/// Android/iOS: option นี้ไม่มีผล และ Image.network จะโหลดรูปตามปกติ
class NetworkBookImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double iconSize;

  const NetworkBookImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.iconSize = 48,
  });

  factory NetworkBookImage.fromBook(
    Book book, {
    Key? key,
    BoxFit fit = BoxFit.cover,
    double iconSize = 48,
  }) {
    return NetworkBookImage(
      key: key,
      imageUrl: book.imageUrl,
      fit: fit,
      iconSize: iconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();

    if (url.isEmpty) {
      return Center(
        child: Icon(
          Icons.menu_book,
          size: iconSize,
        ),
      );
    }

    return Image.network(
      url,
      fit: fit,

      // Flutter Web: ลองโหลดแบบปกติก่อน ถ้าติด CORS ให้ fallback เป็น <img>
      // Android/iOS: property นี้ไม่มีผลตามเอกสาร Flutter
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,

      loadingBuilder: (
        context,
        child,
        loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }

        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        );
      },

      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        debugPrint('BOOK IMAGE ERROR: $error');
        debugPrint('BOOK IMAGE URL: $url');

        return Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: iconSize,
          ),
        );
      },
    );
  }
}
