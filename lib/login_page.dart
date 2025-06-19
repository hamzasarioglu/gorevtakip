import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isLogin = true;
  String errorMessage = '';
  String selectedYetki = 'calisan';

  void _toggleFormType() {
    setState(() {
      isLogin = !isLogin;
      errorMessage = '';
    });
  }

  Future<void> _submit() async {
    try {
      if (isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final userId = FirebaseAuth.instance.currentUser!.uid;
        final userDoc = await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(userId)
            .get();

        final role = userDoc.data()?['yetki'] ?? 'calisan';
        _navigateToHome(role);
      } else {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(userCredential.user!.uid)
            .set({
          'email': _emailController.text.trim(),
          'yetki': selectedYetki,
        });

        _navigateToHome(selectedYetki);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'Bir hata oluştu';
      });
    }
  }

  void _navigateToHome(String yetki) {
    if (yetki == 'yonetici') {
      Navigator.pushReplacementNamed(context, '/adminHome');
    } else {
      Navigator.pushReplacementNamed(context, '/employeeHome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Icon(Icons.task_alt, size: 80, color: Theme.of(context).primaryColor),
            SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Parola',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            if (!isLogin) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.person_outline),
                  SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedYetki,
                      onChanged: (value) {
                        setState(() {
                          selectedYetki = value!;
                        });
                      },
                      decoration: InputDecoration(labelText: 'Yetki Seçin'),
                      items: [
                        DropdownMenuItem(
                          value: 'calisan',
                          child: Text('Çalışan'),
                        ),
                        DropdownMenuItem(
                          value: 'yonetici',
                          child: Text('Yönetici'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(48),
              ),
              child: Text(isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: _toggleFormType,
              child: Text(
                isLogin
                    ? 'Hesabın yok mu? Kayıt ol'
                    : 'Zaten hesabın var mı? Giriş yap',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
