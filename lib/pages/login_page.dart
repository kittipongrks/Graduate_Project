import 'package:dahcpplication/controller/widget.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dahcpplication/pages/signup_page.dart';

class LoginPage extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const LoginPage(),
      );
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String email = '';
  String password = '';
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUserWithEmailAndPassword() async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      print(userCredential);
    } on FirebaseAuthException catch (e) {
      print(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person,
                size: 80,
              ),
              const Text(
                'Sign In.',
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: emailController,
                decoration: textInputDecoration.copyWith(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                onChanged: (val){
                  setState(() {
                    email = val ;
                  });
                },
                validator: (val){
                  if(val!.isEmpty){
                    return 'Please enter your email';
                  }
                  if(!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(val)){
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),


              const SizedBox(height: 15),
              TextFormField(
                controller: passwordController,
                decoration: textInputDecoration.copyWith(
                  hintText: 'password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                onChanged: (val){
                  setState(() {
                    password = val;
                  });
                },
                validator: (val){
                    if(val!.length < 6){
                      return 'Password must be at least 6 characters';
                    }else{
                      return null;
                    }
                  }
              ),



              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await loginUserWithEmailAndPassword();
                },
                child: const Text(
                  'SIGN IN',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text.rich(TextSpan(
                text: 'Don\'t have an account? ',
                style: Theme.of(context).textTheme.titleMedium,
                children: [
                  TextSpan(
                    text: 'Sign Up',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    recognizer: TapGestureRecognizer()..onTap = (){
                      nextScreenReplace(context, const  SignUpPage());
                    }
                  ),
                ],
              )),
              // GestureDetector(
              //   onTap: () {
              //     Navigator.push(context, SignUpPage.route());
              //   },
              //   child: RichText(
              //     text: TextSpan(
              //       text: 'Don\'t have an account? ',
              //       style: Theme.of(context).textTheme.titleMedium,
              //       children: [
              //         TextSpan(
              //           text: 'Sign Up',
              //           style:
              //               Theme.of(context).textTheme.titleMedium?.copyWith(
              //                     fontWeight: FontWeight.bold,
              //                   ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}