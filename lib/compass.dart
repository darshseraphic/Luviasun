import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'main.dart';

class MapUiTheme {
  final bool isDark;
  late final Color appBg;
  late final Color mapCanvasBg;
  late final Color textMain;
  late final Color ruleBorder;

  MapUiTheme(this.isDark) {
    appBg = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    textMain = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    ruleBorder = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5);
    mapCanvasBg = isDark ? const Color(0xFF141414) : const Color(0xFFEBF0F2);
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final bool isDark = ref.watch(themeProvider);
        final theme = MapUiTheme(isDark);

        final String tileUrlTemplate = isDark
            ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
            : 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';

        return Scaffold(
          backgroundColor: theme.appBg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.appBg,
                    border: Border(
                        bottom:
                            BorderSide(color: theme.ruleBorder, width: 1.0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          'MAP',
                          style: TextStyle(
                            color: theme.textMain,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: theme.mapCanvasBg,
                    child: Consumer(
                      builder: (context, mapRef, child) {
                        final activeCoordinates =
                            mapRef.watch(coordinateProvider);

                        return FlutterMap(
                          key: ValueKey(
                              '${activeCoordinates.latitude}_${activeCoordinates.longitude}'),
                          options: MapOptions(
                            initialCenter: activeCoordinates,
                            initialZoom: 12.0,
                            maxZoom: 18.0,
                            minZoom: 3.2,
                            cameraConstraint:
                                const CameraConstraint.containLatitude(),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: tileUrlTemplate,
                              userAgentPackageName: 'com.darsheraphic.luviasun',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
