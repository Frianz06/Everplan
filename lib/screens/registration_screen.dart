import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _companyController = TextEditingController();
  String? _selectedCompany;

  String _selectedRole = 'Employee';
  final List<String> _roles = ['Project Manager', 'Employee'];

  final Color bgColor = const Color.fromRGBO(249, 248, 244, 1);
  final Color inputColor = const Color.fromRGBO(220, 226, 216, 1);
  final Color buttonColor = const Color.fromRGBO(105, 139, 106, 1);
  final Color textColor = const Color.fromRGBO(63, 70, 62, 1);
  final Color iconColor = const Color.fromRGBO(99, 109, 98, 1);

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _registerUser() async {
    if (_selectedRole == 'Project Manager' && _companyController.text.trim().isEmpty) {
      _showSnackBar("Please enter a company name", Colors.orangeAccent);
      return;
    }
    if (_selectedRole == 'Employee' && _selectedCompany == null) {
      _showSnackBar("Please select a company", Colors.orangeAccent);
      return;
    }

    try {
      final creds = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String company = _selectedRole == 'Project Manager' 
          ? _companyController.text.trim() 
          : _selectedCompany!;

      await FirebaseFirestore.instance.collection('users').doc(creds.user!.uid).set({
        'uid': creds.user!.uid,
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'company': company,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (_selectedRole == 'Project Manager') {
        await FirebaseFirestore.instance.collection('companies').doc(company).set({
          'adminUid': creds.user!.uid,
          'name': company,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: bgColor,
          title: const Text("Success"),
          content: Text("Account for ${_nameController.text.trim()} is ready."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text("OK", style: TextStyle(color: buttonColor)),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Error", Colors.redAccent);
    } catch (e) {
      _showSnackBar("An error occurred", Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                Icon(Icons.person_add_outlined, size: 80, color: buttonColor),
                const SizedBox(height: 20),
                Text("Create Account", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 40),
                
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(hintText: "Full Name", prefixIcon: Icon(Icons.person_outline, color: iconColor), filled: true, fillColor: inputColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 15),
                
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(hintText: "Email", prefixIcon: Icon(Icons.email_outlined, color: iconColor), filled: true, fillColor: inputColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(filled: true, fillColor: inputColor, prefixIcon: Icon(Icons.security, color: iconColor), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                  items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setState(() {
                    _selectedRole = val!;
                    _selectedCompany = null; 
                  }),
                ),
                const SizedBox(height: 15),

                // --- UPDATED CONDITIONAL COMPANY FIELDS ---
                if (_selectedRole == 'Project Manager')
                  TextField(
                    controller: _companyController,
                    decoration: InputDecoration(
                      hintText: "Company Name",
                      prefixIcon: Icon(Icons.business, color: iconColor),
                      filled: true,
                      fillColor: inputColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),

                if (_selectedRole == 'Employee')
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('companies').snapshots(),
                    builder: (context, snapshot) {
                      // We handle loading state inside the dropdown to avoid the "loading underline"
                      List<DropdownMenuItem<String>> items = [];
                      if (snapshot.hasData) {
                        items = snapshot.data!.docs.map((doc) => 
                          DropdownMenuItem(value: doc.id, child: Text(doc.id))
                        ).toList();
                      }
                      
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedCompany,
                        hint: Text(snapshot.hasData ? "Select Company" : "Loading companies..."),
                        decoration: InputDecoration(
                          filled: true, 
                          fillColor: inputColor, 
                          prefixIcon: Icon(Icons.list_alt, color: iconColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
                        ),
                        items: items,
                        onChanged: snapshot.hasData ? (val) => setState(() => _selectedCompany = val) : null,
                      );
                    },
                  ),
                const SizedBox(height: 15),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(hintText: "Password", prefixIcon: Icon(Icons.lock_outline, color: iconColor), filled: true, fillColor: inputColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 15),
                
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(hintText: "Confirm Password", prefixIcon: Icon(Icons.lock_reset, color: iconColor), filled: true, fillColor: inputColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_passwordController.text != _confirmPasswordController.text) {
                        _showSnackBar("Passwords don't match", Colors.redAccent);
                        return;
                      }
                      _registerUser();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: buttonColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: const Text("Register", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 25),
                
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text.rich(
                    TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: textColor, fontSize: 14),
                      children: [
                        TextSpan(
                          text: "Login here",
                          style: TextStyle(
                            color: buttonColor,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyController.dispose();
    super.dispose();
  }
}