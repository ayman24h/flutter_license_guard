import 'package:flutter/material.dart';
import 'package:flutter_license_guard/flutter_license_guard.dart';

/// Example public key — replace with your own generated key.
/// Use `dart run license_generator generate-keys` to create a real key pair.
const String publicKey = 'YOUR_BASE64_PUBLIC_KEY';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LicenseGuard.initialize(
    config: LicenseConfig(
      licensePath: 'license.dat',
      publicKey: publicKey,
      appName: 'LicenseGuardExample',
    ),
  );

  final isActivated = await LicenseGuard.isActivated;

  if (isActivated) {
    runApp(const MainApp());
  } else {
    runApp(const ActivationApp());
  }
}

/// The activation screen shown when no valid license is found.
class ActivationApp extends StatelessWidget {
  const ActivationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activate License',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: LicenseActivationPage(
        title: 'Activate LicenseGuard Example',
        subtitle: 'Enter your license key to activate the application.',
        onSuccess: () {
          // Restart the app to show the main screen
          runApp(const MainApp());
        },
        theme: const LicenseActivationTheme(
          // Customize to match your branding
        ),
      ),
    );
  }
}

/// The main application shown when a valid license is active.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LicenseGuard Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LicenseEntity? _license;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLicense();
  }

  Future<void> _loadLicense() async {
    final license = await LicenseGuard.currentLicense;
    setState(() {
      _license = license;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('LicenseGuard Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await LicenseGuard.deactivate();
              runApp(const ActivationApp());
            },
            tooltip: 'Deactivate License',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'License Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _infoRow('Customer', _license?.customerName ?? 'N/A'),
                    _infoRow('Company', _license?.companyName ?? 'N/A'),
                    _infoRow('Type', _license?.licenseType.value ?? 'N/A'),
                    _infoRow(
                      'Issued',
                      _license?.issueDate.toIso8601String().split('T').first ??
                          'N/A',
                    ),
                    _infoRow(
                      'Expires',
                      _license?.expiryDate
                              ?.toIso8601String()
                              .split('T')
                              .first ??
                          'Never',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Licensed Features',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: LicenseFeature.values.map((feature) {
                return FutureBuilder<bool>(
                  future: LicenseGuard.hasFeature(feature),
                  builder: (context, snapshot) {
                    final enabled = snapshot.data ?? false;
                    return Chip(
                      label: Text(feature.value),
                      avatar: Icon(
                        enabled ? Icons.check_circle : Icons.cancel,
                        color: enabled ? Colors.green : Colors.grey,
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
