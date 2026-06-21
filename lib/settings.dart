import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
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

  // --- EXTERNAL ROUTING ENGINES ---
  final Uri _websiteUrl = Uri.parse('https://www.github.com/darshseraphic/');
  final Uri _feedbackUrl = Uri.parse('https://darshseraphic.github.io/');

  Future<void> _launchWebsiteUrl() async {
    try {
      if (!await launchUrl(_websiteUrl, mode: LaunchMode.externalApplication)) {
        throw Exception('COULD NOT LAUNCH OUTWARD SYSTEM PIPELINE PORTAL');
      }
    } catch (e) {
      developer.log('System Error: Handshake failed for Website URI.', error: e);
    }
  }

  Future<void> _launchFeedbackUrl() async {
    try {
      if (!await launchUrl(_feedbackUrl, mode: LaunchMode.externalApplication)) {
        throw Exception('COULD NOT LAUNCH FEEDBACK PIPELINE PORTAL');
      }
    } catch (e) {
      developer.log('System Error: Handshake failed for Feedback URI.', error: e);
    }
  }

  // --- SLIDING PANEL ANIMATION & ROUTING ---
  void _showSlidingPanel(String title, List<Widget> contentSections, SettingsUiTheme theme) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // Allows underlying settings to remain visible
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: FractionallySizedBox(
              widthFactor: 1.0,
              heightFactor: 1.0,
              alignment: Alignment.centerRight,
              child: Container(
                color: theme.canvasBg,
                padding: const EdgeInsets.all(24.0),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Panel Header with Back Navigation
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(), // Naturally reverses animation
                            child: Icon(Icons.arrow_back, color: theme.textMain, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              color: theme.textMain,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                      Divider(color: theme.ruleBorder, height: 32, thickness: 1.0),
                      // Scrollable Content Stack
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: contentSections,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Right-to-Left Open / Left-to-Right Close Animation
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.fastOutSlowIn;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  // --- INFORMATION SECTION BUILDER ---
  Widget _buildInfoSection(String heading, String details, SettingsUiTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading.toUpperCase(),
            style: TextStyle(
              color: theme.textMain,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            details,
            style: TextStyle(
              color: theme.textSub,
              fontSize: 10,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _openUserGuide(SettingsUiTheme theme) {
    _showSlidingPanel(
      'User Guide',
      [
        _buildInfoSection('System Root Engine', 'Built on a robust Riverpod state management infrastructure. Boot sequences feature a 2-second linear opacity Gateway Layer splash screen to stabilize core cache.', theme),
        _buildInfoSection('Layout Infrastructure', 'The interface is anchored by a Matrix Timeline utilizing a 13-column layout mapping 365 daily blocks, augmented by the Quicknote Sandbox Module for rapid data entry.', theme),
        _buildInfoSection('Weather Node', 'Provides real-time atmospheric telemetry. Displays ambient temperature, localized conditions, and dynamic sub-surface data points utilizing high-frequency updates.', theme),
        _buildInfoSection('Calendar Timeline', 'A multi-axis temporal grid. Enables rapid inspection of systemic intervals, event logging, and chronological data mapping across the 13-column layout infrastructure.', theme),
        _buildInfoSection('Map Detector (Compass)', 'Deploys localized spatial awareness arrays. Utilizes hardware magnetometer feeds to render precise directional vectors and orient regional telemetry in real time.', theme),
        _buildInfoSection('Snake Subroutine', 'An embedded logic-testing sandbox. Executes discrete grid-based motion sequences designed for neural synchronization, tactile calibration, and system downtime management.', theme),
      ],
      theme,
    );
  }

  void _openDataSecurity(SettingsUiTheme theme) {
    _showSlidingPanel(
      'Data Security',
      [
        _buildInfoSection('No-SQL Hive Engine', 'The system utilizes a lightweight, local NoSQL Hive engine rather than heavy SQL frameworks to maintain speed and strict localization.', theme),
        _buildInfoSection('Cache Reliability', 'A Memory-First Buffer Pipeline ensures zero-latency cache reads. Includes a Corruption Repair Failsafe that automatically resets broken data blocks to prevent infinite boot loops.', theme),
        _buildInfoSection('Zero-Cloud Sandbox', 'Operates within a strictly sandboxed, air-gapped local environment. Zero external sync pipelines are initiated, preventing remote telemetry scraping or data leaks.', theme),
        _buildInfoSection('Biometric Gatekeeper', 'Integrates native device security protocols to gate access. Secures private telemetry and critical logs behind encrypted biometric validation barriers.', theme),
        _buildInfoSection('Ephemeral State Lifecycle', 'Volatile operational states are strictly bound to the application lifecycle. Non-persistent caches are purged instantly upon process termination to deny memory snooping.', theme),
      ],
      theme,
    );
  }

  void _openPrivacyPolicy(SettingsUiTheme theme) {
    _showSlidingPanel(
      'Privacy Policy',
      [
        _buildInfoSection('Authorship & Deployment', 'System architecture authored by Darshseraphic. Built and deployed during an intensive 24-hour rapid development sprint.', theme),
        _buildInfoSection('Telemetry & Surveillance', 'Absolute Zero Data Accumulation. The system operates via Air-Gapped Hardware Isolation. The codebase contains no analytics, telemetry, or outward network bridges.', theme),
        _buildInfoSection('Hardware Permissions', 'Hardware handshakes (such as location nodes or magnetometers) are processed strictly on-device. Telemetry data never logs to permanent files or leaks beyond the active session.', theme),
        _buildInfoSection('Third-Party Isolation', 'Zero integration with external SDKs, ad networks, or tracker vectors. The ecosystem remains unpolluted by commercial telemetry scripts.', theme),
        _buildInfoSection('User Sovereignty', 'You retain total ownership of your sandbox. Because all data blocks reside inside your local Hive containers, purging the application instantly and irreversibly wipes all footprint logs.', theme),
      ],
      theme,
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
              const SizedBox(height: 2),
              Text(
                'SETTING',
                style: TextStyle(color: theme.textMain, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.0),
              ),

              const SizedBox(height: 32),

              // [01] INTERFACE THEME TOGGLE (Custom Hardware-Accelerated UI Component)
              _buildMenuTile(
                title: 'DARK THEME',
                subtitle: isDark ? 'ACTIVE PROFILE // VERTICAL ABSOLUTE DARK' : 'ACTIVE PROFILE // VERTICAL ABSOLUTE LIGHT',
                textMain: theme.textMain,
                textSub: theme.textSub,
                borderColor: theme.ruleBorder,
                trailing: GestureDetector(
                  onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 44,
                    height: 24,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? theme.panelBg : theme.canvasBg,
                      border: Border.all(color: theme.ruleBorder, width: 1.5),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 120),
                      alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: theme.textMain,
                          shape: BoxShape.rectangle, // Inner indicator square
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // [02] USER GUIDE
              _buildMenuTile(
                title: 'USER GUIDE',
                subtitle: 'HOW TO USE THE APP EFFECTIVELY',
                textMain: theme.textMain,
                textSub: theme.textSub,
                borderColor: theme.ruleBorder,
                onTap: () => _openUserGuide(theme),
              ),

              const SizedBox(height: 16),

              // [03] DATA SECURITY
              _buildMenuTile(
                title: 'DATA SECURITY',
                subtitle: 'MORE INFORMATION ABOUT THE APP AND RELATED TO USER',
                textMain: theme.textMain,
                textSub: theme.textSub,
                borderColor: theme.ruleBorder,
                onTap: () => _openDataSecurity(theme),
              ),

              const SizedBox(height: 16),

              // [04] PRIVACY POLICY
              _buildMenuTile(
                title: 'PRIVACY PROTOCOLS',
                subtitle: 'AIR-GAPPED HARDWARE ISOLATION',
                textMain: theme.textMain,
                textSub: theme.textSub,
                borderColor: theme.ruleBorder,
                onTap: () => _openPrivacyPolicy(theme),
              ),

              const SizedBox(height: 16),

              // [05] WEBSITE ROUTING
              _buildMenuTile(
                title: 'GITHUB',
                subtitle: 'SEE AUTHOR GITHUB PROFILE AND MORE',
                textMain: theme.textMain,
                textSub: theme.textSub,
                borderColor: theme.ruleBorder,
                onTap: _launchWebsiteUrl,
              ),

              const SizedBox(height: 16),

              // [06] FEEDBACK ROUTING
              _buildMenuTile(
                title: 'OTHER APPS',
                subtitle: 'VIEW MORE APPS BUILD BY THE SAME PERSON',
                textMain: theme.textMain,
                textSub: theme.textSub,
                borderColor: theme.ruleBorder,
                onTap: _launchFeedbackUrl,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
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