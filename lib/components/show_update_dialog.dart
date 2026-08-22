import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

void showUpdateDialog({
  required BuildContext context,
  required String currentVersion,
  required String newVersion,
  required List<String> changelog,
  required String storeUrl, // Direct APK download URL
  bool isForceUpdate = false,
}) {
  showDialog(
    context: context,
    barrierDismissible: !isForceUpdate,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (BuildContext dialogContext) {
      return _UpdateDialogWidget(
        currentVersion: currentVersion,
        newVersion: newVersion,
        changelog: changelog,
        storeUrl: storeUrl,
        isForceUpdate: isForceUpdate,
      );
    },
  );
}

class _UpdateDialogWidget extends StatefulWidget {
  final String currentVersion;
  final String newVersion;
  final List<String> changelog;
  final String storeUrl;
  final bool isForceUpdate;

  const _UpdateDialogWidget({
    required this.currentVersion,
    required this.newVersion,
    required this.changelog,
    required this.storeUrl,
    required this.isForceUpdate,
  });

  @override
  State<_UpdateDialogWidget> createState() => _UpdateDialogWidgetState();
}

class _UpdateDialogWidgetState extends State<_UpdateDialogWidget> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0; // 0.0 to 1.0
  String _statusText = 'Downloading update...';
  bool _hasError = false;

  Future<void> startUpdateProcess() async {
    // Check if install unknown apps permission is granted
    var status = await Permission.requestInstallPackages.status;
    if (!status.isGranted) {
      status = await Permission.requestInstallPackages.request();
      if (!status.isGranted) {
        // User denied permission; guide them to settings
        await openAppSettings();
        return;
      }
    }

    // Proceed with OTA Update once permission is active
    _startDownload();
  }

  void _startDownload() async {
    // OTA Update is Android only
    if (!kIsWeb && Platform.isAndroid) {
      setState(() {
        _isDownloading = true;
        _hasError = false;
        _downloadProgress = 0.0;
        _statusText = 'Initializing download...';
      });

      try {
        OtaUpdate()
            .execute(widget.storeUrl, destinationFilename: 'app-debug.apk')
            .listen(
              (OtaEvent event) {
                if (!mounted) return;

                switch (event.status) {
                  case OtaStatus.DOWNLOADING:
                    setState(() {
                      // event.value gives percentage as String (e.g. "45")
                      final double parsedValue =
                          (double.tryParse(event.value ?? '0') ?? 0.0);
                      _downloadProgress = (parsedValue / 100.0).clamp(0.0, 1.0);
                      _statusText = 'Downloading... ${(parsedValue).toInt()}%';
                    });
                    break;
                  case OtaStatus.INSTALLING:
                    setState(() {
                      _downloadProgress = 1.0;
                      _statusText = 'Preparing installer...';
                    });
                    break;
                  case OtaStatus.ALREADY_RUNNING_ERROR:
                    setState(() {
                      _statusText = 'An update is already running.';
                    });
                    break;
                  case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                    setState(() {
                      _hasError = true;
                      _statusText = 'Install permission denied.';
                    });
                    break;
                  default:
                    if (event.status.toString().contains('ERROR')) {
                      setState(() {
                        _hasError = true;
                        _statusText = 'Download failed. Tap retry.';
                      });
                    }
                    break;
                }
              },
              onError: (error) {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _statusText = 'Error downloading update.';
                  });
                }
              },
            );
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _statusText = 'Failed to start download.';
          });
        }
      }
    } else {
      // Fallback for non-Android platforms
      final uri = Uri.parse(widget.storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.primaryColor;
    final backgroundColor = isDark ? const Color(0xFF1E2732) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F1419);
    final bodyColor = isDark
        ? const Color(0xFF8B98A5)
        : const Color(0xFF536471);
    final cardColor = isDark
        ? const Color(0xFF273340)
        : const Color(0xFFF7F9FA);

    return PopScope(
      canPop: !widget.isForceUpdate && !_isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: backgroundColor,
        elevation: 10,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Tag & Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isForceUpdate
                          ? Icons.warning_rounded
                          : Icons.system_update_rounded,
                      color: primaryColor,
                      size: 26,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'v${widget.newVersion}',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                widget.isForceUpdate
                    ? 'Critical Update Required'
                    : 'Update Available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'v${widget.currentVersion} → v${widget.newVersion}',
                style: TextStyle(fontSize: 13, color: bodyColor),
              ),
              const SizedBox(height: 16),

              // Dynamic Body: Show Progress Bar during download, otherwise show Changelog
              if (_isDownloading) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _statusText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _hasError ? Colors.red : titleColor,
                              ),
                            ),
                          ),
                          if (!_hasError)
                            Text(
                              '${(_downloadProgress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _hasError ? 0.0 : _downloadProgress,
                          minHeight: 8,
                          backgroundColor: primaryColor.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _hasError ? Colors.red : primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (widget.changelog.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "WHAT'S NEW",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.changelog.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $item',
                            style: TextStyle(fontSize: 13, color: titleColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  if (!widget.isForceUpdate && !_isDownloading) ...[
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Later',
                          style: TextStyle(color: bodyColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isDownloading && !_hasError
                          ? null // Disable button while actively downloading
                          : startUpdateProcess,
                      child: Text(
                        _hasError
                            ? 'Retry Update'
                            : _isDownloading
                            ? 'Downloading...'
                            : 'Update Now',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
