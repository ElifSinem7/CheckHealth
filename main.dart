import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('A message has been received in the background: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProvider(create: (_) => RelativeSettingsController()),
      ],
      child: CheckHealthApp(),
    ),
  );
}

class SettingsController with ChangeNotifier {
  bool _isDarkTheme = false;
  String _currentLanguage = 'English';
  bool _isSoundEnabled = true;
  bool _isVoiceReadingEnabled = true;

  bool get isDarkTheme => _isDarkTheme;
  String get currentLanguage => _currentLanguage;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isVoiceReadingEnabled => _isVoiceReadingEnabled;

  void toggleTheme(bool isDark) {
    _isDarkTheme = isDark;
    notifyListeners();
  }

  void changeLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }

  void toggleSound(bool isEnabled) {
    _isSoundEnabled = isEnabled;
    notifyListeners();
  }

  void toggleVoiceReading(bool isEnabled) {
    _isVoiceReadingEnabled = isEnabled;
    notifyListeners();
  }

  void saveAccountSettings() {
    // Implement save functionality (e.g., save settings to local storage or Firebase)
    print("Account settings saved");
  }

  Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      print("User logged out");
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  void contactRelative() {
    print("Contacting relative...");
  }
}

class CheckHealthApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settingsController = Provider.of<SettingsController>(context);
    return MaterialApp(
      title: 'Check Health',
      theme: ThemeData(
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(color: Colors.teal),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(color: Colors.teal[800]),
      ),
      themeMode: settingsController.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: SplashScreen(),
    );
  }
}




class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();

    // Flutter TTS nesnesi oluşturuluyor
    flutterTts = FlutterTts();

    // Sesli okuma için dil ve hız ayarları
    flutterTts.setLanguage('en-US');
    flutterTts.setSpeechRate(0.7);

    // Animasyon başlatılıyor
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    requestPermissions();

    Timer(const Duration(seconds: 10), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    flutterTts.stop();
    super.dispose();
  }


  Future<void> requestPermissions() async {
    // Request notification permission
    final notificationStatus = await Permission.notification.request();
    if (notificationStatus.isGranted) {
      print("Notification permission granted.");
    } else if (notificationStatus.isDenied) {
      print("Notification permission denied.");
    } else if (notificationStatus.isPermanentlyDenied) {
      print("Notification permission permanently denied. Opening settings.");
      await openAppSettings();
    }

    // Request microphone permission
    final microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus.isGranted) {
      print("Microphone permission granted.");
    } else if (microphoneStatus.isDenied) {
      print("Microphone permission denied.");
    } else if (microphoneStatus.isPermanentlyDenied) {
      print("Microphone permission permanently denied. Opening settings.");
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade500,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundTextPainter(),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animation.value,
                  child: Text(
                    'CheckHealth',
                    style: TextStyle(
                      fontSize: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BackgroundTextPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.tealAccent.withOpacity(0.05);

    final textSpan = TextSpan(
      text: 'CheckHealth',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.normal,
        color: Colors.white38,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Belirli aralıklarla ekran boyunca küçük "CheckHealth" yazılarını çiziyoruz
    for (double y = 0; y < size.height; y += 100) {
      for (double x = 0; x < size.width; x += 200) {
        textPainter.layout();
        textPainter.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


class LoginPage extends StatelessWidget {
  final FlutterTts flutterTts = FlutterTts();

  // Sesli okuma işlemi
  Future<void> _speak(BuildContext context, String text) async {
    final settingsController = Provider.of<SettingsController>(context, listen: false);
    if (settingsController.isVoiceReadingEnabled) {
      await flutterTts.speak(text); // Sesli okuma yapılıyor
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka plan baloncukları
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: BubbleBackgroundPainter(),
          ),
          // İçerik
          Column(
            children: [
              Spacer(),
              // Başlık yazısı
              Text(
                'CheckHealth',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                ),
              ),
              SizedBox(height: 20),
              // Giriş butonları
              Center(
                child: Column(
                  children: [
                    Consumer<SettingsController>(
                      builder: (context, settingsController, child) {
                        return buildButton(
                          context,
                          'Patient Entrance',
                          Icons.person,
                          Colors.teal.shade700,
                          EmailPasswordPage(nextPage: PatientHomePage()),
                          settingsController.isVoiceReadingEnabled,
                        );
                      },
                    ),
                    Consumer<SettingsController>(
                      builder: (context, settingsController, child) {
                        return buildButton(
                          context,
                          'Doctor Entrance',
                          Icons.local_hospital,
                          Colors.teal.shade500,
                          EmailPasswordPage(nextPage: DoctorHomePage()),
                          settingsController.isVoiceReadingEnabled,
                        );
                      },
                    ),
                    Consumer<SettingsController>(
                      builder: (context, settingsController, child) {
                        return buildButton(
                          context,
                          'Patient Relative Entrance',
                          Icons.family_restroom,
                          Colors.teal.shade300,
                          EmailPasswordPage(nextPage: RelativeHomePage()),
                          settingsController.isVoiceReadingEnabled,
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              // Alt yazı
              Text(
                'Your health, our priority,\nAnytime, Anywhere',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.teal.shade700,
                ),
              ),
              Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  // Buton Yapıcı
  Widget buildButton(BuildContext context, String text, IconData icon, Color color, Widget page, bool isVoiceReadingEnabled) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 15),
          textStyle: TextStyle(fontSize: 18),
        ),
        onPressed: () {
          // Sesli okuma başlatılıyor
          if (isVoiceReadingEnabled) {
            _speak(context, text);
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        icon: Icon(icon, size: 24),
        label: Text(text),
      ),
    );
  }
}

// Baloncuklu Arka Plan Çizici
class BubbleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Baloncuk renkleri
    paint.color = Colors.teal.withOpacity(0.3);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 60, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.4), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.6), 100, paint);

    paint.color = Colors.teal.withOpacity(0.15);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.8), 90, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.7), 50, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.2), 70, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class EmailPasswordPage extends StatefulWidget {
  final Widget nextPage;

  EmailPasswordPage({required this.nextPage});

  @override
  _EmailPasswordPageState createState() => _EmailPasswordPageState();
}

class _EmailPasswordPageState extends State<EmailPasswordPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => widget.nextPage),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: ${e.toString()}")),
      );
    }
  }

  Future<void> _register() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => widget.nextPage),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = Provider.of<SettingsController>(context);

    if (settingsController.isVoiceReadingEnabled) {
      FlutterTts().speak("Enter your email and password"); // Sesli okuma
    }

    return Scaffold(
      body: Stack(
        children: [
          // Plain background with a light color
          // Custom Painter for background
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: BubbleBackgroundPainter1(),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 32),
                    // Email Text Field
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Password Text Field
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    // Login Button
                    ElevatedButton(
                      onPressed: _login,
                      child: Text('Login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Register Button
                    ElevatedButton(
                      onPressed: _register,
                      child: Text('Register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent.shade700,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),


          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title (CheckHealth)
                    Container(
                      margin: EdgeInsets.only(bottom: 30),
                      child: Text(
                        '  ',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    // Email Text Field
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.teal),
                        filled: true,
                        fillColor: Colors.grey[300],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Password Text Field
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.teal),
                        filled: true,
                        fillColor: Colors.grey[300],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    // Login Button
                    ElevatedButton(
                      onPressed: _login,
                      child: Text('Login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Register Button
                    ElevatedButton(
                      onPressed: _register,
                      child: Text('Register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BubbleBackgroundPainter1 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      colors: [Colors.teal.shade600, Colors.white],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Background gradient
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Bubble painter
    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Draw bubbles
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.2), 50, bubblePaint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.3), 70, bubblePaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.8), 90, bubblePaint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.7), 40, bubblePaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.6), 60, bubblePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class PatientHomePage extends StatefulWidget {
  @override
  _PatientHomePageState createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  int _currentIndex = 0;

  // Define the list of tabs (pages) to display
  List<Widget> _tabs = [];

  // Tab switch handler
  void onTabTapped(int index) {
    if (index >= 0 && index < _tabs.length) {
      setState(() {
        _currentIndex = index;  // Update the current tab index
      });
    } else {
      print("Invalid index: $index");
    }
  }

  // Contact relative button handler
  void onContact_Relative() {
    print("onContact_Relative called");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SendNotificationsPage()),
    );
  }

  @override
  void initState() {
    super.initState();

    // Initialize the list of tabs with widgets and pass the callback to Settings
    _tabs = [
      PatientDashboard(),      // Tab 1
      HealthData(),            // Tab 2
      Reports(),               // Tab 3
      Doctors(),               // Tab 4
      SendNotificationsPage(), // Tab 5
      MyNotifications(),       // Tab 6
      Settings(                 // Tab 7 (Settings)
        onContact_Relative: onContact_Relative,
      ),
    ];
  }

  Future<void> requestPermissions() async {
    // Request microphone permission
    PermissionStatus microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus.isGranted) {
      print("Microphone permission granted.");
    } else if (microphoneStatus.isDenied) {
      print("Microphone permission denied.");
    } else if (microphoneStatus.isPermanentlyDenied) {
      print("Microphone permission permanently denied. Opening settings.");
      await openAppSettings();
      return; // Stop further permission requests
    }


    // Request notification permission
    PermissionStatus notificationStatus = await Permission.notification.request();
    if (notificationStatus.isGranted) {
      print("Notification permission granted.");
    } else if (notificationStatus.isDenied) {
      print("Notification permission denied.");
    } else if (notificationStatus.isPermanentlyDenied) {
      print("Notification permission permanently denied. Opening settings.");
      await openAppSettings();
      return;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex], // Display the widget at the current index
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard, color: Colors.blue),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart, color: Colors.green),
            label: 'Health Data',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report, color: Colors.orange),
            label: 'My Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital, color: Colors.teal),
            label: 'My Doctors',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.send, color: Colors.lightBlue.shade100),
              label: 'Send Notifications',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications, color: Colors.purple.shade400),
              label: 'My Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, color: Colors.grey),
            label: 'Settings',
          ),
        ],
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 14),
      ),
    );
  }
}

class PatientDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text(
            'Your health is important to us.',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            child: Text('View Your Health Data'),
            onPressed: () {
              // Navigate to Health Data
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HealthData()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class HealthData extends StatefulWidget {
  @override
  _HealthDataState createState() => _HealthDataState();
}

class _HealthDataState extends State<HealthData> {
  String selectedPeriod = 'Monthly'; // Default to monthly view

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Health Data', style: TextStyle(fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'My Health Data - $selectedPeriod',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[700],
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ChoiceChip(
                  label: Text('Monthly'),
                  selected: selectedPeriod == 'Monthly',
                  selectedColor: Colors.teal[200],
                  onSelected: (_) {
                    setState(() {
                      selectedPeriod = 'Monthly';
                    });
                  },
                ),
                ChoiceChip(
                  label: Text('Weekly'),
                  selected: selectedPeriod == 'Weekly',
                  selectedColor: Colors.teal[200],
                  onSelected: (_) {
                    setState(() {
                      selectedPeriod = 'Weekly';
                    });
                  },
                ),
                ChoiceChip(
                  label: Text('Daily'),
                  selected: selectedPeriod == 'Daily',
                  selectedColor: Colors.teal[200],
                  onSelected: (_) {
                    setState(() {
                      selectedPeriod = 'Daily';
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  if (selectedPeriod == 'Monthly') ...[
                    buildHealthCategory(context, 'Blood Pressure', BloodPressureChart(period: 'Monthly'), Icons.favorite),
                    buildHealthCategory(context, 'Heart Rate', HeartRateChart(period: 'Monthly'), Icons.favorite_border),
                    buildHealthCategory(context, 'Body Temperature', BodyTemperatureChart(period: 'Monthly'), Icons.thermostat),
                  ] else if (selectedPeriod == 'Weekly') ...[
                    buildHealthCategory(context, 'Blood Pressure ', BloodPressureChart(period: 'Weekly'), Icons.favorite),
                    buildHealthCategory(context, 'Heart Rate', HeartRateChart(period: 'Weekly'), Icons.favorite_border),
                    buildHealthCategory(context, 'Body Temperature', BodyTemperatureChart(period: 'Weekly'), Icons.thermostat),
                  ] else if (selectedPeriod == 'Daily') ...[
                    buildHealthCategory(context, 'Blood Pressure', BloodPressureChart(period: 'Daily'), Icons.favorite),
                    buildHealthCategory(context, 'Heart Rate', HeartRateChart(period: 'Daily'), Icons.favorite_border),
                    buildHealthCategory(context, 'Body Temperature', BodyTemperatureChart(period: 'Daily'), Icons.thermostat),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHealthCategory(BuildContext context, String title, Widget chartPage, IconData icon) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal, size: 30),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: chartPage,
            ),
          )));
        },
      ),
    );
  }
}

