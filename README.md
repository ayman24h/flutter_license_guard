# flutter_license_guard

<div dir="rtl">

## نظام ترخيص Offline كامل لتطبيقات Flutter Desktop

حزمة Flutter جاهزة للإنتاج التجاري، توفر نظام ترخيص يعمل بدون إنترنت، مع توقيع رقمي (Ed25519)، ربط بالجهاز (Device Fingerprint)، كشف التلاعب (Tamper Detection)، وتشفير كامل للملفات (AES-256-GCM).

---

## 📋 الفهرس

1. [نظرة عامة](#نظرة-عامة)
2. [هيكل المشروع](#هيكل-المشروع)
3. [التشغيل والاختبار — خطوة بخطوة](#التشغيل-والاختبار)
4. [إضافة الحزمة لمشروعك](#إضافة-الحزمة-لمشروعك)
5. [استخدام الـ API بالكامل](#استخدام-الـ-api)
6. [أداة توليد التراخيص (CLI)](#أداة-توليد-التراخيص-cli)
7. [شرح طبقات الكود](#شرح-طبقات-الكود)
8. [صيغة ملف الترخيص](#صيغة-ملف-الترخيص)
9. [المعمارية والأمن](#المعمارية-والأمن)
10. [سيناريو الاستخدام الكامل](#سيناريو-الاستخدام-الكامل)
11. [الاختبارات](#الاختبارات)
12. [نصائح أمنية](#نصائح-أمنية)
13. [الأسئلة الشائعة](#الأسئلة-الشائعة)
14. [ملاحظات تقنية مهمة](#ملاحظات-تقنية-مهمة)

---

## نظرة عامة

### المميزات

| الميزة | الوصف |
|---|---|
| 🔐 توقيع رقمي | Ed25519 — الترخيص لا يمكن تزويره |
| 💻 ربط بالجهاز | بصمة الجهاز (Hardware Fingerprint) تربط الترخيص بجهاز واحد |
| 🔒 تخزين مشفّر | AES-256-GCM — الملف غير قابل للقراءة كـ JSON |
| 📋 إدارة الميزات | تحكم دقيق في الميزات لكل ترخيص |
| ⏰ انتهاء الصلاحية | أنواع: تجريبي، شهري، سنوي، مدى الحياة، Enterprise |
| 🛡️ كشف التلاعب | SHA-256 checksum يكشف أي تعديل على أي بايت |
| 📴 يعمل Offline | لا يحتاج إنترنت إطلاقاً |
| 🖥️ واجهة تفعيل جاهزة | صفحة Flutter قابلة للتخصيص بالكامل |
| 🔧 أداة CLI | توليد تراخيص موقّعة من سطر الأوامر |

### المكتبات المستخدمة

| المكتبة | الاستخدام |
|---|---|
| `cryptography` | Ed25519 توقيع رقمي + AES-256-GCM تشفير |
| `crypto` | SHA-256 للـ checksum وبصمة الجهاز |
| `path_provider` | مسار التخزين على كل منصة |
| `args` | parsing معاملات سطر الأوامر في أداة CLI |

### المنصات المدعومة

| المنصة | الحالة | مصادر البصمة |
|---|---|---|
| Windows | ✅ كامل | Machine GUID + BIOS UUID + Motherboard Serial + CPU ID |
| macOS | ✅ كامل | Hardware UUID + Serial Number |
| Linux | ✅ كامل | machine-id + Board Serial + CPU info |

---

## هيكل المشروع

```
flutter_license_guard/
│
├── packages/
│   │
│   ├── flutter_license_guard/          ← الحزمة الرئيسية (SDK)
│   │   ├── lib/
│   │   │   ├── flutter_license_guard.dart      ← نقطة الدخول العامة (Public API)
│   │   │   └── src/
│   │   │       ├── core/               ← الواجهة الرئيسية + الإعدادات
│   │   │       │   ├── license_config.dart
│   │   │       │   └── license_guard.dart
│   │   │       ├── models/             ← نماذج البيانات
│   │   │       │   ├── license_entity.dart
│   │   │       │   ├── license_file_payload.dart
│   │   │       │   ├── license_validation_result.dart
│   │   │       │   └── license_record.dart
│   │   │       ├── enums/              ← الأنواع والتعدادات
│   │   │       │   ├── license_type.dart
│   │   │       │   ├── license_feature.dart
│   │   │       │   ├── license_status.dart
│   │   │       │   └── license_error_code.dart
│   │   │       ├── services/           ← الخدمات
│   │   │       │   ├── device_fingerprint_service.dart
│   │   │       │   ├── windows_device_fingerprint_service.dart
│   │   │       │   ├── mac_device_fingerprint_service.dart
│   │   │       │   ├── linux_device_fingerprint_service.dart
│   │   │       │   ├── stub_device_fingerprint_service.dart
│   │   │       │   └── activation_service.dart
│   │   │       ├── crypto/             ← التشفير
│   │   │       │   ├── signature_service.dart
│   │   │       │   ├── ed25519_signature_service.dart
│   │   │       │   └── aes_gcm_encryption_service.dart
│   │   │       ├── storage/            ← التخزين المحلي
│   │   │       │   ├── license_storage.dart
│   │   │       │   └── file_license_storage.dart
│   │   │       ├── validators/         ← مُحقق الترخيص
│   │   │       │   └── license_validator.dart
│   │   │       ├── exceptions/         ← الاستثناءات (11 نوع)
│   │   │       ├── utils/              ← أدوات مساعدة
│   │   │       └── ui/                 ← واجهة تفعيل Flutter
│   │   │           └── license_activation_page.dart
│   │   ├── test/                       ← الاختبارات (9 ملفات)
│   │   ├── pubspec.yaml
│   │   └── README.md
│   │
│   └── license_generator/              ← أداة CLI لتوليد التراخيص
│       ├── bin/
│       │   └── license_generator.dart  ← نقطة تشغيل CLI
│       ├── lib/
│       │   ├── license_generator.dart  ← تصدير المكتبة
│       │   └── src/
│       │       ├── license_generator.dart
│       │       ├── license_crypto.dart
│       │       ├── license_entity.dart
│       │       ├── license_type.dart
│       │       └── license_feature.dart
│       ├── pubspec.yaml
│       └── README.md
│
├── example/                            ← تطبيق مثال كامل
│   ├── lib/
│   │   └── main.dart
│   └── pubspec.yaml
│
├── melos.yaml                          ← إدارة Monorepo
├── LICENSE                             ← MIT
└── README.md                           ← هذا الملف
```

---

## التشغيل والاختبار

> ⚠️ **مهم جداً:** احذف المجلد القديم بالكامل قبل فك النسخة الجديدة.

### الخطوة 1: فك الضغط

```bash
# على Windows (PowerShell):
rmdir /s /q flutter_license_guard
tar xzf flutter_license_guard.tar.gz
cd flutter_license_guard
```

### الخطوة 2: توليد مفاتيح التشفير

```bash
cd packages\license_generator
dart pub get
dart run license_generator generate-keys
```

**الناتج:**

```
=== Ed25519 Key Pair Generated ===

Private Key (KEEP SECRET — use with license_generator):
n01R0XxcmVCXHPbpgf9OCZU/cm//K52U7Z9w950vRes=

Public Key (EMBED IN FLUTTER APP):
/FmlDWy2S8bXr6v5DVF4a0WqE94qX/U3Xbfw0/bhplA=

⚠  Store the private key securely. Never embed it in your app.

Keys saved to:
  ./private_key.txt
  ./public_key.txt
```

> ⚠️ **احفظ المفتاح الخاص في مكان آمن جداً** (مثل AWS Secrets Manager أو HashiCorp Vault). لا تضعه أبداً في الكود أو التطبيق.

### الخطوة 3: تجربة توليد ترخيص

```bash
dart run license_generator create-license --customer "Abdelrhman Mohamed" --device-id "test-device-123" --type lifetime --features sales,inventory,reports --private-key "n01R0XxcmVCXHPbpgf9OCZU/cm//K52U7Z9w950vRes=" --output license.dat
```

**الناتج:**

```
✓ License generated successfully!
  File: license.dat
  Customer: Abdelrhman Mohamed
  Device: test-device-123
  Type: lifetime
  Features: sales, inventory, reports
  Public key: /FmlDWy2S8bXr6v5DVF4a0WqE94qX/U3Xbfw0/bhplA=
```

### الخطوة 4: تشغيل الاختبارات

```bash
cd ..\flutter_license_guard
flutter pub get
flutter test
```

**الناتج المتوقع:**

```
00:00 +1: enums_test ...
00:00 +2: license_entity_test ...
00:00 +3: signature_test ...
00:00 +4: encryption_test ...
00:00 +5: license_file_payload_test ...
00:00 +6: license_integration_test ...
00:00 +7: validation_result_test ...
00:00 +8: device_fingerprint_test ...
00:00 +9: e2e_license_flow_test ...

All tests passed!
```

### الخطوة 5: تشغيل تطبيق المثال

```bash
cd ..\..\example
flutter pub get
flutter run -d windows
```

---

## إضافة الحزمة لمشروعك

### الطريقة الأولى: مسار محلي (Local Path)

في `pubspec.yaml` بتاع مشروعك:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_license_guard:
    path: C:/path/to/flutter_license_guard/packages/flutter_license_guard
```

ثم:

```bash
flutter pub get
```

### الطريقة الثانية: من Git

```yaml
dependencies:
  flutter_license_guard:
    git:
      url: https://github.com/username/flutter_license_guard.git
      path: packages/flutter_license_guard
```

### الطريقة الثالثة: نشر على pub.dev

```bash
cd packages/flutter_license_guard
flutter pub publish
```

ثم في مشروعك:

```yaml
dependencies:
  flutter_license_guard: ^1.0.0
```

---

## استخدام الـ API

### 1. التهيئة في `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_license_guard/flutter_license_guard.dart';

// المفتاح العام من أداة generate-keys
const String publicKey = '/FmlDWy2S8bXr6v5DVF4a0WqE94qX/U3Xbfw0/bhplA=';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تهيئة النظام
  await LicenseGuard.initialize(
    config: LicenseConfig(
      licensePath: 'license.dat',     // اسم ملف الترخيص
      publicKey: publicKey,            // المفتاح العام
      appName: 'MyApp',               // اسم التطبيق (للمسار)
      // اختياري:
      // encryptionKey: 'base64-key',  // مفتاح تشفير مخصص
      // allowOfflineGrace: true,      // فترة سماح بعد الانتهاء
      // gracePeriodDays: 7,           // 7 أيام سماح
    ),
  );

  // 2. فحص الترخيص
  final isActivated = await LicenseGuard.isActivated;

  // 3. شغّل التطبيق المناسب
  if (isActivated) {
    runApp(const MyApp());
  } else {
    runApp(const ActivationApp());
  }
}
```

### 2. صفحة التفعيل (جاهزة)

```dart
class ActivationApp extends StatelessWidget {
  const ActivationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LicenseActivationPage(
        title: 'تفعيل MyApp',
        subtitle: 'ادخل مفتاح الترخيص للمتابعة',
        activateButtonText: 'تفعيل',
        deviceIdLabel: 'معرّف الجهاز',
        licenseInputLabel: 'مفتاح الترخيص',
        onSuccess: () {
          runApp(const MyApp());  // شغّل التطبيق
        },
        theme: const LicenseActivationTheme(
          // خصّص الألوان والشعار
          // backgroundColor: Colors.white,
          // logo: Image.asset('assets/logo.png'),
        ),
      ),
    );
  }
}
```

### 3. فحص الميزات (Features)

```dart
// فحص ميزة واحدة
if (await LicenseGuard.hasFeature(LicenseFeature.inventory)) {
  // اعرض وحدة المخزون
}

// فحص عدة ميزات
final hasSales = await LicenseGuard.hasFeature(LicenseFeature.sales);
final hasReports = await LicenseGuard.hasFeature(LicenseFeature.reports);

if (hasSales && hasReports) {
  // اعرض لوحة المبيعات والتقارير
}
```

### 4. قراءة بيانات الترخيص

```dart
final license = await LicenseGuard.currentLicense;

if (license != null) {
  print('العميل: ${license.customerName}');
  print('الشركة: ${license.companyName}');
  print('النوع: ${license.licenseType.value}');
  print('الميزات: ${license.features}');
  print('تاريخ الإصدار: ${license.issueDate}');
  print('تاريخ الانتهاء: ${license.expiryDate}');
}
```

### 5. تفعيل ترخيص برمجياً

```dart
final result = await LicenseGuard.activate(licenseKey);

if (result.success) {
  print('تم التفعيل بنجاح!');
  print('العميل: ${result.license?.customerName}');
} else {
  print('فشل التفعيل: ${result.message}');
  print('كود الخطأ: ${result.errorCode.code}');
}
```

### 6. إلغاء التفعيل

```dart
final deleted = await LicenseGuard.deactivate();
if (deleted) {
  print('تم إلغاء التفعيل');
}
```

### 7. فحص يدوي

```dart
final result = await LicenseGuard.validate();

if (result.success) {
  print('الترخيص سليم ✓');
} else {
  print('خطأ: ${result.status.name}');
  print('الرسالة: ${result.message}');
}
```

### 8. إعادة الفحص (Refresh)

```dart
// امسح الكاش وأعد الفحص
final result = await LicenseGuard.refresh();
```

### 9. الحصول على معرّف الجهاز

```dart
final deviceId = await LicenseGuard.getDeviceId();
print('Device ID: $deviceId');
// هذا هو المعرّف الذي يرسله العميل للحصول على ترخيص
```

### 10. معرفة مسار ملف الترخيص

```dart
final path = await LicenseGuard.licenseFilePath;
print('License file: $path');
// Windows: C:\Users\user\AppData\Roaming\MyApp\license.dat
```

### 11. استخدام copyWith مع clearExpiry

```dart
final license = await LicenseGuard.currentLicense;

// تحويل ترخيص إلى مدى الحياة (إزالة تاريخ الانتهاء)
final lifetimeLicense = license!.copyWith(
  licenseType: LicenseType.lifetime,
  clearExpiry: true,  // ضروري لتعيين expiryDate = null
);
```

> **ملاحظة مهمة:** في Dart، `copyWith(expiryDate: null)` لا يعمل لأن `null` يعني "استخدم القيمة الحالية". لذلك أضفنا `clearExpiry: true` لتعيين `expiryDate` إلى `null` صراحةً.

---

## أداة توليد التراخيص (CLI)

### الأوامر المتاحة

#### 1. `generate-keys` — توليد مفاتيح

```bash
dart run license_generator generate-keys
```

#### 2. `create-license` — توليد ترخيص

```bash
dart run license_generator create-license --customer "اسم العميل" --device-id "معرّف_الجهاز" --type lifetime --features sales,inventory,reports --private-key "المفتاح_الخاص" --output license.dat
```

### المعاملات (Arguments)

#### المطلوبة

| المعامل | الاختصار | الوصف |
|---|---|---|
| `--customer` | `-c` | اسم العميل |
| `--device-id` | `-d` | معرّف الجهاز (من شاشة التفعيل) |
| `--type` | `-t` | نوع الترخيص: `trial`, `monthly`, `yearly`, `lifetime`, `enterprise` |
| `--private-key` | `-k` | المفتاح الخاص (Base64) |

#### الاختيارية

| المعامل | الاختصار | الوصف |
|---|---|---|
| `--company` | | اسم الشركة |
| `--expiry` | `-e` | تاريخ الانتهاء (YYYY-MM-DD) — يحسب تلقائياً إذا لم يُحدد |
| `--features` | `-f` | الميزات مفصولة بفواصل |
| `--output` | `-o` | مسار الملف الناتج (افتراضي: `license.dat`) |
| `--encryption-key` | | مفتاح تشفير AES-256 مخصص (Base64) |
| `--id` | | معرّف ترخيص مخصص (يولّد تلقائياً إذا لم يُحدد) |

### أنواع الترخيص

| النوع | مدة الصلاحية | الاستخدام |
|---|---|---|
| `trial` | 30 يوم | نسخة تجريبية مجانية |
| `monthly` | 30 يوم | اشتراك شهري |
| `yearly` | 365 يوم | اشتراك سنوي |
| `lifetime` | غير منتهي | شراء لمرة واحدة |
| `enterprise` | غير منتهي | Enterprise بكل الميزات |

### الميزات المتاحة

| الميزة | الوصف |
|---|---|
| `crm` | إدارة علاقات العملاء |
| `sales` | المبيعات |
| `inventory` | المخزون |
| `reports` | التقارير |
| `accounting` | المحاسبة |
| `printing` | الطباعة |
| `backup` | النسخ الاحتياطي |
| `multi_branch` | دعم متعدد الفروع |

### أمثلة

**ترخيص تجريبي 30 يوم:**
```bash
dart run license_generator create-license --customer "أحمد علي" --device-id "abc123" --type trial --features sales,reports --private-key "KEY" --output trial_license.dat
```

**ترخيص سنوي بتاريخ انتهاء محدد:**
```bash
dart run license_generator create-license --customer "شركة النور" --company "Al-Noor Corp" --device-id "def456" --type yearly --expiry 2026-12-31 --features crm,sales,inventory,reports,accounting --private-key "KEY" --output yearly_license.dat
```

**ترخيص Enterprise بكل الميزات:**
```bash
dart run license_generator create-license --customer "شركة كبرى" --company "Big Corp" --device-id "xyz789" --type enterprise --features crm,sales,inventory,reports,accounting,printing,backup,multi_branch --private-key "KEY" --output enterprise_license.dat
```

---

## شرح طبقات الكود

### نظرة معمارية

```
┌─────────────────────────────────────────────────────────┐
│                   التطبيق (Flutter App)                   │
│                                                          │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │ LicenseGuard │  │  Activation  │  │   Validator    │  │
│  │   (Facade)   │  │   Service    │  │                │  │
│  └──────┬───────┘  └──────┬───────┘  └───────┬────────┘  │
│         │                 │                  │           │
│  ┌──────┴─────────────────┴──────────────────┴────────┐  │
│  │                    Core Layer                       │  │
│  └──────┬─────────────────┬──────────────────┬────────┘  │
│         │                 │                  │           │
│  ┌──────┴──────┐  ┌───────┴───────┐  ┌───────┴────────┐  │
│  │   Crypto    │  │   Storage     │  │   Services     │  │
│  │  Ed25519    │  │  File-based   │  │  Fingerprint   │  │
│  │  AES-256    │  │  Encrypted    │  │  Activation    │  │
│  └─────────────┘  └───────────────┘  └────────────────┘  │
│                                                          │
│  المفتاح العام فقط — لا يوجد مفتاح خاص في التطبيق         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│              أداة توليد التراخيص (CLI)                    │
│                                                          │
│  المفتاح الخاص → يوقّع الترخيص → license.dat             │
│                                                          │
│  يُحفظ آمناً على سيرفر/جهاز الإدارة                       │
└─────────────────────────────────────────────────────────┘
```

---

### 1️⃣ `enums/` — الأنواع والتعدادات

| الملف | الوظيفة |
|---|---|
| `license_type.dart` | أنواع الترخيص: `trial`, `monthly`, `yearly`, `lifetime`, `enterprise` |
| `license_feature.dart` | الميزات: `crm`, `sales`, `inventory`, `reports`, `accounting`, `printing`, `backup`, `multiBranch` |
| `license_status.dart` | حالة الترخيص بعد الفحص: `valid`, `expired`, `deviceMismatch`, `invalidSignature`, `corrupted`, `notFound`, `featureNotLicensed`, `revoked` |
| `license_error_code.dart` | أكواد أخطاء قابلة للقراءة آلياً (مثل `LIC_ERR_EXPIRED`) |

**مثال:**

```dart
LicenseType.lifetime          // ترخيص مدى الحياة
LicenseType.yearly.hasExpiry  // true — له تاريخ انتهاء
LicenseFeature.inventory      // ميزة المخزون
LicenseFeature.fromStringList(['sales', 'inventory'])  // من نص
```

---

### 2️⃣ `models/` — نماذج البيانات

| الملف | الوظيفة |
|---|---|
| `license_entity.dart` | الكيان الأساسي للترخيص — كل البيانات |
| `license_validation_result.dart` | نتيجة الفحص (نجح/فشل + السبب + الترخيص) |
| `license_file_payload.dart` | صيغة الملف الثنائي (Binary) مع checksum |
| `license_record.dart` | نموذج جاهز للوحة تحكم مستقبلية |

#### `LicenseEntity` — النموذج الأهم:

```dart
LicenseEntity(
  id: '12345',
  customerName: 'AM Store',
  companyName: 'AM Store LLC',
  deviceId: 'ABC123...',        // مرتبط بالجهاز
  licenseType: LicenseType.lifetime,
  issueDate: DateTime(2025, 1, 1),
  expiryDate: null,              // null = مدى الحياة
  features: ['sales', 'inventory', 'reports'],
  signature: 'base64...',        // التوقيع الرقمي
  metadata: {'plan': 'pro'},     // بيانات إضافية
)
```

**الدوال المهمة:**

| الدالة | الوظيفة |
|---|---|
| `toJson()` | تحويل لـ JSON |
| `fromJson()` | إنشاء من JSON |
| `toSignedDataJson()` | JSON بترتيب ثابت (sorted keys) — هذا ما يُوقَّع |
| `hasFeature(String)` | فحص ميزة |
| `isExpired` | هل انتهت الصلاحية؟ |
| `hasExpiry` | هل يوجد تاريخ انتهاء؟ |
| `copyWith(...)` | نسخة معدّلة |
| `copyWith(clearExpiry: true)` | نسخة مع إزالة تاريخ الانتهاء |

#### `toSignedDataJson()` — أهم دالة:

تحوّل الترخيص لـ JSON بترتيب مفاتيح ثابت (alphabetical). هذا ضروري لأن التوقيع الرقمي يتطلب نفس البيانات بالضبط عند التوقيع وعند التحقق. لو ترتيب المفاتيح اختلف، التوقيع لن يتطابق.

```json
{"company":"AM Store","customer":"AM Store","deviceId":"ABC123","features":["sales","inventory"],"id":"12345","issueDate":"2025-01-01T00:00:00.000","type":"lifetime"}
```

ملاحظة: حقل `signature` **غير مضمن** في هذا JSON — التوقيع لا يوقّع نفسه.

---

### 3️⃣ `crypto/` — طبقة التشفير

| الملف | الوظيفة |
|---|---|
| `signature_service.dart` | واجهة مجردة (Abstract Interface) للتوقيع |
| `ed25519_signature_service.dart` | تنفيذ Ed25519 — توقيع + تحقق + توليد مفاتيح |
| `aes_gcm_encryption_service.dart` | تشفير AES-256-GCM — تشفير + فك تشفير |

> **ملاحظة:** جميع عمليات التشفير **asynchronous** (تُرجع `Future`) لأن مكتبة `cryptography` تعمل بشكل غير متزامن.

#### Ed25519 — التوقيع الرقمي:

- **المفتاح الخاص (32 bytes seed)** → يوقّع البيانات (في أداة CLI فقط)
- **المفتاح العام (32 bytes)** → يتحقق من التوقيع (في التطبيق)
- **التوقيع (64 bytes)** → دليل إن البيانات أصلية ولم تُعدّل

```dart
// توقيع (في أداة CLI فقط)
final signature = await Ed25519SignatureService().sign(
  data: licenseData,
  privateKeyBase64: privateKey,
);

// تحقق (في التطبيق)
final isValid = await Ed25519SignatureService().verify(
  data: licenseData,
  signature: signature,
  publicKeyBase64: publicKey,
);
```

#### AES-256-GCM — التشفير:

- بتشفّر البيانات بحيث تصبح غير مقروءة
- GCM بتضيف **authentication tag (MAC)** → تكشف أي تعديل على النص المشفّر
- المفتاح مشتق من بصمة الجهاز (أو مفتاح مخصص)

**صيغة البيانات المشفّرة:**
```
[nonce (12 bytes)][ciphertext][mac (16 bytes)]
```

```dart
// تشفير
final ciphertext = await AesGcmEncryptionService().encrypt(
  plaintext: licenseJson,
  key: aesKey,
);

// فك تشفير
final plaintext = await AesGcmEncryptionService().decrypt(
  ciphertext: encryptedData,
  key: aesKey,
);
```

---

### 4️⃣ `services/` — الخدمات

| الملف | الوظيفة |
|---|---|
| `device_fingerprint_service.dart` | واجهة مجردة لتوليد معرّف الجهاز |
| `windows_device_fingerprint_service.dart` | **Windows**: MachineGUID + BIOS UUID + Motherboard + CPU |
| `mac_device_fingerprint_service.dart` | **macOS**: Hardware UUID + Serial Number |
| `linux_device_fingerprint_service.dart` | **Linux**: machine-id + Board Serial + CPU |
| `stub_device_fingerprint_service.dart` | للاختبار فقط |
| `activation_service.dart` | إدارة عملية التفعيل |

#### بصمة الجهاز (Device Fingerprint):

**على Windows:**

```
deviceHash = SHA256(
  MachineGUID    (من Registry: HKLM\SOFTWARE\Microsoft\Cryptography)
  + BIOS UUID    (من WMI: wmic csproduct get UUID)
  + Motherboard  (من WMI: wmic baseboard get SerialNumber)
  + CPU ID       (من WMI: wmic cpu get ProcessorId)
)
```

النتيجة: hash بطول 64 حرف hex — **فريد لكل جهاز، ثابت عبر إعادة التشغيل**.

---

### 5️⃣ `storage/` — التخزين المحلي

| الملف | الوظيفة |
|---|---|
| `license_storage.dart` | واجهة مجردة (Abstract Interface) |
| `file_license_storage.dart` | تخزين في نظام الملفات |

**مسار التخزين على كل منصة:**

| المنصة | المسار |
|---|---|
| Windows | `%APPDATA%\<appName>\license.dat` |
| macOS | `~/Library/Application Support/<appName>/license.dat` |
| Linux | `~/.local/share/<appName>/license.dat` |

---

### 6️⃣ `validators/` — مُحقق الترخيص

`license_validator.dart` ينفّذ **8 فحوصات بالترتيب**:

```
1️⃣ هل الملف موجود؟
   ❌ → LicenseStatus.notFound
   ↓ ✅
2️⃣ هل الـ checksum سليم؟ (SHA-256)
   ❌ → LicenseStatus.corrupted (تم التلاعب)
   ↓ ✅
3️⃣ هل الـ magic header صحيح؟ ("FLGV")
   ❌ → LicenseStatus.corrupted
   ↓ ✅
4️⃣ هل فك التشفير ناجح؟ (AES-256-GCM)
   ❌ → LicenseStatus.corrupted
   ↓ ✅
5️⃣ هل التوقيع صحيح؟ (Ed25519 verify)
   ❌ → LicenseStatus.invalidSignature (مزوّر)
   ↓ ✅
6️⃣ هل الجهاز مطابق؟
   ❌ → LicenseStatus.deviceMismatch
   ↓ ✅
7️⃣ هل الترخيص منتهي؟ (مع فترة سماح اختيارية)
   ❌ → LicenseStatus.expired
   ↓ ✅
8️⃣ ✅ كله سليم → LicenseStatus.valid
```

---

### 7️⃣ `core/` — الواجهة الرئيسية

| الملف | الوظيفة |
|---|---|
| `license_config.dart` | إعدادات (مسار الملف، المفتاح العام، اسم التطبيق، خيارات) |
| `license_guard.dart` | **الواجهة الرئيسية (Facade)** — كل الدوال اللي هتستخدمها |

#### `LicenseGuard` — الواجهة الوحيدة اللي تحتاجها:

```dart
// تهيئة
await LicenseGuard.initialize(config: LicenseConfig(...));

// فحوصات
await LicenseGuard.isActivated              // هل مفعّل؟ (Future<bool>)
await LicenseGuard.hasFeature(LicenseFeature.inventory)  // هل الميزة متاحة؟
await LicenseGuard.currentLicense           // الترخيص الحالي (Future<LicenseEntity?>)
await LicenseGuard.validate()               // فحص كامل
await LicenseGuard.refresh()                // إعادة فحص (يمسح الكاش)

// تفعيل
await LicenseGuard.activate(licenseKey)     // تفعيل ترخيص
await LicenseGuard.deactivate()             // إلغاء تفعيل

// معلومات
await LicenseGuard.getDeviceId()            // معرّف الجهاز
await LicenseGuard.licenseFilePath          // مسار ملف الترخيص

// تنظيف
LicenseGuard.dispose()                      // تحرير الموارد
```

---

### 8️⃣ `ui/` — واجهة التفعيل

`license_activation_page.dart` — صفحة Flutter جاهزة:

**المكونات:**
- اسم التطبيق (قابل للتخصيص)
- معرّف الجهاز + زر نسخ 📋
- حقل إدخال مفتاح الترخيص
- زر تفعيل مع loading state
- عرض الأخطاء بشكل واضح
- زر إلغاء (اختياري)

**التخصيص عبر `LicenseActivationTheme`:**

```dart
LicenseActivationPage(
  title: 'تفعيل تطبيقي',
  subtitle: 'ادخل المفتاح للمتابعة',
  activateButtonText: 'تفعيل الآن',
  theme: const LicenseActivationTheme(
    backgroundColor: Colors.white,
    titleStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    logo: Image.asset('assets/logo.png'),
    activateButtonStyle: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(Colors.blue),
    ),
    deviceIdBackgroundColor: Colors.grey,
    errorBackgroundColor: Colors.red,
  ),
  onSuccess: () { /* ... */ },
)
```

---

### 9️⃣ `exceptions/` — الاستثناءات

11 نوع خطأ، كلها ترث من `LicenseException`:

| الاستثناء | السبب |
|---|---|
| `LicenseException` | الأساس لكل الأخطاء |
| `LicenseFileNotFoundException` | ملف الترخيص غير موجود |
| `LicenseCorruptedException` | الملف تالف أو غير صالح |
| `LicenseSignatureInvalidException` | التوقيع مزوّر أو المفتاح خاطئ |
| `LicenseDeviceMismatchException` | الترخيص لجهاز آخر |
| `LicenseExpiredException` | انتهت صلاحية الترخيص |
| `LicenseFeatureNotLicensedException` | الميزة غير مشمولة في الترخيص |
| `DeviceFingerprintException` | فشل توليد بصمة الجهاز |
| `LicenseStorageException` | خطأ في التخزين المحلي |
| `LicenseNotInitializedException` | لم يتم استدعاء `initialize()` |
| `ActivationException` | خطأ عام في التفعيل |

> **ملاحظة تقنية:** الاستثناءات التي تحتوي على string interpolation ديناميكية (مثل `LicenseCorruptedException` و `LicenseExpiredException`) **ليست `const`** لأن Dart لا يسمح بـ `const` مع تعبيرات غير ثابتة. الاستثناءات التي تحتوي على نص ثابت فقط (مثل `LicenseSignatureInvalidException`) **هي `const`**.

---

### 🔟 `utils/` — أدوات مساعدة

| الملف | الوظيفة |
|---|---|
| `hash_utils.dart` | SHA-256 للنصوص والبايتات |
| `base64_utils.dart` | ترميز وفك ترميز Base64 |
| `date_utils.dart` | فحص الانتهاء، حساب الأيام المتبقية |

---

### 1️⃣1️⃣ `license_generator/` — أداة CLI

**البنية:**

| الملف | الوظيفة |
|---|---|
| `bin/license_generator.dart` | نقطة تشغيل CLI (سطر الأوامر) |
| `lib/src/license_generator.dart` | المنطق: إنشاء + توقيع + تشفير + حفظ |
| `lib/src/license_crypto.dart` | عمليات التشفير (Ed25519 + AES-256-GCM) |
| `lib/src/license_entity.dart` | نموذج الترخيص (مستقل عن Flutter) |
| `lib/src/license_type.dart` | أنواع الترخيص |
| `lib/src/license_feature.dart` | الميزات |

**عملية توليد الترخيص:**

```
بيانات الترخيص (JSON)
       ↓
ترتيب المفاتيح (Canonical JSON — sorted keys)
       ↓
توقيع Ed25519 (بالمفتاح الخاص)
       ↓
تشفير AES-256-GCM (بمفتاح مشتق من Device ID)
       ↓
تجميع: [Magic][Version][Encrypted][Signature][Checksum]
       ↓
license.dat (ملف ثنائي غير مقروء)
```

---

### 1️⃣2️⃣ `models/license_record.dart` — نماذج جاهزة للمستقبل

نماذج مصمّمة للوحة تحكم أونلاين مستقبلية:

| النموذج | الوصف |
|---|---|
| `Customer` | العميل (اسم، إيميل، هاتف، شركة) |
| `DeviceInfo` | جهاز مرتبط بالترخيص (معرّف، منصة، تاريخ أول/آخر ظهور) |
| `ActivationHistoryEntry` | سجل تفعيل (تاريخ، حالة، جهاز) |
| `LicenseRecord` | سجل كامل = ترخيص + عميل + أجهزة + سجل التفعيل |

---

## صيغة ملف الترخيص

ملف `license.dat` هو ملف ثنائي (Binary) — **غير قابل للقراءة كـ JSON**:

```
┌──────────────────────────────────────────────────────────┐
│ 4 bytes   │ رأس سحري "FLGV" (Magic Header)              │
│ 1 byte    │ رقم الإصدار (Format Version = 1)            │
│ 4 bytes   │ طول البيانات المشفّرة (Payload Length)       │
│ N bytes   │ البيانات المشفّرة (AES-256-GCM Encrypted)    │
│ 4 bytes   │ طول التوقيع (Signature Length)              │
│ 64 bytes  │ توقيع Ed25519 (Digital Signature)           │
│ 32 bytes  │ SHA-256 Checksum (كشف التلاعب)              │
└──────────────────────────────────────────────────────────┘
```

### طبقات الحماية (3 طبقات):

| الطبقة | الوظيفة | كشف |
|---|---|---|
| **SHA-256 Checksum** | hash لكل البايتات قبل الـ checksum | أي تعديل على أي بايت |
| **GCM MAC** | authentication tag مصاحب للنص المشفّر | أي تعديل على النص المشفّر |
| **Ed25519 Signature** | توقيع رقمي على الـ JSON الأصلي | تزوير كامل للملف |

**حتى لو عدّل شخص بايت واحد في الملف:**
1. الـ checksum لن يتطابق → `FormatException`
2. لو تجاوز الـ checksum، الـ GCM MAC لن يتطابق → فشل فك التشفير
3. لو تجاوز الاثنين، التوقيع لن يتطابق → `invalidSignature`

---

## المعمارية والأمن

### مبادئ التصميم

| المبدأ | التطبيق |
|---|---|
| **Clean Architecture** | طبقات منفصلة: core → services → crypto → storage |
| **SOLID** | كل طبقة لها واجهة (interface) + تنفيذ (impl) |
| **Dependency Injection** | كل الاعتمادات تُحقن عبر الـ constructor |
| **Null Safety** | الكود كامل بـ Dart 3+ null safety |
| **Open/Closed** | مفتوح للتوسعة (منصات جديدة) مغلق للتعديل |

### فصل المفاتيح (Key Separation)

```
┌──────────────────────┐     ┌──────────────────────┐
│   أداة CLI (آمنة)     │     │   تطبيق Flutter      │
│                      │     │                      │
│   🔒 Private Key     │     │   🔓 Public Key      │
│   (يوقّع التراخيص)    │     │   (يتحقق فقط)        │
│                      │     │                      │
│   لا يُوزّع أبداً      │     │   آمن للتضمين        │
└──────────────────────┘     └──────────────────────┘
```

### التشفير المستخدم

| الخوارزمية | الاستخدام | الحجم |
|---|---|---|
| Ed25519 | توقيع رقمي | مفتاح 32B + توقيع 64B |
| AES-256-GCM | تشفير البيانات | مفتاح 32B + nonce 12B + MAC 16B |
| SHA-256 | checksum + بصمة الجهاز | 32B |

### نقاط التحقق المتعددة

النظام يتحقق في **8 نقاط مختلفة**. هذا يعني أن الترخيص يُفحص عند:

1. **بدء التطبيق** — `LicenseGuard.isActivated`
2. **التفعيل** — `ActivationService.activateFromBase64`
3. **فحص الميزات** — `LicenseGuard.hasFeature`
4. **الفحص اليدوي** — `LicenseGuard.validate()`

---

## سيناريو الاستخدام الكامل

### السيناريو: عميل جديد يشتري ترخيص

```
1️⃣ أنشئ المفاتيح (مرة واحدة)
   ┌─────────────────────────────────┐
   │ dart run license_generator       │
   │   generate-keys                  │
   │                                 │
   │ → private_key.txt (آمن)         │
   │ → public_key.txt (في التطبيق)   │
   └─────────────────────────────────┘
              ↓
2️⃣ ضع المفتاح العام في التطبيق
   ┌─────────────────────────────────┐
   │ const publicKey = 'xY7z...';    │
   │                                 │
   │ await LicenseGuard.initialize(  │
   │   config: LicenseConfig(        │
   │     publicKey: publicKey,       │
   │     ...                         │
   │   ),                            │
   │ );                              │
   └─────────────────────────────────┘
              ↓
3️⃣ العميل يفتح التطبيق → لا يوجد ترخيص
   ┌─────────────────────────────────┐
   │ التطبيق يفحص → isActivated = false │
   │ يعرض شاشة التفعيل               │
   └─────────────────────────────────┘
              ↓
4️⃣ شاشة التفعيل تعرض Device ID
   ┌─────────────────────────────────┐
   │ Device ID: a1b2c3d4e5f6...      │
   │ [📋 نسخ]                        │
   └─────────────────────────────────┘
              ↓
5️⃣ العميل يرسل لك Device ID
   (إيميل، واتساب، نموذج ويب...)
              ↓
6️⃣ أنت تولّد الترخيص
   ┌──────────────────────────────────────┐
   │ dart run license_generator            │
   │   create-license                      │
   │     --customer "العميل"               │
   │     --device-id "a1b2c3d4e5f6..."     │
   │     --type yearly                     │
   │     --features sales,inventory        │
   │     --private-key "private_key"       │
   │     --output license.dat              │
   └──────────────────────────────────────┘
              ↓
7️⃣ أنت ترسل license.dat للعميل
   (إيميل، رابط تحميل...)
              ↓
8️⃣ العميل يفتح license.dat
   ينسخ المحتوى (Base64) ويلصقه في شاشة التفعيل
              ↓
9️⃣ التطبيق يتحقق:
   ✅ التوقيع صحيح (Ed25519)
   ✅ الجهاز مطابق
   ✅ غير منتهي
   ✅ الميزات متاحة
              ↓
🔟 ✅ التطبيق يفتح — الترخيص مفعّل ومحفوظ محلياً
```

---

## الاختبارات

### ملفات الاختبار (9 ملفات)

| الملف | ما يختبر |
|---|---|
| `enums_test.dart` | أنواع الترخيص والميزات (fromString، hasExpiry) |
| `license_entity_test.dart` | تسلسل/إلغاء تسلسل، toSignedDataJson، copyWith، clearExpiry |
| `signature_test.dart` | Ed25519 توقيع/تحقق، مفاتيح خاطئة، توقيع مزوّر |
| `encryption_test.dart` | AES-256-GCM تشفير/فك تشفير، مفاتيح خاطئة، نص مزوّر |
| `license_file_payload_test.dart` | صيغة الملف الثنائي، كشف التلاعب، رأس خاطئ |
| `license_integration_test.dart` | دورة كاملة: توقيع → تشفير → تجميع → فك → تحقق |
| `validation_result_test.dart` | نتائج الفحص (نجاح/فشل بكل الأنواع) |
| `device_fingerprint_test.dart` | بصمة الجهاز (Stub) — ثبات، تفرّق، صحة hex |
| `e2e_license_flow_test.dart` | اختبار شامل: توليد → حفظ → تحقق → فحص ميزات + انتهاء + جهاز خاطئ |

### تشغيل الاختبارات

```bash
cd packages\flutter_license_guard
flutter test
```

### تشغيل اختبار محدد

```bash
flutter test test\signature_test.dart
```

### تغطية الاختبارات

الاختبارات تغطي:
- ✅ توليد بصمة الجهاز (ثبات + تفرّق)
- ✅ توقيع Ed25519 (توقيع + تحقق + فشل مع بيانات/مفاتيح خاطئة)
- ✅ تشفير AES-256-GCM (تشفير + فك تشفير + فشل مع تلاعب)
- ✅ انتهاء الصلاحية (تواريخ مستقبلية/ماضية)
- ✅ ترخيص غير صالح (توقيع مزوّر، جهاز خاطئ)
- ✅ الميزات (موجودة/غير موجودة)
- ✅ copyWith مع clearExpiry
- ✅ دورة كاملة (Integration test)
- ✅ End-to-end (توليد → حفظ → تحقق → فحص ميزات)

---

## نصائح أمنية

### ✅ افعل هذا

| النصيحة | الوصف |
|---|---|
| احفظ Private Key في vault | AWS Secrets Manager، HashiCorp Vault، أو ملف آمن مشفّر |
| فعّل Flutter obfuscation | `flutter build windows --obfuscate --split-debug-info=...` |
| تحقق في نقاط متعددة | لا تعتمد على فحص واحد عند بدء التطبيق |
| اربط الترخيص بـ Device ID | يمنع مشاركة الترخيص بين الأجهزة |
| استخدم فترة سماح محدودة | `allowOfflineGrace: true, gracePeriodDays: 7` |
| سجّل محاولات التفعيل | للكشف عن محاولات التزوير |
| حدّث المفاتيح دورياً | ولّد مفاتيح جديدة لكل إصدار رئيسي |

### ❌ لا تفعل هذا

| التحذير | السبب |
|---|---|
| لا تضع Private Key في التطبيق | يمكن استخراجه وتزوير تراخيص |
| لا تجعل الملف readable كـ JSON | يكشف بيانات العميل والميزات |
| لا تزل الـ checksum | يفتح باب للتلاعب |
| لا تسمح بترخيص بدون Device ID | يسمح بمشاركة الترخيص |
| لا تعمل validate مرة واحدة فقط | استخدم فحوصات متكررة في أماكن حساسة |
| لا تضع مفتاح تشفير ثابت | استخدم مفتاح مشتق من الجهاز |

---

## الأسئلة الشائعة

### س: هل يعمل النظام بدون إنترنت؟

**نعم.** النظام مصمم بالكامل ليعمل Offline. كل التحقق يتم محلياً — التوقيع، بصمة الجهاز، فحص الانتهاء. لا يحتاج أي اتصال بخادم.

### س: ماذا يحدث لو غيّر العميل hardware؟

تتغير بصمة الجهاز → الترخيص لن يعمل → العميل يحتاج ترخيص جديد بـ Device ID الجديد. هذا سلوك متوقع لأسباب أمنية.

### س: هل يمكن استخدام نفس الترخيص على جهازين؟

**لا.** الترخيص مرتبط بـ Device ID فريد لكل جهاز. لاستخدامه على جهاز آخر، ولّد ترخيص جديد بـ Device ID الخاص بذلك الجهاز.

### س: ماذا يحدث لو حاول شخص فك التطبيق (Reverse Engineering)؟

يجد:
- المفتاح العام فقط (لا يمكنه تزوير تراخيص)
- خوارزمية التحقق (لا فائدة منها بدون المفتاح الخاص)
- صيغة الملف (لا يمكنه إنشاء ملف صالح)

### س: هل يمكن تزوير ملف الترخيص؟

**لا.** الملف محمي بـ 3 طبقات:
1. SHA-256 checksum (كشف أي تعديل)
2. GCM MAC (كشف تعديل النص المشفّر)
3. Ed25519 signature (توقيع رقمي لا يمكن تزويره بدون المفتاح الخاص)

### س: كيف أضيف ميزات جديدة؟

أضفها في `LicenseFeature` enum (في الحزمة الرئيسية وأداة CLI):

```dart
enum LicenseFeature {
  // ... الموجود
  myNewFeature('my_new_feature');
  // ...
}
```

ثم استخدمها في أداة CLI: `--features my_new_feature`

### س: كيف أضيف منصة جديدة؟

أنشئ تنفيذ جديد لـ `DeviceFingerprintService`:

```dart
class MyPlatformDeviceFingerprintService
    implements DeviceFingerprintService {
  @override
  Future<String> getDeviceId() async {
    // اجمع معرّفات الهاردوير الخاصة بالمنصة
    // رجّع SHA-256 hash
  }
}
```

ثم أضفه في `LicenseGuard._createDeviceFingerprintService()`.

### س: هل يمكنني تخصيص شاشة التفعيل؟

**نعم.** استخدم `LicenseActivationTheme` لتخصيص كل شيء: الألوان، الخطوط، الشعار، الأزرار. أو ابني واجهتك الخاصة واستخدم `LicenseGuard.activate()` مباشرة.

### س: أين يُحفظ ملف الترخيص؟

| المنصة | المسار |
|---|---|
| Windows | `%APPDATA%\<appName>\license.dat` |
| macOS | `~/Library/Application Support/<appName>/license.dat` |
| Linux | `~/.local/share/<appName>/license.dat` |

### س: هل يمكنني استخدام RSA بدلاً من Ed25519؟

البنية تدعم ذلك. أنشئ تنفيذ جديد لـ `SignatureService` باستخدام RSA. لكن Ed25519 أفضل: مفاتيح أصغر، أسرع، وأبسط.

### س: كيف أعمل revoke للترخيص؟

حالياً النظام Offline بالكامل، فلا يوجد revoke عن بُعد. يمكنك:
- إصدار تحديث للتطبيق بمفتاح عام جديد (يبطل كل التراخيص القديمة)
- أو إضافة قائمة revoke محلية في تحديث التطبيق

للمستقبل: النماذج (`LicenseRecord`, `ActivationHistoryEntry`) جاهزة للوحة تحكم أونلاين.

### س: لماذا `copyWith(expiryDate: null)` لا يعمل؟

في Dart، `null` في `copyWith` يعني "استخدم القيمة الحالية" وليس "اضبط إلى null". لذلك أضفنا `clearExpiry: true`:

```dart
// ❌ لا يعمل — يبقي القيمة الحالية
final bad = license.copyWith(expiryDate: null);

// ✅ يعمل — يضبط expiryDate إلى null
final good = license.copyWith(clearExpiry: true);
```

---

## ملاحظات تقنية مهمة

### 1. العمليات غير المتزامنة (Async)

جميع عمليات التشفير (توقيع، تحقق، تشفير، فك تشفير) **async** لأن مكتبة `cryptography` تعمل بشكل غير متزامن. استخدم `await` دائماً:

```dart
// ✅ صحيح
final isValid = await signatureService.verify(...);

// ❌ خطأ — يرجع Future<bool> وليس bool
final isValid = signatureService.verify(...);
```

### 2. الاستثناءات و const

الاستثناءات في Dart لا يمكن أن تكون `const` إذا كانت تحتوي على تعبيرات غير ثابتة (مثل string interpolation بمتغيرات). لذلك:

| الاستثناء | `const`؟ | السبب |
|---|---|---|
| `LicenseException` | ✅ `const` | معاملات ثابتة |
| `LicenseSignatureInvalidException` | ✅ `const` | نص ثابت فقط |
| `LicenseDeviceMismatchException` | ✅ `const` | نص ثابت فقط |
| `LicenseNotInitializedException` | ✅ `const` | نص ثابت فقط |
| `LicenseCorruptedException` | ❌ ليس `const` | يستخدم `$detail` |
| `LicenseExpiredException` | ❌ ليس `const` | يستخدم `expiryDate.toIso8601String()` |
| `LicenseFileNotFoundException` | ❌ ليس `const` | يستخدم `$path` |
| `LicenseFeatureNotLicensedException` | ❌ ليس `const` | يستخدم `$feature` |
| `DeviceFingerprintException` | ❌ ليس `const` | يستخدم `$detail` |
| `LicenseStorageException` | ❌ ليس `const` | يستخدم `$detail` |
| `ActivationException` | ❌ ليس `const` | يستخدم `$detail` |

### 3. مكتبة cryptography

استخدمنا مكتبة `cryptography` بدلاً من `pointycastle` لأن:
- API أنظف وأبسط
- دعم أفضل لـ Dart 3
- لا تحتاج تعامل مع أنواع معقدة
- Ed25519 و AES-256-GCM في نفس المكتبة

### 4. أداة CLI — parsing المعاملات

أداة CLI تستخدم `args` package مع parsing مباشر (وليس `addCommand`) لأن `addCommand` في بعض إصدارات `args` لا يدعم `--options` بشكل صحيح مع الأوامر الفرعية.

### 5. مفتاح Ed25519 الخاص

مكتبة `cryptography` تستخدم **32-byte seed** كمفتاح خاص (وليس 64-byte كما في بعض المكتبات الأخرى). المفتاح العام مشتق من الـ seed:

```
Private Key (seed): 32 bytes → Base64
Public Key:         32 bytes → Base64 (مشتق من الـ seed)
Signature:          64 bytes
```

---

## الترخيص

MIT — راجع ملف [LICENSE](LICENSE).

</div>
