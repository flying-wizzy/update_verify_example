// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_example/main.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth.dart';


/// Profile page shows after sign in or registerationg
class ProfilePage extends StatefulWidget {
  // ignore: public_member_api_docs
  const ProfilePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User user;
  late TextEditingController controller;
  final newMailController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    user = auth.currentUser!;

    auth.userChanges().listen((event) {
      if (event != null && mounted) {
        setState(() {
          user = event;
        });
      }
    });

    log(user.toString());
    super.initState();
  }




  Future updateDisplayName() async {
    await user.updateDisplayName("Hello Firebase Team");
    ScaffoldSnackbar.of(context).show('Name updated');
  }

  Future<void> handleVerifyAndUpdateEmail() async {
    try {
      await FirebaseAuth.instance.currentUser
          ?.verifyBeforeUpdateEmail(newMailController.text);
    } on FirebaseAuthException catch (err) {
      if (err.code == "requires-recent-login") {
        final bool? reAuthenticated = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReAuthPage()));
        if (reAuthenticated ?? false) {
           await handleVerifyAndUpdateEmail();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        body: Stack(
          children: [
            Center(
              child: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      Text(user.displayName ?? "no display name"),
                      Text(user.email ?? user.phoneNumber ?? 'User'),
                      const SizedBox(height: 10),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: newMailController,
                        decoration: const InputDecoration(
                          labelText: "Enter new Mail",
                        ),
                      ),
                      TextButton(
                        onPressed: handleVerifyAndUpdateEmail, child: const Text('Verify and Update Email'),
                      ),
                      TextButton(
                        onPressed: isLoading ? null : updateDisplayName,
                        child: const Text('Update Display Name'),
                      ),
                      TextButton(
                        onPressed: _signOut,
                        child: const Text('Sign out'),
                      ),
                      TextButton(
                        onPressed: ()=> FirebaseAuth.instance.currentUser?.delete(),
                        child: const Text('Delete Account'),
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


  /// Example code for sign out.
  Future<void> _signOut() async {
    await auth.signOut();
    await GoogleSignIn().signOut();
  }
}

class ReAuthPage extends StatelessWidget {
  const ReAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: EmailReAuthSection(),
    );
  }
}

class EmailReAuthSection extends StatelessWidget {
  EmailReAuthSection({Key? key}) : super(key: key);

  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _mailController,
            decoration: const InputDecoration(
              labelText: 'Enter Mail',
            ),
          ),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Enter Password',
            ),
          ),
          _LoginButton(
              mailController: _mailController,
              passwordController: _passwordController,
              formKey: formKey),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    Key? key,
    required this.mailController,
    required this.passwordController,
    required this.formKey,
  }) : super(key: key);

  final TextEditingController mailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        if (mailController.text.isNotEmpty &&
            passwordController.text.isNotEmpty) {
          if(formKey.currentState?.validate() ?? false) {
            try {
              final AuthCredential mailCredential = EmailAuthProvider
                  .credential(
                email: mailController.text,
                password: passwordController.text,
              );
              await FirebaseAuth.instance.currentUser
                  ?.reauthenticateWithCredential(mailCredential);
              Navigator.pop(context);
            } catch (e){
              debugPrint(e.toString());
            }

          }
        } else {
        }
      }, child: const Text('Re-Authenticate'),
    );
  }
}
