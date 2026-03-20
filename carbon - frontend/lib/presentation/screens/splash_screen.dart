import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/routing/app_router.dart';
import '../../data/models/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _statusMessage = 'Initializing...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    
    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check backend connectivity
      setState(() => _statusMessage = 'Connecting to server...');
      await _checkBackendConnection();
      
      // Small delay for smooth UX
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() => _statusMessage = 'Loading...');
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateBasedOnAuthState();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = 'Connection failed';
        });
      }
    }
  }

  Future<void> _checkBackendConnection() async {
    try {
      final apiClient = ApiClient();
      final healthUrl = await ApiConfig.health;
      await apiClient.get(healthUrl).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Connection timeout'),
      );
    } catch (e) {
      throw Exception('Backend unreachable: $e');
    }
  }

  void _navigateBasedOnAuthState() {
    final authState = ref.read(authProvider);
    
    String route;
    if (authState.status == AuthStatus.authenticated) {
      route = AppRouter.home;
    } else {
      route = AppRouter.login;
    }
    
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shield,
                    size: 60,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'CARBON',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Parametric Insurance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 48),
                
                if (!_hasError)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.error_outline,
                    size: 40,
                    color: colorScheme.error,
                  ),
                const SizedBox(height: 16),
                
                Text(
                  _statusMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _hasError ? colorScheme.error : colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                
                if (_hasError) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _statusMessage = 'Retrying...';
                      });
                      _initializeApp();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(AppRouter.login);
                    },
                    child: const Text('Continue Offline'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
