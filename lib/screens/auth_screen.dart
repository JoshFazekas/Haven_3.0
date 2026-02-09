import 'package:flutter/material.dart';
import 'package:haven/core/services/auth_service.dart';
import 'package:haven/core/services/auth_state.dart';
import 'package:haven/core/services/location_data_service.dart';
import 'package:haven/screens/lights_screen.dart';
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
  bool _isForgotPassword = false;
  bool _isSignUp = false;

  // Forgot password animation
  late AnimationController _forgotPasswordController;

  // Sign up animation
  late AnimationController _signUpController;

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

    // Forgot password animation controller
    _forgotPasswordController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Sign up animation controller
    _signUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
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
    _forgotPasswordController.dispose();
    _signUpController.dispose();
    _imageTimer?.cancel();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    ErrorMessages.show(
      context,
      message: message,
    );
  }

  void _toggleForgotPassword() {
    setState(() {
      _isForgotPassword = !_isForgotPassword;
    });
    if (_isForgotPassword) {
      _forgotPasswordController.forward();
    } else {
      _forgotPasswordController.reverse();
    }
  }

  void _toggleSignUp() {
    setState(() {
      _isSignUp = !_isSignUp;
    });
    if (_isSignUp) {
      _signUpController.forward();
    } else {
      _signUpController.reverse();
    }
  }

  Future<void> _sendSignUpEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ErrorMessages.showById(context, errorId: 1);
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ErrorMessages.showById(context, errorId: 3);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual sign up API call
      // await _authService.sendSignUpEmail(email);
      
      await Future.delayed(const Duration(seconds: 1)); // Simulated delay
      
      if (mounted) {
        ErrorMessages.show(context, message: 'Account creation link sent to $email');
        _toggleSignUp();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to send sign up email. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendForgotPasswordEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ErrorMessages.showById(context, errorId: 1);
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ErrorMessages.showById(context, errorId: 3);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual forgot password API call
      // await _authService.sendForgotPasswordEmail(email);
      
      await Future.delayed(const Duration(seconds: 1)); // Simulated delay
      
      if (mounted) {
        ErrorMessages.show(context, message: 'Password reset link sent to $email');
        _toggleForgotPassword();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to send reset email. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      final username = result['username'] as String?;
      final userType = result['userType'] as int?;

      // Step 1: Store auth credentials
      await AuthState().login(
        token: token,
        refreshToken: refreshToken,
        userId: userId,
        username: username,
        userType: userType,
        email: email,
        password: password,
      );

      // Step 2: Fetch user info from /api/User/Info
      try {
        final userInfoResponse = await _authService.getUserInfo(
          bearerToken: token,
          email: email,
        );

        final userData = userInfoResponse['data'] as Map<String, dynamic>;
        final fullName = userData['fullName'] as String? ?? '';
        final phoneNumber = userData['phoneNumber'] as String? ?? '';
        final defaultLocationId = userData['defaultLocationId'] as int? ?? 0;
        final userEmail = userData['email'] as String? ?? email;
        final infoUserId = userData['userId'] as int? ?? userId;

        // Store user info
        await AuthState().saveUserInfo(
          fullName: fullName,
          phoneNumber: phoneNumber,
          defaultLocationId: defaultLocationId,
          email: userEmail,
          userId: infoUserId,
        );

        // Step 3: Fetch location lights/zones using the default location ID
        if (defaultLocationId > 0) {
          try {
            final locationData = await _authService.getLocationLightsZones(
              bearerToken: token,
              locationId: defaultLocationId,
            );
            // Store raw response in AuthState for backwards compatibility
            AuthState().saveLocationLightsZones(locationData);
            // Parse and store in LocationDataService for typed access
            await LocationDataService().loadFromApiResponse(locationData);
          } catch (e) {
            debugPrint('Failed to fetch location lights/zones: $e');
            // Non-fatal: continue to home screen
          }
        }
      } catch (e) {
        debugPrint('Failed to fetch user info: $e');
        // Non-fatal: continue to home screen with basic auth data
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LightsScreen()),
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
                              // Animated welcome text
                              AnimatedBuilder(
                                animation: Listenable.merge([_forgotPasswordController, _signUpController]),
                                builder: (context, child) {
                                  String text = 'Welcome back';
                                  if (_isForgotPassword) {
                                    text = 'Send password reset link';
                                  } else if (_isSignUp) {
                                    text = 'Create Account';
                                  }
                                  return Text(
                                    text,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: Colors.white.withOpacity(0.95),
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: 1.5,
                                        ),
                                    textAlign: TextAlign.center,
                                  );
                                },
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
                            
                            // Password field with fade animation (hidden for forgot password and sign up)
                            AnimatedBuilder(
                              animation: Listenable.merge([_forgotPasswordController, _signUpController]),
                              builder: (context, child) {
                                // Use the max of both animations to hide password field
                                final fadeValue = 1.0 - (_forgotPasswordController.value > _signUpController.value 
                                    ? _forgotPasswordController.value 
                                    : _signUpController.value);
                                return FadeTransition(
                                  opacity: AlwaysStoppedAnimation(fadeValue),
                                  child: SizeTransition(
                                    sizeFactor: AlwaysStoppedAnimation(fadeValue),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 20),
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
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            
                            // Forgot password button (hidden for forgot password and sign up modes)
                            AnimatedBuilder(
                              animation: Listenable.merge([_forgotPasswordController, _signUpController]),
                              builder: (context, child) {
                                final fadeValue = 1.0 - (_forgotPasswordController.value > _signUpController.value 
                                    ? _forgotPasswordController.value 
                                    : _signUpController.value);
                                return FadeTransition(
                                  opacity: AlwaysStoppedAnimation(fadeValue),
                                  child: SizeTransition(
                                    sizeFactor: AlwaysStoppedAnimation(fadeValue),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _toggleForgotPassword,
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
                                  ),
                                );
                              },
                            ),
                            
                            // Back to Sign In button (shown only for forgot password mode)
                            AnimatedBuilder(
                              animation: _forgotPasswordController,
                              builder: (context, child) {
                                return FadeTransition(
                                  opacity: AlwaysStoppedAnimation(_forgotPasswordController.value),
                                  child: SizeTransition(
                                    sizeFactor: AlwaysStoppedAnimation(_forgotPasswordController.value),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _toggleForgotPassword,
                                        child: Text(
                                          'Back to Sign In',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.85),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            // Main action button with gradient
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
                                onPressed: _isLoading 
                                    ? null 
                                    : (_isForgotPassword 
                                        ? _sendForgotPasswordEmail 
                                        : (_isSignUp ? _sendSignUpEmail : _signIn)),
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
                                    : AnimatedBuilder(
                                        animation: Listenable.merge([_forgotPasswordController, _signUpController]),
                                        builder: (context, child) {
                                          String buttonText = 'Sign In';
                                          if (_isForgotPassword) {
                                            buttonText = 'Send Email';
                                          } else if (_isSignUp) {
                                            buttonText = 'Create Account';
                                          }
                                          return Text(
                                            buttonText,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 1,
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // "Don't have an account? Sign Up" (hidden during forgot password and sign up)
                            AnimatedBuilder(
                              animation: Listenable.merge([_forgotPasswordController, _signUpController]),
                              builder: (context, child) {
                                final fadeValue = 1.0 - (_forgotPasswordController.value > _signUpController.value 
                                    ? _forgotPasswordController.value 
                                    : _signUpController.value);
                                return FadeTransition(
                                  opacity: AlwaysStoppedAnimation(fadeValue),
                                  child: SizeTransition(
                                    sizeFactor: AlwaysStoppedAnimation(fadeValue),
                                    child: child,
                                  ),
                                );
                              },
                              child: Row(
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
                                  onPressed: _toggleSignUp,
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
                            ),
                            
                            // "Already have an account? Sign In" (shown only during sign up)
                            AnimatedBuilder(
                              animation: _signUpController,
                              builder: (context, child) {
                                return FadeTransition(
                                  opacity: AlwaysStoppedAnimation(_signUpController.value),
                                  child: SizeTransition(
                                    sizeFactor: AlwaysStoppedAnimation(_signUpController.value),
                                    child: child,
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                Text(
                                  "Already have an account? ",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 15,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _toggleSignUp,
                                  child: const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: Color(0xFFF57F20),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              ),
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
