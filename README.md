# Book Borrow Flutter Project

โปรเจกต์ตัวอย่างระบบยืม–คืนหนังสือแบบใช้งานจริง

## เทคโนโลยี

- Flutter
- Firebase Authentication (Email/Password)
- Cloud Firestore
- Google Books API
- package:http

## จำนวนหน้า

ไม่นับ Login/Register มี 7 หน้า

1. Home
2. ค้นหาหนังสือ
3. รายละเอียดหนังสือ
4. กำลังยืม
5. ประวัติยืม–คืน
6. รายการโปรด
7. Profile

## วิธีเริ่มโปรเจกต์

### 1. สร้าง Flutter project

```bash
flutter create book_borrow_app
cd book_borrow_app
```

แล้วนำไฟล์ในโฟลเดอร์ `lib/` จากชุดนี้ไปวางทับ `lib/`
รวมถึง `pubspec.yaml` และ `firestore.rules`

### 2. ติดตั้ง Firebase CLI

```bash
firebase login
dart pub global activate flutterfire_cli
```

### 3. เชื่อม Flutter กับ Firebase

จาก root ของ project:

```bash
flutter pub get
flutterfire configure
```

เลือก Firebase project และ Android app ตามที่ต้องการ

คำสั่งนี้จะสร้าง `lib/firebase_options.dart`

### 4. เปิด Email/Password

Firebase Console
-> Authentication
-> Sign-in method
-> เปิด Email/Password

### 5. สร้าง Firestore

Firebase Console
-> Firestore Database
-> Create database

จากนั้นนำ `firestore.rules` ไปใส่ใน Rules

### 6. รัน

```bash
flutter run
```

## โครงสร้างข้อมูล Firestore

```text
users
  └── {uid}
      ├── displayName
      ├── email
      ├── createdAt
      │
      ├── loans
      │    └── {loanId}
      │         ├── bookId
      │         ├── title
      │         ├── authors
      │         ├── imageUrl
      │         ├── publisher
      │         ├── publishedDate
      │         ├── isbn
      │         ├── status
      │         ├── borrowedAt
      │         ├── dueDate
      │         └── returnedAt
      │
      └── favorites
           └── {bookId}
                ├── bookId
                ├── title
                ├── authors
                ├── imageUrl
                ├── publisher
                ├── publishedDate
                ├── isbn
                └── savedAt
```

## การยืมคืน

- จำกัดการยืมพร้อมกันสูงสุด 3 เล่ม
- หนังสือแต่ละเล่มยืมได้ครั้งเดียวต่อผู้ใช้
- กำหนดคืน 7 วัน
- ปุ่มคืนจะเปลี่ยน `status` จาก `borrowed` เป็น `returned`
- ประวัติการคืนยังคงอยู่ใน Firestore

## API

ค้นหาหนังสือด้วย:

```text
GET https://www.googleapis.com/books/v1/volumes?q=flutter
```

ตัวแอปไม่ได้มีรายการหนังสือแบบ hard-code/mockData แต่ดึงจาก Google Books API จริง

## หมายเหตุ

โปรเจกต์นี้เก็บ snapshot ของข้อมูลหนังสือตอนยืมไว้ใน Firestore เพื่อให้ประวัติยืมคืนยังแสดงได้ แม้ข้อมูลภายนอกจะเปลี่ยนภายหลัง

ระบบนี้เหมาะสำหรับโปรเจกต์นักศึกษา/เดโมระบบห้องสมุด โดย Google Books API ไม่ได้ให้จำนวนเล่มคงคลังของห้องสมุดจริง ดังนั้น "การยืม" ในโปรเจกต์นี้คือการบันทึกธุรกรรมยืมของผู้ใช้ลง Firestore


## รูปหนังสือ: Web + Android

โปรเจกต์ใช้ `lib/widgets/network_book_image.dart` เป็นจุดกลางสำหรับรูปหนังสือทุกหน้า

```dart
Image.network(
  imageUrl,
  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
)
```

บน Web Flutter จะ fallback ไปใช้ HTML `<img>` เมื่อการโหลด bytes ติด CORS และบน Android/iOS option นี้ไม่มีผล จึงใช้ network image ตามปกติ

ใน Android ให้ตรวจสอบ `android/app/src/main/AndroidManifest.xml` ว่ามี:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

รัน Web:

```bash
flutter run -d chrome --dart-define=GOOGLE_BOOKS_API_KEY=YOUR_API_KEY
```

รัน Android:

```bash
flutter run -d android --dart-define=GOOGLE_BOOKS_API_KEY=YOUR_API_KEY
```

อย่าส่ง `headers` แบบกำหนดเองให้ `Image.network` ที่ใช้ HTML fallback เพราะ HTML image ต้องใช้ headers ว่าง/null

## UI/UX Update

เวอร์ชันนี้ปรับหน้าตาให้ใช้งานง่ายขึ้น โดยยังใช้ข้อมูล API/Firebase เดิม

- โทนสีเขียวธรรมชาติ + พื้นหลังครีมอ่อน
- ปุ่มและการ์ดมีขนาดกดง่ายบนมือถือ
- หน้า Home มี Quick Search และสรุปจำนวนหนังสือที่กำลังยืม
- แถบนำทางด้านล่างมี badge จำนวนหนังสือที่กำลังยืม
- หน้า Search มีคำค้นยอดนิยมและปุ่มล้างคำค้นหา
- หน้า Detail มีปุ่มยืมแบบติดด้านล่าง ทำให้กดง่าย
- หน้า Borrowed มีวันครบกำหนดและเตือนหนังสือเกินกำหนด
- หน้า Empty/Error มีข้อความและไอคอนที่เข้าใจง่าย
- รูปหนังสือยังรองรับ Web + Android ผ่าน NetworkBookImage
