import 'dart:async';

import 'package:flutter/material.dart';

import 'homepage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  Timer? _timer;

  _startDelay(){
    _timer = Timer(const Duration(seconds: 2), _goNext);
  }

  _goNext(){
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => const HomePage(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _startDelay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF008080),
      body: Center(
        child: Icon(Icons.mic,size: 300.0,color: Colors.amberAccent,),
        // child: Image.asset('assets/image/SplashLogo.jpg'),
      ),
    );
  }
}
