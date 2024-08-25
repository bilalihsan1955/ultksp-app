import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          systemOverlayStyle:
              SystemUiOverlayStyle.dark, // Light theme status bar
        ),
      ),
      darkTheme: ThemeData(
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent, // Transparent in dark theme
            statusBarIconBrightness:
                Brightness.light, // Light icons for dark mode
          ),
        ),
      ),
      themeMode: ThemeMode.system, // Switch theme based on system settings
      home: WebViewScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WebViewScreen extends StatefulWidget {
  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  bool _hasError = false;
  bool _hasConnectivity = true;
  late BuildContext _dialogContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUIOverlayStyle(); // Apply overlay style after UI is rendered
    });

    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        setState(() {
          _hasConnectivity = false;
          _hasError = true;
        });
        _showNoConnectionDialog();
      } else {
        setState(() {
          _hasConnectivity = true;
          _hasError = false;
        });
        if (_hasError) {
          Navigator.of(_dialogContext)
              .pop(); // Dismiss dialog if connection returns
          _controller.reload(); // Reload WebView after regaining connection
        }
      }
    });
  }

  void _updateSystemUIOverlayStyle() {
    final theme = Theme.of(context);

    if (theme.brightness == Brightness.dark) {
      // Transparent status bar in dark theme, no overlay
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      // Transparent status bar with black icons for light theme
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Black icons for light mode
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ));
    }
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _hasConnectivity = false;
        _hasError = true;
      });
      _showNoConnectionDialog();
    } else {
      setState(() {
        _hasConnectivity = true;
        _hasError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensuring status bar color is consistent with WebView on the home screen
    _updateSystemUIOverlayStyle();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: _hasConnectivity && !_hasError
            ? WebView(
                initialUrl: 'https://docs.flutter.dev/',
                javascriptMode: JavascriptMode.unrestricted,
                onWebViewCreated: (WebViewController webViewController) {
                  _controller = webViewController;
                },
                onPageFinished: (url) {
                  _updateSystemUIOverlayStyle(); // Re-apply overlay style when page finishes loading
                },
                onWebResourceError: (error) {
                  setState(() {
                    _hasError = true;
                  });
                },
              )
            : Center(
                child: Text(
                  'No internet connection. Please check your connection and try again.',
                  textAlign: TextAlign.center,
                ),
              ),
      ),
    );
  }

  void _showNoConnectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        _dialogContext = context;
        return AlertDialog(
          title: Text('No Internet Connection'),
          content: Text(
              'It seems you are not connected to the internet. Please check your connection and try again.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkConnectivity(); // Re-check connectivity
              },
              child: Text('Retry'),
            ),
          ],
        );
      },
    );
  }
}
