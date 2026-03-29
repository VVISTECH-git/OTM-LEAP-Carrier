import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:leapcarrier/core/providers/locale_provider.dart';
import 'package:leapcarrier/core/theme/leap_theme.dart';
import 'package:leapcarrier/features/auth/screens/splash_screen.dart';
import 'package:leapcarrier/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Prevent screenshots and recent-apps thumbnails from exposing sensitive
  // shipment, invoice, or bid data. Skipped in debug so devs can screenshot.
  // Implemented natively in MainActivity.kt — no third-party package needed.
  if (!kDebugMode) {
    const MethodChannel('com.vvis.leapcarrier/security')
        .invokeMethod('enableSecureFlag');
  }

  final localeProvider = LocaleProvider();
  // Carrier default: Navy Blue — professional / enterprise positioning
  final themeProvider  = LeapThemeProvider(
    defaultTheme: LeapThemes.navy,
    prefsKey: 'carrier_selected_theme',
  );

  unawaited(localeProvider.loadSavedLocale());
  unawaited(themeProvider.loadSavedTheme());

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: localeProvider),
      ChangeNotifierProvider.value(value: themeProvider),
    ],
    child: const LeapCarrierApp(),
  ));
}

class LeapCarrierApp extends StatelessWidget {
  const LeapCarrierApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider  = context.watch<LeapThemeProvider>();

    return MaterialApp(
      navigatorKey:               navigatorKey,
      debugShowCheckedModeBanner: false,
      title:                      'LEAP Carrier',
      theme:                      themeProvider.toMaterialTheme(),
      locale:                     localeProvider.locale,
      supportedLocales:           LocaleProvider.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}