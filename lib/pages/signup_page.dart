import 'package:dahcpplication/controller/widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dahcpplication/pages/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget{
  static route() => MaterialPageRoute(
      builder: (context) => const SignUpPage(),
        );
      const SignUpPage({super.key});

      @override
      State<SignUpPage> createState() => _SignUpPageState();
}


class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> createUserWithEmailAndPassword() async {
    if (formKey.currentState!.validate()){}
    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      print(userCredential.user?.uid);
    } on FirebaseAuthException catch (e) {
      print(e.message);
    }
  }
  // Future registerUserWithEmailAndPassword(
  //   String name , String email , String password , String gender , DateTime birthdate) async{
  // try {
  //   User user = (await FirebaseAuth.instance.createUserWithEmailAndPassword(
  //     email: email,
  //     password: password,
  //   )).user!;

  //   if(user!= null){
  //     await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
  //       'name': name,
  //       'email': email
  //   }
  // } on FirebaseAuthException catch (e) {
      
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                'Sign Up.',
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),


              const SizedBox(height: 20),
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
                  await createUserWithEmailAndPassword();
                },
                child: const Text(
                  'SIGN UP',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text.rich(TextSpan(
                text: 'Already have an account? ',
                style: Theme.of(context).textTheme.titleMedium,
                children: [
                  TextSpan(
                    text: 'Sign In',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    recognizer: TapGestureRecognizer()..onTap = (){
                      nextScreen(context, const  LoginPage());
                    }
                  ),
                ],
              )),
              // GestureDetector(
              //   onTap: () {
              //     Navigator.push(context, LoginPage.route());
              //   },
              //   child: RichText(
              //     text: TextSpan(
              //       text: 'Already have an account? ',
              //       style: Theme.of(context).textTheme.titleMedium,
              //       children: [
              //         TextSpan(
              //           text: 'Sign In',
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