// Kan Basıncı Grafiği
class BloodPressureChart extends StatelessWidget {
  final String period;

  BloodPressureChart({required this.period});

  @override
  Widget build(BuildContext context) {
    List<FlSpot> data = [];
    if (period == 'Monthly') {
      data = [
        FlSpot(1, 120), FlSpot(2, 118), FlSpot(3, 115), FlSpot(4, 117),
        FlSpot(5, 119), FlSpot(6, 120), FlSpot(7, 116), FlSpot(8, 118),
        FlSpot(9, 115), FlSpot(10, 117), FlSpot(11, 119), FlSpot(12, 120),
      ];
    } else if (period == 'Weekly') {
      data = [
        FlSpot(1, 122), FlSpot(2, 118), FlSpot(3, 121), FlSpot(4, 119),
      ];
    } else if (period == 'Daily') {
      data = [FlSpot(1, 119), FlSpot(2, 120), FlSpot(3, 118)];
    }

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: data.length.toDouble(),
        minY: 110,
        maxY: 130,
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            color: Colors.green,
            barWidth: 5,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

// Kalp Atışı Grafiği
class HeartRateChart extends StatelessWidget {
  final String period;

  HeartRateChart({required this.period});

  @override
  Widget build(BuildContext context) {
    List<FlSpot> data = [];
    if (period == 'Monthly') {
      data = [
        FlSpot(1, 75), FlSpot(2, 78), FlSpot(3, 80), FlSpot(4, 76),
        FlSpot(5, 77), FlSpot(6, 79), FlSpot(7, 80), FlSpot(8, 76),
        FlSpot(9, 78), FlSpot(10, 79), FlSpot(11, 80), FlSpot(12, 77),
      ];
    } else if (period == 'Weekly') {
      data = [
        FlSpot(1, 78), FlSpot(2, 76), FlSpot(3, 77), FlSpot(4, 75),
      ];
    } else if (period == 'Daily') {
      data = [FlSpot(1, 80), FlSpot(2, 78), FlSpot(3, 79)];
    }

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: data.length.toDouble(),
        minY: 60,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            color: Colors.red,
            barWidth: 5,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

// Vücut Sıcaklığı Grafiği
class BodyTemperatureChart extends StatelessWidget {
  final String period;

  BodyTemperatureChart({required this.period});

  @override
  Widget build(BuildContext context) {
    List<FlSpot> data = [];
    if (period == 'Monthly') {
      data = [
        FlSpot(1, 36.5), FlSpot(2, 36.7), FlSpot(3, 36.8), FlSpot(4, 36.6),
        FlSpot(5, 36.7), FlSpot(6, 36.8), FlSpot(7, 36.6), FlSpot(8, 36.7),
        FlSpot(9, 36.8), FlSpot(10, 36.6), FlSpot(11, 36.7), FlSpot(12, 36.8),
      ];
    } else if (period == 'Weekly') {
      data = [
        FlSpot(1, 36.6), FlSpot(2, 36.7), FlSpot(3, 36.5), FlSpot(4, 36.8),
      ];
    } else if (period == 'Daily') {
      data = [FlSpot(1, 36.7), FlSpot(2, 36.6), FlSpot(3, 36.8)];
    }

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: data.length.toDouble(),
        minY: 36.5,
        maxY: 37.0,
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            color: Colors.blue,
            barWidth: 5,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}


class Reports extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Reports'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        children: [
          buildReportCard(context, '2023-10-01', 'Blood Pressure Report', 'Details for blood pressure check.',
              'Blood Pressure details: Systolic 140 mmHg, Diastolic 90 mmHg. High blood pressure is present.'),
          buildReportCard(context, '2023-09-15', 'Blood Sugar Report', 'Details for blood sugar levels check.',
              'Blood Sugar details: Fasting Glucose: 120 mg/dL, A1C: 7.2% - Onset of diabetes detected.'),
          buildReportCard(context, '2023-08-20', 'Heart Health Report', 'Details for heart health check.',
              'Heart Health details: ECG results are normal, but high cholesterol levels detected.'),
        ],
      ),
    );
  }

  Widget buildReportCard(BuildContext context, String date, String title, String description, String reportDetails) {
    return GestureDetector(
      onTap: () {
        // Tıklandığında detaylı rapor sayfasına yönlendir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailPage(title: title, date: date, reportDetails: reportDetails),
          ),
        );
      },
      child: Card(
        elevation: 4,
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Text(
            'Date: $date\n$description',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}

class ReportDetailPage extends StatelessWidget {
  final String title;
  final String date;
  final String reportDetails;

  ReportDetailPage({required this.title, required this.date, required this.reportDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$title Detail'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rapor Başlığı
            Text(
              title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            SizedBox(height: 8),
            // Rapor Tarihi
            Text(
              'Date: $date',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            // Rapor Detayı
            Text(
              reportDetails,
              style: TextStyle(fontSize: 18, height: 1.6),
            ),
            SizedBox(height: 20),
            // Additional Report Info
            buildAdditionalInfo(title),
            SizedBox(height: 20),
            // Button to go back
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);  // Return to the previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Return',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAdditionalInfo(String title) {
    if (title == 'Blood Pressure Report') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extra Information:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '• Treatment Recommendations: ACE inhibitors or diuretics have been recommended for hypertension treatment.\n'
                '• Follow-up: Regular blood pressure measurements should be made and treatment should be continued if necessary.\n'
                '• Lifestyle: Reducing salt intake, weight control and regular exercise are recommended.\n',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      );
    } else if (title == 'Blood Sugar Report') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extra Information:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
          '• Treatment Recommendations: Metformin or insulin treatment has been recommended for diabetes treatment.\n'
              '• Follow-up: Blood sugar levels should be monitored and insulin dose adjusted if necessary.\n'
              '• Lifestyle: Blood sugar control can be achieved with a low-carb diet and regular exercise.\n',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      );
    } else if (title == 'Heart Health Report') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extra Information:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '• Treatment Recommendations: Statin drugs are recommended for high cholesterol treatment.\n'
                '• Follow-up: Regular ECG and cholesterol tests should be performed to monitor heart health.\n'
                '• Lifestyle: Low-fat diet, regular exercise and quitting smoking are recommended.\n',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      );
    } else {
      return Container();  // Default case if title doesn't match
    }
  }
}

