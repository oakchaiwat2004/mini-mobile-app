# Android Internet Permission

เปิดไฟล์:

`android/app/src/main/AndroidManifest.xml`

ให้มี permission นี้ภายใน `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

ตัวอย่าง:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>

    <application
        android:label="book_borrow_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        ...
    </application>
</manifest>
```

อย่าวาง permission ไว้ข้างใน `<application>`
