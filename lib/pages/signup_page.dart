import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dahcpplication/pages/login_page.dart';
import 'package:dahcpplication/controller/controller.dart';
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
  final cfPasswordController = TextEditingController();
  final birthdateController = TextEditingController();
  DateTime? birthdate ;
  String genderController = '';

  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> createUserWithEmailAndPassword() async {
    if (formKey.currentState!.validate()){
      if(passwordController.text != cfPasswordController.text){
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match')),
          );
          return;
      }else{
        try {
          UserCredential? userCredential =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

          await createUserDocument(userCredential);
          print(userCredential.user?.uid);

        } on FirebaseAuthException catch (e) {
          print(e.message);
        }
      }
      
    }
  }

  // create user document and collent in firestore
  Future<void> createUserDocument(UserCredential? userCredential) async{
    if (userCredential != null && userCredential.user != null){
      final uid = userCredential.user!.uid;
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .set({
            'email': userCredential.user!.email,
            'birthdate': birthdate != null ? Timestamp.fromDate(birthdate!) : null,
            'gender' : genderController,
            'foodAllergies': '',
            'medicalConditions': '',
          });
    }
  }

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
              const SizedBox(height: 30),
              TextFormField(
                controller: emailController,
                decoration: textInputDecoration.copyWith(
                  hintText: 'Email',
                  prefixIcon: Icon(
                    Icons.email,
                    color: Theme.of(context).colorScheme.secondary,),
                  
                ),
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
                  prefixIcon: Icon(
                    Icons.lock,
                    color: Theme.of(context).colorScheme.secondary,),
                ),
                obscureText: true,
                validator: (val){
                    if(val!.length < 6){
                      return 'Password must be at least 6 characters';
                    }else{
                      return null;
                    }
                  }
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: cfPasswordController,
                decoration: textInputDecoration.copyWith(
                  hintText: 'Confirm Password',
                  prefixIcon: Icon(
                    Icons.lock,
                    color: Theme.of(context).colorScheme.secondary,),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 15),
              // birthdate field over 15 year old
              TextFormField(
                controller : birthdateController,
                readOnly: true,
                decoration: textInputDecoration.copyWith(
                  hintText: 'Birthdate',
                  prefixIcon: Icon(
                    Icons.calendar_month,
                    color: Theme.of(context).colorScheme.secondary,),
                ),
                                // ...existing code...
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light(),
                        child: child!,
                      );
                    },
                  );
                  if (pickedDate != null) {
                    setState(() {
                      birthdate = pickedDate; // เก็บเป็น DateTime
                      birthdateController.text =
                          "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                    });
                  }
                },
                // ...existing code...
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your bithdate';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              //gender male and female selector
              DropdownButtonFormField<String>(
                value: genderController.isNotEmpty ? genderController: null,
                decoration: textInputDecoration.copyWith(
                  hintText: 'Gender',
                  prefixIcon: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (value) {
                  setState(() {
                    genderController = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your gender';
                  }
                  return null;
                },
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
                    text: ' Sign In',
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
            ],
          ),
        ),
      ),
    );
  }
}