class Doctors extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Doctors'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        children: [
          buildDoctorCard(context, 'Dr. Ahmet Yılmaz', 'Internal Medicine', 'Prescription for fever, cough: Parol, Tussin.'),
          buildDoctorCard(context, 'Dr. Elif Demir', 'Cardiology', 'Prescription for high blood pressure: Inhibitor, Aspirin.'),
          buildDoctorCard(context, 'Dr. Mehmet Kaya', 'Diabetes', 'Prescription for blood sugar: Metformin.'),
        ],
      ),
    );
  }

  Widget buildDoctorCard(BuildContext context, String name, String specialty, String prescription) {
    return GestureDetector(
      onTap: () {
        // Doktor detay sayfasına yönlendir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorDetailPage(name: name, specialty: specialty, prescription: prescription),
          ),
        );
      },
      child: Card(
        elevation: 4,
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          title: Text(
            name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal),
          ),
          subtitle: Text(
            'Profession: $specialty\nPrescriptions: $prescription',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }
}

class DoctorDetailPage extends StatelessWidget {
  final String name;
  final String specialty;
  final String prescription;

  DoctorDetailPage({required this.name, required this.specialty, required this.prescription});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$name Details'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doktor Başlığı
            Text(
              name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            SizedBox(height: 8),
            // Uzmanlık Alanı
            Text(
              'Area of Specialization: $specialty',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            // Reçeteler
            Text(
              'Prescriptions Issued:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              prescription,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),
            // Ekstra Bilgi (örneğin hastanın doktorla olan ilişkisi)
            buildAdditionalInfo(specialty),
            SizedBox(height: 20),
            // Geri Dön Butonu
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);  // Önceki sayfaya dön
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Return',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAdditionalInfo(String specialty) {
    if (specialty == 'Internal Diseases') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extra Information:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '- Common illnesses include fever, flu, cough and colds.\n'
                '- Prescriptions usually include painkillers, antibiotics and cough syrups.\n'
                '- The health status of the patients is closely monitored, the treatment process is carefully followed.\n',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      );
    } else if (specialty == 'Cardiology') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extra Information:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
          '- High blood pressure, heart rhythm disorders and vascular diseases are treated.\n'
              '- In cardiologic treatments, drugs such as beta-blockers, ACE inhibitors are usually used.\n'
              '- Regular check-ups and lifestyle changes (exercise, diet) are integral parts of treatment\n',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      );
    } else if (specialty == 'Diabetes') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extra Information:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
          '- Diabetes treatment is aimed at regulating blood sugar levels and preventing complications.\n'
               '- Metformin, insulin therapy and dietary recommendations are common treatment options.\n'
               '- Patients should continuously monitor blood sugar and continue treatment with regular check-ups,\n',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      );
    } else {
      return Container();  // Default case if specialty doesn't match
    }
  }
}

class SendNotificationsPage extends StatefulWidget {
  @override
  _SendNotificationsPageState createState() => _SendNotificationsPageState();
}

