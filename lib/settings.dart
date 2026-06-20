import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart'; // Imports your global themeProvider flag

// --- 1. LOCAL THEME MATRIX SPECIFICATION ---
class SettingsUiTheme {
  final bool isDark;
  late final Color canvasBg;
  late final Color textMain;
  late final Color textSub;
  late final Color ruleBorder;
  late final Color panelBg;

  SettingsUiTheme(this.isDark) {
    canvasBg = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    textMain = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    textSub = isDark ? const Color(0xFF737373) : const Color(0xFF404040);
    ruleBorder = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5);
    panelBg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);
  }
}

// --- 2. ENGINE CONTROLLER LOGIC ---
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Target outbound pipeline links
  final Uri _websiteUrl = Uri.parse('https://github.com/darshserphic');
  final Uri _companionAppsUrl = Uri.parse('https://github.com/darshserphic?tab=repositories');

  Future<void> _launchWebsiteUrl() async {
    if (!await launchUrl(_websiteUrl, mode: LaunchMode.externalApplication)) {
      throw Exception('COULD NOT LAUNCH OUTWARD SYSTEM PIPELINE PORTAL');
    }
  }

  Future<void> _launchCompanionAppsUrl() async {
    if (!await launchUrl(_companionAppsUrl, mode: LaunchMode.externalApplication)) {
      throw Exception('COULD NOT LAUNCH COMPANION APPLICATIONS LINK');
    }
  }

  void _showPrivacyDialog(SettingsUiTheme theme) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'DISMISS',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.panelBg,
                border: Border.all(color: theme.textMain, width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRIVACY PROTOCOLS',
                    style: TextStyle(
                      color: theme.textMain,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.05,
                    ),
                  ),
                  Divider(color: theme.ruleBorder, height: 16, thickness: 0.8),
                  Text(
                    'ALL ENCRYPTION ARCHITECTURES RUN STRICTLY ON SECURE LOCAL DEVICE PARTITIONS. REMOVING THE APPLICATION PURGES THESE METRICS PERMANENTLY.',
                    style: TextStyle(
                      color: theme.textSub,
                      fontSize: 10,
                      height: 1.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.textMain,
                        border: Border.all(color: theme.textMain, width: 1.0),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'ACKNOWLEDGE',
                        style: TextStyle(
                          color: theme.isDark ? Colors.black : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final theme = SettingsUiTheme(isDark);

    return Scaffold(
      backgroundColor: theme.canvasBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER SYSTEM HUD
              Text(
                'LUVIASUN INSTRUMENTATION // CONFIG',
                style: TextStyle(color: theme.textSub, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.06),
              ),
              const SizedBox(height: 2),
              Text(
                'SYSTEM PARAMETERS',
                style: TextStyle(color: theme.textMain, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.02),
              ),

              const SizedBox(height: 32),

              // [01] INTERFACE THEME TOGGLE
              _buildMenuTile(
                title: 'CORE INTERFACE ILLUMINATION',
                subtitle: isDark ? 'ACTIVE PROFILE // VERTICAL ABSOLUTE DARK' : 'ACTIVE PROFILE // VERTICAL ABSOLUTE LIGHT',
                textMain: theme.textMain,
                textSub: theme.textSub,
                borderColor: theme.ruleBorder,
                trailing: Switch(
                  value: isDark,
                  onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(),
                  activeColor: theme.textMain,
                  activeTrackColor: theme.ruleBorder,
                  inactiveThumbColor: theme.textSub,
                  inactiveTrackColor: theme.panelBg,
                ),
              ),

              const SizedBox(height: 16),

              // [02] PRIVACY ENGINE LOGS
              _buildMenuTile(
                title: 'PRIVACY PROTOCOLS',
                subtitle: 'VIEW ENCRYPTION & SECURITY DATA MATRIX',
                textMain: theme.textMain,
                textSub: theme.textSub,
                borderColor: theme.ruleBorder,
                onTap: () => _showPrivacyDialog(theme),
              ),

              const SizedBox(height: 16),

              // [03] OUTWARD SYSTEM PORTAL
              _buildMenuTile(
                title: 'OUTWARD SYSTEM PORTAL',
                subtitle: 'ACCESS ROOT DEVELOPMENT PIPELINES',
                textMain: theme.textMain,
                textSub: theme.textSub,
                borderColor: theme.ruleBorder,
                onTap: _launchWebsiteUrl,
              ),

              const SizedBox(height: 16),

              // [04] COMPANION APPLICATIONS
              _buildMenuTile(
                title: 'COMPANION APPLICATIONS',
                subtitle: 'EXPLORE ALTERNATIVE SYSTEM BUILDS',
                textMain: theme.textMain,
                textSub: theme.textSub,
                borderColor: theme.ruleBorder,
                onTap: _launchCompanionAppsUrl,
              ),

              const Spacer(),

              // BRUTALIST SIGNATURE LOGO BLOCK
              Center(
                child: Text(
                  'BUILD BY DARSHSERPHIC',
                  style: TextStyle(
                    color: theme.textSub,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required String title,
    required String subtitle,
    required Color textMain,
    required Color textSub,
    required Color borderColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 0.8),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textMain,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.02,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textSub,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.01,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}