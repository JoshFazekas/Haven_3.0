import 'package:flutter/material.dart';
import 'package:haven/screens/otp_verification_screen.dart';
import 'package:haven/screens/welcome_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSignUpMode = false;

  late AnimationController _logoFadeController;
  late Animation<double> _logoFadeAnimation;

  late AnimationController _signUpFieldsController;
  late Animation<double> _signUpFieldsAnimation;

  @override
  void initState() {
    super.initState();
    _logoFadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _logoFadeAnimation = CurvedAnimation(
      parent: _logoFadeController,
      curve: Curves.easeIn,
    );
    // Start the fade animation
    _logoFadeController.forward();

    _signUpFieldsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _signUpFieldsAnimation = CurvedAnimation(
      parent: _signUpFieldsController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _logoFadeController.dispose();
    _signUpFieldsController.dispose();
    super.dispose();
  }

  void _toggleSignUpMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
    });
    if (_isSignUpMode) {
      _signUpFieldsController.forward();
    } else {
      _signUpFieldsController.reverse();
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_isSignUpMode) {
        // Sign up logic
        debugPrint('First Name: ${_firstNameController.text}');
        debugPrint('Last Name: ${_lastNameController.text}');
        debugPrint('Email: ${_emailController.text}');
        debugPrint('Phone: ${_phoneController.text}');
      } else {
        // Sign in logic
        debugPrint('Sending OTP to: ${_emailController.text}');
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              OtpVerificationScreen(email: _emailController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo with fade in animation
                  FadeTransition(
                    opacity: _logoFadeAnimation,
                    child: Image.asset(
                      'assets/images/havenlogo.png',
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _isSignUpMode ? 'Create your account' : 'Welcome back',
                      key: ValueKey<bool>(_isSignUpMode),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  // Animated Sign Up Fields
                  SizeTransition(
                    sizeFactor: _signUpFieldsAnimation,
                    axisAlignment: -1.0,
                    child: FadeTransition(
                      opacity: _signUpFieldsAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          // First Name Field
                          TextFormField(
                            controller: _firstNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'First Name',
                              hintText: 'Enter your first name',
                              prefixIcon: const Icon(Icons.person_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: _isSignUpMode
                                ? (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your first name';
                                    }
                                    return null;
                                  }
                                : null,
                          ),
                          const SizedBox(height: 16),
                          // Last Name Field
                          TextFormField(
                            controller: _lastNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Last Name',
                              hintText: 'Enter your last name',
                              prefixIcon: const Icon(Icons.person_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: _isSignUpMode
                                ? (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your last name';
                                    }
                                    return null;
                                  }
                                : null,
                          ),
                          const SizedBox(height: 16),
                          // Phone Number Field (Optional)
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number (Optional)',
                              hintText: 'Enter your phone number',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign In / Sign Up Button
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF57F20).withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(
                          color: Color(0xFFF57F20),
                          width: 2,
                        ),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _isSignUpMode ? 'Sign Up' : 'Sign In',
                        key: ValueKey<bool>(_isSignUpMode),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle Sign Up / Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _isSignUpMode
                              ? 'Already have an account? '
                              : "Don't have an account? ",
                          key: ValueKey<bool>(_isSignUpMode),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      TextButton(
                        onPressed: _toggleSignUpMode,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _isSignUpMode ? 'Sign In' : 'Sign Up',
                            key: ValueKey<bool>(_isSignUpMode),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Temporary skip button
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const WelcomeScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Skip to Welcome Screen',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
