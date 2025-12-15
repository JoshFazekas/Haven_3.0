import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:haven/core/services/bluetooth_scan_service.dart';
import 'package:haven/core/services/ble_provisioning_service.dart';
import 'package:haven/core/services/auth_state.dart';
import 'package:lottie/lottie.dart';

/// Popup state for the provisioning flow
enum PopupState {
  initial,        // Show "Add to Location" button
  enterPassword,  // Show WiFi password input
  provisioning,   // Show loading animation
  completed,      // Show confirm animation and "Added!"
}

/// Secure storage for WiFi passwords
const _wifiPasswordsKey = 'cached_wifi_passwords';
const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

/// Apple AirPods-style bottom sheet popup for nearby Haven device detection
class NearbyDevicePopup extends StatefulWidget {
  final NearbyHavenDevice device;
  final VoidCallback onDismiss;
  final VoidCallback? onConnect;

  const NearbyDevicePopup({
    super.key,
    required this.device,
    required this.onDismiss,
    this.onConnect,
  });

  @override
  State<NearbyDevicePopup> createState() => _NearbyDevicePopupState();
}

class _NearbyDevicePopupState extends State<NearbyDevicePopup>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // Drag state
  double _dragOffset = 0;
  
  // Provisioning state
  PopupState _popupState = PopupState.initial;
  final BleProvisioningService _provisioningService = BleProvisioningService();
  StreamSubscription<ProvisioningState>? _provisioningSubscription;
  
  // WiFi state
  String? _wifiSsid;
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  // Confirm animation controller
  AnimationController? _confirmFadeController;
  Animation<double>? _confirmFadeAnimation;

  // Location ID to provision the device to
  static const int _targetLocationId = 27040;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Slide up from bottom with spring-like ease
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start from below screen
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Fade in the background
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // Subtle scale animation for the card
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Start the animation
    _controller.forward();
    
    // Haptic feedback when appearing
    HapticFeedback.mediumImpact();
    
    // Setup confirm fade animation
    _confirmFadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _confirmFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confirmFadeController!,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _confirmFadeController?.dispose();
    _provisioningSubscription?.cancel();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _animateOut() async {
    await _controller.reverse();
    widget.onDismiss();
  }
  
  /// Dismiss and remember this device so it won't show again
  Future<void> _dismissAndRemember() async {
    // Mark this device as dismissed in the bluetooth service
    BluetoothScanService().dismissDevice(widget.device.deviceId);
    await _animateOut();
  }

  /// Animate the sheet back to its original position
  void _snapBack() {
    final startOffset = _dragOffset;
    final snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    snapController.addListener(() {
      setState(() {
        _dragOffset = startOffset * (1 - snapController.value);
      });
    });
    
    snapController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        snapController.dispose();
      }
    });
    
    snapController.forward();
  }
  
  /// Start the provisioning process - first show password entry
  Future<void> _startProvisioning() async {
    // First, check if the phone is connected to WiFi
    final wifiSsid = await _provisioningService.getCurrentWifiSsid();
    
    if (wifiSsid == null || wifiSsid.isEmpty) {
      // Show error - not connected to WiFi
      if (mounted) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed - Connect phone to WiFi first'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    // Try to load cached password for this network
    final cachedPassword = await _getCachedPassword(wifiSsid);
    if (cachedPassword != null) {
      _passwordController.text = cachedPassword;
    }
    
    // Transition to password entry state
    setState(() {
      _wifiSsid = wifiSsid;
      _popupState = PopupState.enterPassword;
    });
    
    HapticFeedback.mediumImpact();
  }
  
  /// Get cached password for a WiFi network
  Future<String?> _getCachedPassword(String ssid) async {
    try {
      final stored = await _storage.read(key: _wifiPasswordsKey);
      if (stored != null) {
        final Map<String, dynamic> passwords = Map<String, dynamic>.from(
          Map.castFrom(jsonDecode(stored)),
        );
        return passwords[ssid] as String?;
      }
    } catch (e) {
      debugPrint('Error reading cached WiFi password: $e');
    }
    return null;
  }
  
  /// Save password for a WiFi network
  Future<void> _cachePassword(String ssid, String password) async {
    try {
      Map<String, dynamic> passwords = {};
      final stored = await _storage.read(key: _wifiPasswordsKey);
      if (stored != null) {
        passwords = Map<String, dynamic>.from(
          Map.castFrom(jsonDecode(stored)),
        );
      }
      passwords[ssid] = password;
      await _storage.write(key: _wifiPasswordsKey, value: jsonEncode(passwords));
    } catch (e) {
      debugPrint('Error caching WiFi password: $e');
    }
  }
  
  /// Submit password and start actual provisioning
  Future<void> _submitPasswordAndProvision() async {
    final wifiPassword = _passwordController.text;
    
    if (wifiPassword.isEmpty) {
      HapticFeedback.vibrate();
      return;
    }
    
    setState(() {
      _popupState = PopupState.provisioning;
    });
    
    HapticFeedback.mediumImpact();
    
    // Listen to provisioning state changes
    _provisioningSubscription = _provisioningService.stateStream.listen((state) {
      if (state == ProvisioningState.completed) {
        _onProvisioningComplete();
      } else if (state == ProvisioningState.failed) {
        _onProvisioningFailed();
      }
    });
    
    // Get bearer token from auth state
    final bearerToken = AuthState().token;
    
    if (bearerToken == null || bearerToken.isEmpty) {
      // Show error - not logged in
      if (mounted) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed - Please sign in again'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          _popupState = PopupState.initial;
        });
      }
      return;
    }
    
    // Start provisioning with the detected WiFi credentials
    final result = await _provisioningService.provisionDevice(
      device: widget.device,
      bearerToken: bearerToken,
      locationId: _targetLocationId,
      wifiSsid: _wifiSsid!,
      wifiPassword: _passwordController.text,
    );
    
    if (!result.success && mounted) {
      _onProvisioningFailed();
    }
  }
  
  void _onProvisioningComplete() {
    if (!mounted) return;
    
    // Cache the WiFi password for future use
    if (_wifiSsid != null && _passwordController.text.isNotEmpty) {
      _cachePassword(_wifiSsid!, _passwordController.text);
    }
    
    setState(() {
      _popupState = PopupState.completed;
    });
    
    // Fade in the confirm animation
    _confirmFadeController?.forward();
    
    HapticFeedback.heavyImpact();
    
    // Auto-dismiss after showing the confirmation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _animateOut();
      }
    });
  }
  
  void _onProvisioningFailed() {
    if (!mounted) return;
    
    setState(() {
      _popupState = PopupState.initial;
    });
    
    HapticFeedback.vibrate();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to add device. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate effective opacity based on drag
        final dragProgress = _dragOffset / 400; // 400 is rough sheet height
        final effectiveOpacity = (1 - dragProgress).clamp(0.0, 1.0);
        
        return Stack(
          children: [
            // Blurred/dimmed background
            GestureDetector(
              onTap: _popupState == PopupState.initial ? _animateOut : null,
              child: Container(
                color: Colors.black.withOpacity(0.6 * _fadeAnimation.value * effectiveOpacity),
              ),
            ),
            
            // Bottom sheet card
            Positioned(
              left: 0,
              right: 0,
              bottom: -_dragOffset,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  alignment: Alignment.bottomCenter,
                  child: _buildCard(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return GestureDetector(
      onTap: () {}, // Prevent dismissing when tapping the card
      onVerticalDragStart: _popupState == PopupState.initial ? (details) {
        // Drag started
      } : null,
      onVerticalDragUpdate: _popupState == PopupState.initial ? (details) {
        setState(() {
          // Only allow dragging down (positive delta)
          _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, double.infinity);
        });
      } : null,
      onVerticalDragEnd: _popupState == PopupState.initial ? (details) {
        final velocity = details.velocity.pixelsPerSecond.dy;
        
        // Dismiss if dragged more than 100px or fast swipe down
        if (_dragOffset > 100 || velocity > 300) {
          HapticFeedback.lightImpact();
          _animateOut();
        } else {
          // Snap back to original position
          _snapBack();
        }
      } : null,
      child: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E), // Apple dark gray
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Content based on state
                if (_popupState == PopupState.completed)
                  _buildCompletedContent()
                else
                  _buildNormalContent(bottomPadding),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNormalContent(double bottomPadding) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Device image
        Image.asset(
          'assets/images/xseries.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
        
        const SizedBox(height: 12),
        
        // Controller type
        Text(
          _getControllerType(widget.device.deviceName),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          'Haven Controller Nearby',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Button area - morphs between states
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _popupState == PopupState.enterPassword
                ? _buildPasswordEntry()
                : _popupState == PopupState.provisioning
                    ? _buildProvisioningButton()
                    : _buildAddButton(),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Dismiss button - Text only like Apple (hide during provisioning/password)
        if (_popupState == PopupState.initial)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _dismissAndRemember();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Not Now',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        
        // Cancel button for password entry
        if (_popupState == PopupState.enterPassword)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _popupState = PopupState.initial;
                    _passwordController.clear();
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        
        SizedBox(height: bottomPadding + 8),
      ],
    );
  }
  
  Widget _buildAddButton() {
    return SizedBox(
      key: const ValueKey('addButton'),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _startProvisioning,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Add to Location',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  Widget _buildPasswordEntry() {
    return Column(
      key: const ValueKey('passwordEntry'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Connected WiFi network info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // WiFi signal strength icon
              Icon(
                Icons.wifi,
                color: const Color(0xFF22C55E),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _wifiSsid ?? 'Unknown Network',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Password input field
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF22C55E).withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Center(
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofocus: false,
              cursorColor: const Color(0xFF22C55E),
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Enter WiFi password',
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              onSubmitted: (_) => _submitPasswordAndProvision(),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Connect button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _submitPasswordAndProvision,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Connect',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildProvisioningButton() {
    return SizedBox(
      key: const ValueKey('provisioning'),
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade700,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: Lottie.asset(
              'assets/animations/load.json',
              repeat: true,
              animate: true,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCompletedContent() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return FadeTransition(
      opacity: _confirmFadeAnimation!,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding + 8, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Confirm animation
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: Lottie.asset(
                  'assets/animations/confirm.json',
                  repeat: false,
                  animate: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // "Added!" text
            const Center(
              child: Text(
                'Added!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Get controller type from device name
  String _getControllerType(String deviceName) {
    final upperName = deviceName.toUpperCase();
    if (upperName.contains('MINI') || upperName.contains('X-MINI') || upperName.contains('XMINI')) {
      return 'X Mini';
    } else if (upperName.contains('POE') || upperName.contains('X-POE') || upperName.contains('XPOE')) {
      return 'X Poe';
    } else {
      return 'X Series';
    }
  }
}
