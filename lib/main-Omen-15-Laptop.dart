import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'services/ads_service.dart';
import 'screens/shop_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/onboarding_service.dart';
import 'services/camera_service.dart';
import 'services/api_key_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Google Mobile Ads SDK
  await MobileAds.instance.initialize();
  // Only configure test devices in debug mode for development
  if (kDebugMode) {
    const testDeviceIds = [
      '244859454DE58AD483B5603F3727A7E8', // seen in log output
    ];
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: testDeviceIds),
    );
  }
  await AdsService.init();
  
  // Initialize services
  await Future.wait([
    CameraService.initialize(),
    ApiKeyManager.initialize(),
  ]);
  
  final completed = await OnboardingService.isCompleted();
  // If onboarding has not been completed, suspend ads from the very start so
  // the GlobalBannerHost doesn't load or display banners on the welcome flow.
  AdsService.suspendAds.value = !completed;
  runApp(SchnellVerkaufApp(onboardingCompleted: completed));
}

class SchnellVerkaufApp extends StatelessWidget {
  final bool onboardingCompleted;
  const SchnellVerkaufApp({super.key, required this.onboardingCompleted});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  title: 'Schnell Verkaufen',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          primary: Colors.orange,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
  builder: (context, child) => GlobalBannerHost(child: child ?? const SizedBox()),
      home: onboardingCompleted ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}

/// Hosts a single banner ad instance across the whole app so it doesn't
/// reload on every route change.
class GlobalBannerHost extends StatefulWidget {
  final Widget child;
  const GlobalBannerHost({super.key, required this.child});

  @override
  State<GlobalBannerHost> createState() => _GlobalBannerHostState();
}

class _GlobalBannerHostState extends State<GlobalBannerHost> with WidgetsBindingObserver {
  BannerAd? _ad;
  bool _loaded = false;
  int _retry = 0;

  static String get _bannerUnitId {
    // Always use real ad unit ID
    return 'ca-app-pub-5163515529550008/1306525347';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delay to ensure MediaQuery is ready (frame callback)
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAdaptiveAd());
  }

  @override
  void didChangeMetrics() {
    // Orientation/size change: reload adaptive ad size once.
    if (mounted) {
      _loadAdaptiveAd();
    }
  }

  Future<void> _loadAdaptiveAd() async {
    _ad?.dispose();
    _loaded = false;
    // Determine available width for adaptive banner
    final width = MediaQuery.of(context).size.width.truncate();
    AnchoredAdaptiveBannerAdSize? adaptiveSize;
    try {
      adaptiveSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    } catch (_) {
      adaptiveSize = null;
    }
    final adSize = adaptiveSize ?? AdSize.banner;

    _ad = BannerAd(
      size: adSize,
      adUnitId: _bannerUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
            setState(() {
              _loaded = true;
              _retry = 0;
            });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          // Retry with backoff (no fill or transient errors)
          final delay = Duration(seconds: (5 * (_retry + 1)).clamp(5, 30));
          _retry = (_retry + 1).clamp(0, 5);
          Future.delayed(delay, () { if (mounted) _loadAdaptiveAd(); });
        },
      ),
    );
    _ad!.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    return ValueListenableBuilder<bool>(
      valueListenable: AdsService.showAds,
      builder: (context, showAds, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: AdsService.suspendAds,
          builder: (context, suspended, __) {
        Widget banner = const SizedBox.shrink();
            // If suspended (e.g. onboarding) we never show banners here.
            if (suspended) {
              banner = const SizedBox.shrink();
            } else if (showAds) {
          if (_loaded && ad != null) {
            banner = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1, thickness: 0.5),
                SizedBox(
                  width: double.infinity,
                  height: ad.size.height.toDouble(),
                  child: Center(
                    child: SizedBox(
                      width: ad.size.width.toDouble(),
                      height: ad.size.height.toDouble(),
                      child: AdWidget(ad: ad),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Fallback Eigenwerbung
            banner = GestureDetector(
              onTap: () {
                navigatorKey.currentState!.push(
                  MaterialPageRoute(builder: (_) => const ShopScreen()),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1, thickness: 0.5),
                  Container(
                    color: Colors.black12,
                    width: double.infinity,
                    height: 50,
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/ads/fallback_banner.png',
                      fit: BoxFit.contain,
                      height: 50,
                      errorBuilder: (_, __, ___) => const Text(
                        'Eigene Werbung – Jetzt werbefrei werden',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }
        return Column(
          children: [
            Expanded(child: widget.child),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 100),
              child: banner,
            ),
          ],
        );
          },
        );
      },
    );
  }
}
