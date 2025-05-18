import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formkey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 80,
                    color: Theme.of(context).colorScheme.inverseSurface,
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Form(
                  key: _formkey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Email textfield
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TextFormField(
                          validator: MultiValidator([
                            RequiredValidator(errorText: 'Enter email address'),
                            EmailValidator(errorText: 'Please correct email filled'),
                          ]),
                          decoration: InputDecoration(
                            hintText: 'Email',
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            errorStyle: TextStyle(fontSize: 18.0),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                              borderRadius: BorderRadius.all(Radius.circular(9.0)),
                            ),
                          ),
                        ),
                      ),
                    // Password field
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TextFormField(
                          obscureText: true,
                          validator: MultiValidator([
                            RequiredValidator(errorText: 'Please enter Password'),
                            MinLengthValidator(8, errorText: 'Password must be at least 8 characters'),
                            PatternValidator(r'(?=.*?[#!@$%^&*-])', errorText: 'Psw must have at least one special character'),
                          ]),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.key, color: Colors.green),
                            errorStyle: TextStyle(fontSize: 18.0),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
                              borderRadius: BorderRadius.all(Radius.circular(9.0)),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(200, 0, 0, 0),
                        child: Text('Forget Password!'),
                      ),
                      // Login button
                      Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Container(
                          child: ElevatedButton(
                            child: Text(
                              'Login',
                              style: TextStyle(color: Colors.white, fontSize: 22),
                            ),
                            onPressed: () {
                              if (_formkey.currentState!.validate()) {
                                print('form submitted');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          width: MediaQuery.of(context).size.width,
                          height: 50,
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
                          child: Center(
                            child: Text(
                              'Or Sign In Using!',
                              style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.inverseSurface),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                            child: Container(
                              height: 50,
                              width: 50,
                              alignment: Alignment.center,
                              child: FaIcon(
                                FontAwesomeIcons.google,
                                size: 30,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).colorScheme.inverseSurface),
                                borderRadius: BorderRadius.circular(10),
                                color: Theme.of(context).scaffoldBackgroundColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Center(
                        child: Container(
                          padding: EdgeInsets.only(top: 50),
                          child: Text(
                            'SIGN UP!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.lightBlue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}