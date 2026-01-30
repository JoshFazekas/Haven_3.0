import 'package:flutter/material.dart';
import 'package:haven/core/services/auth_service.dart';
import 'package:haven/core/services/auth_state.dart';
import 'package:haven/screens/welcome_screen.dart';
import 'package:haven/widgets/glass_input_field.dart';
import 'package:haven/core/config/error_messages.dart';
import 'dart:async';
import 'dart:ui';

class SignInScreen extends StatefulWidget {
  final String? initialEmail;

  const SignInScreen({super.key, this.initialEmail});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Ken Burns Effect
  late AnimationController _kenBurnsController1;
  late AnimationController _kenBurnsController2;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation1;
  late Animation<double> _scaleAnimation2;
  late Animation<double> _fadeAnimation;
  
  int _currentImageIndex = 0;
  int _nextImageIndex = 1;
  bool _showingFirst = true;
  Timer? _imageTimer;
  
  final List<String> _backgroundImages = [
    'assets/images/image1.jpg',
    'assets/images/image2.jpg',
    'assets/images/image3.jpg',
    'assets/images/image4.jpg',
    'assets/images/image5.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadLastEmail();
    _initializeAnimations();
    _startImageCycle();
  }

  void _initializeAnimations() {
    // Ken Burns controllers for both layers
    _kenBurnsController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    
    _kenBurnsController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    // Crossfade controller - 2 seconds for smooth transition
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Scale animations for Ken Burns zoom
    _scaleAnimation1 = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _kenBurnsController1,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation2 = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _kenBurnsController2,
      curve: Curves.easeInOut,
    ));

    // Fade animation for crossfade (0 = show first, 1 = show second)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start first image animation
    _kenBurnsController1.forward();
  }

  void _startImageCycle() {
    _imageTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _transitionToNextImage();
      }
    });
  }

  void _transitionToNextImage() {
    if (_showingFirst) {
      // Prepare next image on layer 2
      _nextImageIndex = (_currentImageIndex + 1) % _backgroundImages.length;
      _kenBurnsController2.reset();
      _kenBurnsController2.forward();
      
      // Crossfade from layer 1 to layer 2
      _fadeController.forward().then((_) {
        if (mounted) {
          setState(() {
            _showingFirst = false;
            _currentImageIndex = _nextImageIndex;
          });
        }
      });
    } else {
      // Prepare next image on layer 1
      _nextImageIndex = (_currentImageIndex + 1) % _backgroundImages.length;
      _kenBurnsController1.reset();
      _kenBurnsController1.forward();
      
      // Crossfade from layer 2 to layer 1
      _fadeController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _showingFirst = true;
            _currentImageIndex = _nextImageIndex;
          });
        }
      });
    }
  }

  Future<void> _loadLastEmail() async {
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    } else {
      final lastEmail = await AuthState().getLastEmail();
      if (lastEmail != null && mounted) {
        setState(() {
          _emailController.text = lastEmail;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _kenBurnsController1.dispose();
    _kenBurnsController2.dispose();
    _fadeController.dispose();
    _imageTimer?.cancel();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    ErrorMessages.show(
      context,
      message: message,
    );
  }

  Future<void> _signIn() async {
    // Manual validation with glass error messages using error IDs
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Check if both are empty - Error ID 4
    if (email.isEmpty && password.isEmpty) {
      ErrorMessages.showById(context, errorId: 4);
      return;
    }

    // Check email - Error ID 1
    if (email.isEmpty) {
      ErrorMessages.showById(context, errorId: 1);
      return;
    }

    // Check email format - Error ID 3
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ErrorMessages.showById(context, errorId: 3);
      return;
    }

    // Check password - Error ID 2
    if (password.isEmpty) {
      ErrorMessages.showById(context, errorId: 2);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.authenticate(
        email,
        password,
      );

      final token = result['token'] as String;
      final refreshToken = result['refreshToken'] as String;
      final userId = result['id'] as int;

      await AuthState().login(
        token: token,
        refreshToken: refreshToken,
        userId: userId,
        email: email,
        password: password,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        // Error ID 5 for incorrect credentials
        ErrorMessages.showById(context, errorId: 5);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Layer 1 - First image with Ken Burns
          AnimatedBuilder(
            animation: Listenable.merge([_kenBurnsController1, _fadeController]),
            builder: (context, child) {
              final imageIndex = _showingFirst ? _currentImageIndex : _nextImageIndex;
              return Opacity(
                opacity: 1.0 - _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation1.value,
                  alignment: Alignment.center,
                  child: Image.asset(
                    _backgroundImages[imageIndex],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    gaplessPlayback: true,
                  ),
                ),
              );
            },
          ),
          
          // Background Layer 2 - Second image with Ken Burns (crossfades on top)
          AnimatedBuilder(
            animation: Listenable.merge([_kenBurnsController2, _fadeController]),
            builder: (context, child) {
              final imageIndex = _showingFirst ? _nextImageIndex : _currentImageIndex;
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation2.value,
                  alignment: Alignment.center,
                  child: Image.asset(
                    _backgroundImages[imageIndex],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    gaplessPlayback: true,
                  ),
                ),
              );
            },
          ),
          
          // Content - Liquid Glass Container
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 40.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            width: 2,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logo
                              Image.asset(
                                'assets/images/havenlogo.png',
                                height: 80,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Welcome back',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white.withOpacity(0.95),
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 1.5,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                            
                            // Email field
                            GlassInputField(
                              controller: _emailController,
                              labelText: 'Email',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textCapitalization: TextCapitalization.none,
                              autocorrect: false,
                              onChanged: (value) {
                                final lowercased = value.toLowerCase();
                                if (value != lowercased) {
                                  _emailController.value = TextEditingValue(
                                    text: lowercased,
                                    selection: TextSelection.collapsed(
                                      offset: lowercased.length,
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // Password field
                            GlassInputField(
                              controller: _passwordController,
                              labelText: 'Password',
                              prefixIcon: Icons.lock_outlined,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Forgot password button
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Sign in button with gradient
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFF57F20),
                                    const Color(0xFFF57F20).withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF57F20).withOpacity(0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Sign up link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 15,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: Color(0xFFF57F20),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
