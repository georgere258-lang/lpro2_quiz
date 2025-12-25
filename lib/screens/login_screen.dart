import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'main_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _fullPhoneNumber = "";
  String _verificationId = ""; 
  bool _codeSent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // مراقب ذكي: إذا تم تسجيل الدخول بنجاح في أي لحظة، يتم النقل فوراً
    _auth.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        _goToHome();
      }
    });
  }

  // دالة إرسال الكود
  Future<void> _sendCode() async {
    if (_fullPhoneNumber.isEmpty) {
      _showSnackBar("يرجى إدخال رقم الهاتف أولاً");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _fullPhoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // التحقق التلقائي بواسطة أندرويد
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          _showSnackBar("فشل التحقق: ${e.message}");
        },
        codeSent: (String verId, int? resendToken) {
          setState(() {
            _verificationId = verId;
            _codeSent = true;
            _isLoading = false;
          });
          _showSnackBar("تم إرسال الكود بنجاح");
        },
        codeAutoRetrievalTimeout: (String verId) {
          _verificationId = verId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("حدث خطأ غير متوقع");
    }
  }

  // دالة التأكد من الكود يدوياً
  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length < 6) {
      _showSnackBar("يرجى إدخال الكود كاملاً (6 أرقام)");
      return;
    }

    setState(() => _isLoading = true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );
      
      await _auth.signInWithCredential(credential);
      _goToHome();
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String errorMsg = "كود التحقق غير صحيح";
      if (e.code == 'session-expired') errorMsg = "انتهت صلاحية الكود، اطلب كوداً جديداً";
      _showSnackBar(errorMsg);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("فشل تسجيل الدخول");
    }
  }

  void _goToHome() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (c) => const MainWrapper()), 
        (route) => false
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color brandOrange = Color(0xFFFF8C42);
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B3358), Color(0xFF061121)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/logo.svg', height: 90),
                const SizedBox(height: 50),
                
                if (!_codeSent)
                  IntlPhoneField(
                    style: const TextStyle(color: Colors.white),
                    initialCountryCode: 'EG',
                    languageCode: "ar",
                    dropdownTextStyle: const TextStyle(color: Colors.white),
                    cursorColor: brandOrange,
                    decoration: InputDecoration(
                      labelText: 'رقم الموبايل',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: brandOrange),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onChanged: (phone) => _fullPhoneNumber = phone.completeNumber,
                  )
                else
                  TextField(
                    controller: _otpController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                    cursorColor: brandOrange,
                    decoration: InputDecoration(
                      labelText: 'أدخل كود التحقق',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: brandOrange),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                _isLoading 
                  ? const CircularProgressIndicator(color: brandOrange)
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
                        ),
                        onPressed: _codeSent ? _verifyOtp : _sendCode,
                        child: Text(
                          _codeSent ? "تأكيد ودخول" : "إرسال كود التحقق",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                
                if (_codeSent && !_isLoading)
                  TextButton(
                    onPressed: () => setState(() => _codeSent = false),
                    child: const Text(
                      "تعديل رقم الهاتف؟",
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}