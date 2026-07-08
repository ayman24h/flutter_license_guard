import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/license_guard.dart';
import '../enums/license_error_code.dart';
import '../enums/license_feature.dart';
import '../enums/license_type.dart';
import '../models/license_validation_result.dart';

/// A customizable activation page widget.
///
/// Displays the device ID, a license input field, and an activate button.
/// On successful activation, [onSuccess] is called. On failure, an error
/// message is displayed.
///
/// All visual elements can be customized via the [LicenseActivationTheme]
/// parameter.
class LicenseActivationPage extends StatefulWidget {
  /// Creates a [LicenseActivationPage].
  const LicenseActivationPage({
    super.key,
    this.theme,
    this.onSuccess,
    this.onCancel,
    this.title,
    this.subtitle,
    this.activateButtonText = 'Activate License',
    this.cancelButtonText = 'Cancel',
    this.deviceIdLabel = 'Device ID',
    this.licenseInputLabel = 'License Key',
    this.showCancelButton = false,
  });

  /// Visual theme for the activation page.
  final LicenseActivationTheme? theme;

  /// Called when activation succeeds.
  final VoidCallback? onSuccess;

  /// Called when the user cancels activation.
  final VoidCallback? onCancel;

  /// Custom title text.
  final String? title;

  /// Custom subtitle text.
  final String? subtitle;

  /// Text for the activate button.
  final String activateButtonText;

  /// Text for the cancel button.
  final String cancelButtonText;

  /// Label for the device ID field.
  final String deviceIdLabel;

  /// Label for the license input field.
  final String licenseInputLabel;

  /// Whether to show the cancel button.
  final bool showCancelButton;

  @override
  State<LicenseActivationPage> createState() => _LicenseActivationPageState();
}

class _LicenseActivationPageState extends State<LicenseActivationPage> {
  String _deviceId = '';
  String _licenseKey = '';
  bool _isLoading = false;
  bool _isActivating = false;
  String? _errorMessage;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    setState(() => _isLoading = true);
    try {
      final deviceId = await LicenseGuard.getDeviceId();
      setState(() {
        _deviceId = deviceId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get device ID: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _activate() async {
    if (_licenseKey.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a license key.');
      return;
    }

    setState(() {
      _isActivating = true;
      _errorMessage = null;
    });

    try {
      final result = await LicenseGuard.activate(_licenseKey.trim());
      if (result.success) {
        widget.onSuccess?.call();
      } else {
        setState(() {
          _errorMessage = result.message;
          _isActivating = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Activation failed: $e';
        _isActivating = false;
      });
    }
  }

  Future<void> _copyDeviceId() async {
    // Copy to clipboard
    // ignore: avoid_print
    await Clipboard.setData(ClipboardData(text: _deviceId));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? const LicenseActivationTheme();
    final defaultTheme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor ?? defaultTheme.colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(theme, defaultTheme),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    LicenseActivationTheme theme,
    ThemeData defaultTheme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // App icon / logo
        if (theme.logo != null) ...[
          theme.logo!,
          const SizedBox(height: 24),
        ],

        // Title
        Text(
          widget.title ?? 'Activate Your License',
          style: theme.titleStyle ??
              defaultTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),

        // Subtitle
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtitle!,
            style: theme.subtitleStyle ?? defaultTheme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 32),

        // Device ID display
        _buildDeviceIdCard(theme, defaultTheme),

        const SizedBox(height: 24),

        // License input
        TextField(
          decoration: InputDecoration(
            labelText: widget.licenseInputLabel,
            hintText: 'Paste your license key here',
            border: theme.inputBorder ?? const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.vpn_key_outlined),
          ),
          maxLines: 3,
          onChanged: (value) => _licenseKey = value,
        ),

        const SizedBox(height: 16),

        // Error message
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (theme.errorBackgroundColor ??
                  defaultTheme.colorScheme.errorContainer),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.errorIconColor ??
                      defaultTheme.colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: theme.errorTextColor ??
                          defaultTheme.colorScheme.onErrorContainer,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Activate button
        FilledButton(
          onPressed: _isActivating ? null : _activate,
          style: theme.activateButtonStyle,
          child: _isActivating
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.activateButtonText),
        ),

        // Cancel button
        if (widget.showCancelButton) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onCancel,
            child: Text(widget.cancelButtonText),
          ),
        ],
      ],
    );
  }

  Widget _buildDeviceIdCard(
    LicenseActivationTheme theme,
    ThemeData defaultTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.deviceIdBackgroundColor ??
            defaultTheme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: defaultTheme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fingerprint,
                size: 18,
                color: defaultTheme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.deviceIdLabel,
                style: defaultTheme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  _deviceId,
                  style: defaultTheme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_copied ? Icons.check : Icons.copy),
                onPressed: _copyDeviceId,
                tooltip: 'Copy Device ID',
                color: _copied
                    ? Colors.green
                    : defaultTheme.colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Theme configuration for [LicenseActivationPage].
///
/// Allows customizing colors, styles, and visual elements of the
/// activation page to match the host application's branding.
class LicenseActivationTheme {
  /// Creates a [LicenseActivationTheme].
  const LicenseActivationTheme({
    this.backgroundColor,
    this.titleStyle,
    this.subtitleStyle,
    this.logo,
    this.inputBorder,
    this.activateButtonStyle,
    this.deviceIdBackgroundColor,
    this.errorBackgroundColor,
    this.errorTextColor,
    this.errorIconColor,
  });

  /// Background color for the page.
  final Color? backgroundColor;

  /// Text style for the title.
  final TextStyle? titleStyle;

  /// Text style for the subtitle.
  final TextStyle? subtitleStyle;

  /// Custom logo widget displayed above the title.
  final Widget? logo;

  /// Border for input fields.
  final InputBorder? inputBorder;

  /// Style for the activate button.
  final ButtonStyle? activateButtonStyle;

  /// Background color for the device ID card.
  final Color? deviceIdBackgroundColor;

  /// Background color for error messages.
  final Color? errorBackgroundColor;

  /// Text color for error messages.
  final Color? errorTextColor;

  /// Icon color for error messages.
  final Color? errorIconColor;
}
