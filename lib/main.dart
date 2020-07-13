import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_segment/flutter_segment.dart';
import 'package:fusecash/models/app_state.dart';
import 'package:fusecash/redux/state/store.dart';
import 'package:fusecash/screens/routes.gr.dart';
import 'package:fusecash/themes/app_theme.dart';
import 'package:fusecash/themes/custom_theme.dart';
import 'package:redux/redux.dart';
import 'package:flutter/foundation.dart';
import 'package:fusecash/generated/i18n.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DotEnv().load('.env');
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  Store<AppState> store = await AppFactory().getStore();
  String initialRoute =
      checkIsLoggedIn(store) ? Router.lockScreen : Router.splashScreen;
  runZonedGuarded<Future<void>>(
      () async => runApp(CustomTheme(
            initialThemeKey: MyThemeKeys.DEFAULT,
            child: new MyApp(store: store, initialRoute: initialRoute),
          )), (Object error, StackTrace stackTrace) async {
    try {
      await AppFactory().reportError(error, stackTrace);
    } catch (e) {
      print('Sending report to sentry.io failed: $e');
      print('Original error: $error');
    }
  });

  FlutterError.onError = (FlutterErrorDetails details) {
    if (AppFactory().isInDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };
}

bool checkIsLoggedIn(Store<AppState> store) {
  String privateKey = store.state.userState.privateKey;
  String jwtToken = store.state.userState.jwtToken;
  bool isLoggedOut = store.state.userState.isLoggedOut;
  if (privateKey.isNotEmpty && jwtToken.isNotEmpty && !isLoggedOut) {
    return true;
  }
  return false;
}

class MyApp extends StatefulWidget {
  final Store<AppState> store;
  final String initialRoute;
  MyApp({Key key, this.store, this.initialRoute}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final i18n = I18n.delegate;
  // BiometricAuth _biometricType;

  void onLocaleChange(Locale locale) {
    setState(() {
      I18n.locale = locale;
    });
  }

  @override
  void initState() {
    super.initState();
    I18n.onLocaleChanged = onLocaleChange;
  }

  @override
  Widget build(BuildContext context) {
    return StoreProvider<AppState>(
        store: widget.store,
        child: MaterialApp(
          title: 'Fuse Cash',
          initialRoute: widget.initialRoute,
          navigatorKey: Router.navigator.key,
          onGenerateRoute: Router.onGenerateRoute,
          theme: CustomTheme.of(context),
          localizationsDelegates: [
            i18n,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: i18n.supportedLocales,
          localeResolutionCallback:
              i18n.resolution(fallback: new Locale("en", "US")),
          navigatorObservers: [SegmentObserver()],
        ));
  }
}