class _SendNotificationsPageState extends State<SendNotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String? _receiverId;

  Future<void> _findReceiverByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _receiverId = querySnapshot.docs.first['uid'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User found! You can write your message.')),
        );
      } else {
        setState(() {
          _receiverId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user was found for the email address.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null || _receiverId == null || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message!')),
      );
      return;
    }

    try {
      await _firestore.collection('messages').add({
        'senderId': currentUser.uid,
        'receiverId': _receiverId,
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message sent successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message could not be sent: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Notification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Recipient Email Address',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _findReceiverByEmail(_emailController.text.trim()),
              child: Text('Find Recipient'),
            ),
            SizedBox(height: 16),
            if (_receiverId != null) ...[
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Write Your Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _sendMessage,
                child: Text('Send Message'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MyNotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("My Notifications"),
        ),
        body: Center(
          child: Text("User is not logged in."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("My Notifications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('receiverId', isEqualTo: userId) // Kullanıcıya ait mesajlar
            .orderBy('timestamp', descending: true) // Zaman sırasına göre sıralama
            .snapshots(),
        builder: (context, snapshot) {
          // Hata kontrolü
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // Yükleniyor göstergesi
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Veri kontrolü
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No notifications yet."));
          }

          // Mesajları listeleme
          final messages = snapshot.data!.docs;

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final senderId = message['senderId'] ?? "Unknown Sender";
              final content = message['message'] ?? "No Content";
              final timestamp = message['timestamp'] as Timestamp?;

              final timeText = timestamp != null
                  ? "${timestamp.toDate().hour}:${timestamp.toDate().minute}, ${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}"
                  : "Unknown Time";

              return ListTile(
                title: Text("From: $senderId"),
                subtitle: Text(content),
                trailing: Text(timeText),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsDetail_Page(
                        senderId: senderId,
                        message: content,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
class NotificationsDetail_Page extends StatelessWidget {
  final String senderId;
  final String message;

  NotificationsDetail_Page({required this.senderId, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Message from $senderId'),
        backgroundColor: Colors.purple.shade600,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sender ID: $senderId',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Message:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}



class Settings extends StatelessWidget {
  final VoidCallback onContact_Relative;

  Settings({required this.onContact_Relative});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSectionHeader("Preferences"),
            _buildThemeToggle(context),
            _buildLanguageSetting(context),
            _buildSoundSetting(context),
            _buildVoiceReadingOption(context),
            Divider(thickness: 1),
            _buildSectionHeader("Account"),
            _buildSaveAccountOption(context),
            _buildLogoutOption(context),
            Divider(thickness: 1),
            _buildSectionHeader("Communication"),
            _buildContact_RelativeOption(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return ListTile(
      title: Text("Dark Theme"),
      trailing: Switch(
        value: Provider.of<SettingsController>(context).isDarkTheme,
        onChanged: (bool value) {
          Provider.of<SettingsController>(context, listen: false)
              .toggleTheme(value);
          // Wrap MaterialApp in a Consumer widget to react to theme changes
        },
      ),
    );
  }

  Widget _buildLanguageSetting(BuildContext context) {
    return ListTile(
      title: Text("Language"),
      subtitle: Text(
        Provider.of<SettingsController>(context).currentLanguage,
      ),
      trailing: DropdownButton<String>(
        value: Provider.of<SettingsController>(context).currentLanguage,
        onChanged: (String? newValue) {
          if (newValue != null) {
            Provider.of<SettingsController>(context, listen: false)
                .changeLanguage(newValue);
            // Call a method to update app language resources here
          }
        },
        items: <String>['English', 'Turkish']
            .map<DropdownMenuItem<String>>((String language) {
          return DropdownMenuItem<String>(
            value: language,
            child: Text(language),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSoundSetting(BuildContext context) {
    return ListTile(
      title: Text("Enable Sounds"),
      trailing: Switch(
        value: Provider.of<SettingsController>(context).isSoundEnabled,
        onChanged: (bool value) {
          Provider.of<SettingsController>(context, listen: false)
              .toggleSound(value);
        },
      ),
    );
  }

  Widget _buildVoiceReadingOption(BuildContext context) {
    return ListTile(
      title: Text("Enable Voice Reading"),
      trailing: Switch(
        value: Provider.of<SettingsController>(context).isVoiceReadingEnabled,
        onChanged: (bool value) {
          Provider.of<SettingsController>(context, listen: false)
              .toggleVoiceReading(value);
        },
      ),
    );
  }

  Widget _buildSaveAccountOption(BuildContext context) {
    return ListTile(
      title: Text("Save Account"),
      onTap: () {
        Provider.of<SettingsController>(context, listen: false)
            .saveAccountSettings();
      },
      trailing: Icon(Icons.save, color: Colors.green),
    );
  }

  Widget _buildLogoutOption(BuildContext context) {
    return ListTile(
      title: Text("Logout"),
      onTap: () {
        Provider.of<SettingsController>(context, listen: false).logout(context);
      },
      trailing: Icon(Icons.logout, color: Colors.red),
    );
  }

  Widget _buildContact_RelativeOption() {
    return ListTile(
      title: Text("Contact Relative"),
      onTap: onContact_Relative,
      trailing: Icon(Icons.group, color: Colors.blue),
    );
  }
}



class DoctorHomePage extends StatefulWidget {
  @override
  _DoctorHomePageState createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  int _currentIndex = 0;

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void onContactPatient() {
    print("onContactPatient called");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SendNotificationPage()),
    );
  }

  late List<Widget> _relativeTabs;

  @override
  void initState() {
    super.initState();
    _relativeTabs = [
      DoctorDashboard(),
      PatientsPage(),
      SendNotificationPage(),
      MyNotificationPage(),
      SettingsPage(
        onContactPatient: onContactPatient,
      ),
    ];
  }

  void requestPermissions() async {
    // Request microphone permission
    PermissionStatus microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus.isGranted) {
      print("Microphone permission granted.");
    } else if (microphoneStatus.isDenied) {
      print("Microphone permission denied.");
    } else if (microphoneStatus.isPermanentlyDenied) {
      print("Microphone permission permanently denied. Opening settings.");
      openAppSettings();
    }


    // Request notification permission
    PermissionStatus notificationStatus = await Permission.notification.request();
    if (notificationStatus.isGranted) {
      print("Notification permission granted.");
    } else if (notificationStatus.isDenied) {
      print("Notification permission denied.");
    } else if (notificationStatus.isPermanentlyDenied) {
      print("Notification permission permanently denied. Opening settings.");
      await openAppSettings();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _relativeTabs[_currentIndex], // Fixed this line to use _relativeTabs
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard, color: Colors.blue),
            activeIcon: Icon(Icons.dashboard, color: Colors.blueAccent),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people, color: Colors.green),
            activeIcon: Icon(Icons.people, color: Colors.greenAccent),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send, color: Colors.orange),
            activeIcon: Icon(Icons.send, color: Colors.orangeAccent),
            label: 'Send Notification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications, color: Colors.purple),
            activeIcon: Icon(Icons.notifications, color: Colors.purpleAccent),
            label: 'My Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, color: Colors.red),
            activeIcon: Icon(Icons.settings, color: Colors.redAccent),
            label: 'Settings',
          ),
        ],
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 14),
      ),
    );
  }
}

class DoctorDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Doctor Dashboard', style: TextStyle(fontSize: 24)),
    );
  }
}

class PatientsPage extends StatelessWidget {
  final List<Map<String, String>> patients = [
    {'name': 'Ali Yılmaz', 'age': '35', 'condition': 'High Blood Pressure'},
    {'name': 'Ayşe Demir', 'age': '29', 'condition': 'Diabetes'},
    {'name': 'Mehmet Çelik', 'age': '47', 'condition': 'Heart Disease'},
    {'name': 'Zeynep Aksoy', 'age': '50', 'condition': 'Asthma'},
    {'name': 'Kerem Aydın', 'age': '62', 'condition': 'Arthritis'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patients', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
        backgroundColor: Colors.teal.shade500,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                onTap: () {
                  // Tıklandığında hastanın detay sayfasına git
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientDetailPage(patient: patient),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade500,
                  child: Text(
                    patient['name']![0],
                    style: TextStyle(fontSize: 22, color: Colors.white),
                  ),
                ),
                title: Text(
                  patient['name']!,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Age: ${patient['age']} - Disease: ${patient['condition']}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
class PatientDetailPage extends StatelessWidget {
  final Map<String, String> patient;

  PatientDetailPage({required this.patient});

  @override
  Widget build(BuildContext context) {
    // Detaylı hastalık bilgileri ve tedavi süreci
    final patientDetails = _getPatientDetails(patient['name']!);

    return Scaffold(
      appBar: AppBar(
        title: Text(patient['name']!, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
        backgroundColor: Colors.teal.shade500,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profil Fotoğrafı ve İsim
            Center(
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.teal.shade500,
                child: Text(
                  patient['name']![0],
                  style: TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                patient['name']!,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: Colors.teal.shade500),
              ),
            ),
            SizedBox(height: 32),

            // Yaş ve Rahatsızlık Bilgisi
            Text(
              'Age: ${patient['age']}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'Disease: ${patient['condition']}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 24),

            // İleri Düzey Tedavi Bilgileri
            Text(
              'Advanced Treatment Information:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.teal.shade500),
            ),
            SizedBox(height: 8),
            Text(
              '• Treatment Process: ${patientDetails['treatment']}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              '• Medicines Used: ${patientDetails['medications']}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              '• Doctors: ${patientDetails['doctors']}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),

            // Notlar veya Ekstra Bilgiler
            Text(
              'Notes: ${patientDetails['notes']}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // Her hastaya özgü tedavi bilgileri
  Map<String, String> _getPatientDetails(String name) {
    switch (name) {
      case 'Ali Yılmaz':
        return {
          'treatment': 'Blood pressure regulating medications and lifestyle changes.',
          'medications': 'Losartan, Amlodipine',
          'doctors': 'Dr. Ayşe Yılmaz, Dr. Mehmet Aksoy',
          'notes': 'Regular exercise and reduction of salt consumption were recommended.'
        };
      case 'Ayşe Demir':
        return {
          'treatment': 'Diabetes management and insulin therapy.',
          'medications': 'Insulin Glargine, Metformin',
          'doctors': 'Dr. Ali Kaya, Dr. Emine Gül',
          'notes': 'Low carb diet and sugar monitoring recommended.'
        };
      case 'Mehmet Çelik':
        return {
          'treatment': 'Heart disease treatment, angioplasty and stent placement.',
          'medications': 'Aspirin, Atorvastatin',
          'doctors': 'Dr. Kerem Şahin, Dr. Emine Yılmaz',
          'notes': 'Regular cardiologic follow-up and diet were recommended.'
        };
      case 'Zeynep Aksoy':
        return {
          'treatment': 'Asthma treatment and inhaler use.',
          'medications': 'Salbutamol, Budesonide',
          'doctors': 'Dr. Ahmet Aksoy, Dr. Kerem Demir',
          'notes': 'It was recommended to pay attention to ventilation and avoid triggers in winter.'
        };
      case 'Kerem Aydın':
        return {
          'treatment': 'Arthritis treatment, physical therapy and pain management.',
          'medications': 'Ibuprofen, Methotrexate',
          'doctors': 'Dr. Hakan Yılmaz, Dr. Esra Can',
          'notes': 'Physical therapy and regular exercise for joint mobility were recommended.'
        };
      default:
        return {
          'treatment': 'Information not available',
          'medications': 'Information not available',
          'doctors': 'Information not available',
          'notes': 'Information not available.'
        };
    }
  }
}



class SendNotificationPage extends StatefulWidget {
  @override
  _SendNotificationPageState createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String? _receiverId;

  Future<void> _findReceiverByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _receiverId = querySnapshot.docs.first['uid'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User found! You can write your message.')),
        );
      } else {
        setState(() {
          _receiverId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user was found for the email address.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null || _receiverId == null || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message!')),
      );
      return;
    }

    try {
      await _firestore.collection('messages').add({
        'senderId': currentUser.uid,
        'receiverId': _receiverId,
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message sent successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message could not be sent: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Notification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Recipient Email Address',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _findReceiverByEmail(_emailController.text.trim()),
              child: Text('Find Recipient'),
            ),
            SizedBox(height: 16),
            if (_receiverId != null) ...[
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Write Your Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _sendMessage,
                child: Text('Send Message'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MyNotificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("My Notifications"),
        ),
        body: Center(
          child: Text("User is not logged in."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("My Notifications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('receiverId', isEqualTo: userId) // Kullanıcıya ait mesajlar
            .orderBy('timestamp', descending: true) // Zaman sırasına göre sıralama
            .snapshots(),
        builder: (context, snapshot) {
          // Hata kontrolü
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // Yükleniyor göstergesi
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Veri kontrolü
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No notifications yet."));
          }

          // Mesajları listeleme
          final messages = snapshot.data!.docs;

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final senderId = message['senderId'] ?? "Unknown Sender";
              final content = message['message'] ?? "No Content";
              final timestamp = message['timestamp'] as Timestamp?;

              final timeText = timestamp != null
                  ? "${timestamp.toDate().hour}:${timestamp.toDate().minute}, ${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}"
                  : "Unknown Time";

              return ListTile(
                title: Text("From: $senderId"),
                subtitle: Text(content),
                trailing: Text(timeText),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Notifications_DetailPage(
                        senderId: senderId,
                        message: content,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
class Notifications_DetailPage extends StatelessWidget {
  final String senderId;
  final String message;

  Notifications_DetailPage({required this.senderId, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Message from $senderId'),
        backgroundColor: Colors.purple.shade600,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sender ID: $senderId',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Message:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final VoidCallback onContactPatient;

  SettingsPage({required this.onContactPatient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSectionHeader("Preferences"),
            _buildThemeToggle(context),
            _buildLanguageSetting(context),
            _buildSoundSetting(context),
            _buildVoiceReadingOption(context),
            Divider(thickness: 1),
            _buildSectionHeader("Account"),
            _buildSaveAccountOption(context),
            _buildLogoutOption(context),
            Divider(thickness: 1),
            _buildSectionHeader("Communication"),
            _buildContactPatientOption(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return ListTile(
      title: Text("Dark Theme"),
      trailing: Switch(
        value: Provider.of<SettingsController>(context).isDarkTheme,
        onChanged: (bool value) {
          Provider.of<SettingsController>(context, listen: false)
              .toggleTheme(value);
        },
      ),
    );
  }

  Widget _buildLanguageSetting(BuildContext context) {
    return ListTile(
      title: Text("Language"),
      subtitle: Text(
        Provider.of<SettingsController>(context).currentLanguage,
      ),
      trailing: DropdownButton<String>(
        value: Provider.of<SettingsController>(context).currentLanguage,
        onChanged: (String? newValue) {
          if (newValue != null) {
            Provider.of<SettingsController>(context, listen: false)
                .changeLanguage(newValue);
          }
        },
        items: <String>['English', 'Turkish']
            .map<DropdownMenuItem<String>>((String language) {
          return DropdownMenuItem<String>(
            value: language,
            child: Text(language),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSoundSetting(BuildContext context) {
    return ListTile(
      title: Text("Enable Sounds"),
      trailing: Switch(
        value: Provider.of<SettingsController>(context).isSoundEnabled,
        onChanged: (bool value) {
          Provider.of<SettingsController>(context, listen: false)
              .toggleSound(value);
        },
      ),
    );
  }

  Widget _buildVoiceReadingOption(BuildContext context) {
    return ListTile(
      title: Text("Enable Voice Reading"),
      trailing: Switch(
        value: Provider.of<SettingsController>(context).isVoiceReadingEnabled,
        onChanged: (bool value) {
          Provider.of<SettingsController>(context, listen: false)
              .toggleVoiceReading(value);
        },
      ),
    );
  }

  Widget _buildSaveAccountOption(BuildContext context) {
    return ListTile(
      title: Text("Save Account"),
      onTap: () {
        Provider.of<SettingsController>(context, listen: false)
            .saveAccountSettings();
      },
      trailing: Icon(Icons.save, color: Colors.green),
    );
  }

  Widget _buildLogoutOption(BuildContext context) {
    return ListTile(
      title: Text("Logout"),
      onTap: () {
        Provider.of<SettingsController>(context, listen: false).logout(context);
      },
      trailing: Icon(Icons.logout, color: Colors.red),
    );
  }

  Widget _buildContactPatientOption() {
    return ListTile(
      title: Text("Contact Patient"),
      onTap: onContactPatient,
      trailing: Icon(Icons.group, color: Colors.blue),
    );
  }
}






class RelativeHomePage extends StatefulWidget {
  @override
  _RelativeHomePageState createState() => _RelativeHomePageState();
}

class _RelativeHomePageState extends State<RelativeHomePage> {
  int _currentIndex = 0;

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void onContactRelative() {
    print("onContactRelative called"); // Debugging log
    setState(() {
      _currentIndex = 2; // Switch to the "Send Notification" tab
      print("Current index set to $_currentIndex"); // Debugging log
    });
  }

  late List<Widget> _relativeTabs;

  @override
  void initState() {
    super.initState();
    _relativeTabs = [
      RelativeDashboard(),
      MyRelatives(),
      SendNotification(),
      MyNotifications(),
      RelativeSettingsPage(
        onContactRelative: onContactRelative,
      ),
    ];
  }


  void requestPermissions() async {
    // Request microphone permission
    PermissionStatus microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus.isGranted) {
      print("Microphone permission granted.");
    } else if (microphoneStatus.isDenied) {
      print("Microphone permission denied.");
    } else if (microphoneStatus.isPermanentlyDenied) {
      print("Microphone permission permanently denied. Opening settings.");
      openAppSettings();
    }


    // Request notification permission
    PermissionStatus notificationStatus = await Permission.notification.request();
    if (notificationStatus.isGranted) {
      print("Notification permission granted.");
    } else if (notificationStatus.isDenied) {
      print("Notification permission denied.");
    } else if (notificationStatus.isPermanentlyDenied) {
      print("Notification permission permanently denied. Opening settings.");
      await openAppSettings();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _relativeTabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard, color: Colors.blue),
            activeIcon: Icon(Icons.dashboard, color: Colors.blueAccent),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.family_restroom, color: Colors.green),
            activeIcon: Icon(Icons.family_restroom, color: Colors.greenAccent),
            label: 'My Relatives',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send, color: Colors.orange),
            activeIcon: Icon(Icons.send, color: Colors.orangeAccent),
            label: 'Send Notification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications, color: Colors.purple),
            activeIcon: Icon(Icons.notifications, color: Colors.purpleAccent),
            label: 'My Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, color: Colors.red),
            activeIcon: Icon(Icons.settings, color: Colors.redAccent),
            label: 'Settings',
          ),
        ],
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 14),
      ),
    );
  }
}

// Components for Relative's Panel
class RelativeDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Relative Dashboard'));
  }
}

class MyRelatives extends StatelessWidget {
  final List<Map<String, dynamic>> relatives = [
    {
      'name': 'Mother: Fatma Yıldız',
      'conditions': ['Diabetes', 'High Blood Pressure'],
      'doctors': ['Dr. Ali Kaya', 'Dr. Emine Gül'],
    },
    {
      'name': 'Father: Ahmet Yıldız',
      'conditions': ['Heart Disease'],
      'doctors': ['Dr. Mehmet Aksoy'],
    },
    {
      'name': 'Sister: Selin Celik',
      'conditions': ['Asthma', 'Migraine'],
      'doctors': ['Dr. Ayşe Yılmaz', 'Dr. Kerem Şahin'],
    },
    {
      'name': 'Son: Can Aydın',
      'conditions': ['Arthritis'],
      'doctors': ['Dr. Leyla Ugur'],
    },
    {
      'name': 'Brother: Mehmet Yıldız',
      'conditions': ['Allergy'],
      'doctors': ['Dr. Elif Cetin'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Relatives'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: relatives.length,
          itemBuilder: (context, index) {
            final relative = relatives[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RelativeDetailPage(relative: relative),
                  ),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                margin: EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade700.withOpacity(0.8), Colors.tealAccent.withOpacity(0.5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Colors.teal.shade700, size: 36),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          relative['name'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class RelativeDetailPage extends StatelessWidget {
  final Map<String, dynamic> relative;

  RelativeDetailPage({required this.relative});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          relative['name'],
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profil Fotoğrafı ve Kişisel Bilgiler
              Center(
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.teal.shade700,
                  child: Icon(Icons.person, color: Colors.white, size: 80),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  relative['name'],
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                ),
              ),
              SizedBox(height: 32),

              // Rahatsızlıklar Başlığı ve Liste
              Text(
                'Diseases:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
              ),
              SizedBox(height: 8),
              ...relative['conditions'].map<Widget>((condition) {
                return _buildInfoCard(condition);
              }).toList(),
              SizedBox(height: 24),

              // Doktorlar Başlığı ve Liste
              Text(
                'Doctors:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
              ),
              SizedBox(height: 8),
              ...relative['doctors'].map<Widget>((doctor) {
                return _buildInfoCard(doctor);
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String info) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            info,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class SendNotification extends StatefulWidget {
  @override
  _SendNotificationState createState() => _SendNotificationState();
}

class _SendNotificationState extends State<SendNotification> {
  final List<String> relatives = [
    'Fatma Yıldız',
    'Ahmet Yıldız',
    'Selin Çelik',
    'Can Aydın',
    'Mehmet Yıldız',
  ];

  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose(); // Controller'ı temizle
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Notifications'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: relatives.map((relative) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.notifications, color: Colors.teal.shade700, size: 30),
                title: Text(relative),
                trailing: IconButton(
                  icon: Icon(Icons.send, color: Colors.teal.shade700),
                  onPressed: () {
                    _showMessageDialog(context, relative);
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showMessageDialog(BuildContext context, String relative) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Send a Message to $relative'),
          content: TextField(
            controller: _messageController,
            decoration: InputDecoration(hintText: 'Type your message here'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_messageController.text.isNotEmpty) {
                  _sendMessage(relative, _messageController.text);
                  _messageController.clear();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Message sent to $relative'),
                    ),
                  );
                }
              },
              child: Text('Send'),
            ),
          ],
        );
      },
    );
  }

  void _sendMessage(String recipient, String message) {
    FirebaseFirestore.instance.collection('messages').add({
      'recipient': recipient,
      'message': message,
      'timestamp': Timestamp.now(),
    });
  }
}


class MyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("My Notifications"),
        ),
        body: Center(
          child: Text("User is not logged in."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("My Notifications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('receiverId', isEqualTo: userId) // Kullanıcıya ait mesajlar
            .orderBy('timestamp', descending: true) // Zaman sırasına göre sıralama
            .snapshots(),
        builder: (context, snapshot) {
          // Hata kontrolü
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // Yükleniyor göstergesi
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Veri kontrolü
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No notifications yet."));
          }

          // Mesajları listeleme
          final messages = snapshot.data!.docs;

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final senderId = message['senderId'] ?? "Unknown Sender";
              final content = message['message'] ?? "No Content";
              final timestamp = message['timestamp'] as Timestamp?;

              final timeText = timestamp != null
                  ? "${timestamp.toDate().hour}:${timestamp.toDate().minute}, ${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}"
                  : "Unknown Time";

              return ListTile(
                title: Text("From: $senderId"),
                subtitle: Text(content),
                trailing: Text(timeText),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationDetail_Page(
                        senderId: senderId,
                        message: content,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
class NotificationDetail_Page extends StatelessWidget {
  final String senderId;
  final String message;

  NotificationDetail_Page({required this.senderId, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Message from $senderId'),
        backgroundColor: Colors.purple.shade600,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sender ID: $senderId',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Message:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}



class RelativeSettingsController extends ChangeNotifier {
  bool _isDarkTheme = false;
  String _currentLanguage = 'English';
  bool _isSoundEnabled = true;
  bool _isVoiceReadingEnabled = false;

  bool get isDarkTheme => _isDarkTheme;
  String get currentLanguage => _currentLanguage;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isVoiceReadingEnabled => _isVoiceReadingEnabled;

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void changeLanguage(String language) {
  _currentLanguage = language;
  _locale = language == 'English' ? const Locale('en') : const Locale('tr');
  notifyListeners();
  }


  void toggleTheme(bool isDark) {
    _isDarkTheme = isDark;
    notifyListeners();
  }


  void toggleSound(bool isEnabled) {
    _isSoundEnabled = isEnabled;
    notifyListeners();
  }

  void toggleVoiceReading(bool isEnabled) {
    _isVoiceReadingEnabled = isEnabled;
    notifyListeners();
  }

  void saveAccountSettings() {
    // Logic to save account settings
    print("Account settings saved.");
  }

  void logout() {
    // Logic to handle logout
    print("User logged out.");
  }

  void contactPatient() {
    // Logic to contact the patient
    print("Contacting patient...");
  }
}


class RelativeSettingsPage extends StatelessWidget {
  final VoidCallback onContactRelative;

  RelativeSettingsPage({required this.onContactRelative});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSectionHeader("Preferences"),
            _buildThemeToggle(context),
            _buildLanguageSetting(context),
            _buildSoundSetting(context),
            _buildVoiceReadingOption(context),
            Divider(thickness: 1),
            _buildSectionHeader("Account"),
            _buildSaveAccountOption(context),
            _buildLogoutOption(context),
            Divider(thickness: 1),
            _buildSectionHeader("Communication"),
            _buildContactRelativeOption(), // Integrates the onContactRelative callback
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return ListTile(
      title: Text("Dark Theme"),
      trailing: Switch(
        value: Provider.of<SettingsController>(context).isDarkTheme,
        onChanged: (bool value) {
          Provider.of<SettingsController>(context, listen: false)
              .toggleTheme(value);
        },
      ),
    );
  }

  Widget _buildLanguageSetting(BuildContext context) {
    return ListTile(
      title: Text("Language"),
      subtitle: Text(
        Provider.of<SettingsController>(context).currentLanguage,
      ),
      trailing: DropdownButton<String>(
        value: Provider.of<SettingsController>(context).currentLanguage,
        onChanged: (String? newValue) {
          if (newValue != null) {
            Provider.of<SettingsController>(context, listen: false)
                .changeLanguage(newValue);
          }
        },
        items: <String>['English', 'Turkish']
            .map<DropdownMenuItem<String>>((String language) {
          return DropdownMenuItem<String>(
            value: language,
            child: Text(language),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSoundSetting(BuildContext context) {
    return ListTile(
      title: Text("Enable Sounds"),
      trailing: Switch(
        value: Provider.of<SettingsController>(context).isSoundEnabled,
        onChanged: (bool value) {
          Provider.of<SettingsController>(context, listen: false)
              .toggleSound(value);
        },
      ),
    );
  }

  Widget _buildVoiceReadingOption(BuildContext context) {
    return ListTile(
      title: Text("Enable Voice Reading"),
      trailing: Switch(
        value: Provider.of<SettingsController>(context).isVoiceReadingEnabled,
        onChanged: (bool value) {
          Provider.of<SettingsController>(context, listen: false)
              .toggleVoiceReading(value);
        },
      ),
    );
  }

  Widget _buildSaveAccountOption(BuildContext context) {
    return ListTile(
      title: Text("Save Account"),
      onTap: () {
        Provider.of<SettingsController>(context, listen: false)
            .saveAccountSettings();
      },
      trailing: Icon(Icons.save, color: Colors.green),
    );
  }

  Widget _buildLogoutOption(BuildContext context) {
    return ListTile(
      title: Text("Logout"),
      onTap: () {
        Provider.of<SettingsController>(context, listen: false).logout(context);
      },
      trailing: Icon(Icons.logout, color: Colors.red),
    );
  }

  Widget _buildContactPatientOption(BuildContext context) {
    return ListTile(
      title: Text("Contact Patient"),
      onTap: () {
        //Provider.of<SettingsController>(context, listen: false)
        //.contactPatient();
      },
      trailing: Icon(Icons.person, color: Colors.blue),
    );
  }

  Widget _buildContactRelativeOption() {
    return ListTile(
      title: Text("Contact Relative"),
      onTap: onContactRelative,
      trailing: Icon(Icons.group, color: Colors.blue),
    );
  }


}