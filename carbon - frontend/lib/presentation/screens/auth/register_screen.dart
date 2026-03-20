import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../data/models/auth_state.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _incomeController = TextEditingController();
  String _selectedZone = 'North';
  String _selectedVehicle = 'bike';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final List<String> _zones = ['North', 'South', 'East', 'West', 'Central'];
  final List<String> _vehicles = ['bike', 'scooter', 'bicycle'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          phone: '+91${_phoneController.text.trim()}',
          password: _passwordController.text,
          zone: _selectedZone,
          vehicleType: _selectedVehicle,
          projectedWeeklyIncome: _incomeController.text.isNotEmpty
              ? double.tryParse(_incomeController.text.trim())
              : null,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    } else if (authState.status == AuthStatus.error) {
      _showError(authState.errorMessage ?? 'Registration failed');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: cs.onSurfaceVariant),
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurfaceVariant),
      prefixIcon: Icon(icon, color: cs.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // Logo
                  Container(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shield, size: 64, color: cs.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Create Account',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Get protected while you deliver',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(color: cs.onSurface),
                    decoration: _inputDecoration(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      icon: Icons.person_outline,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Name is required';
                      if (v.trim().length < 2) return 'Name must be at least 2 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: cs.onSurface),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: _inputDecoration(
                      label: 'Phone Number',
                      hint: '10-digit mobile number',
                      icon: Icons.phone,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Phone number is required';
                      if (v.length != 10) return 'Enter a valid 10-digit number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: cs.onSurface),
                    decoration: _inputDecoration(
                      label: 'Password',
                      hint: 'Minimum 6 characters',
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: cs.onSurfaceVariant,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    style: TextStyle(color: cs.onSurface),
                    decoration: _inputDecoration(
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                          color: cs.onSurfaceVariant,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please confirm your password';
                      if (v != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Zone Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedZone,
                    dropdownColor: cs.surfaceContainer,
                    style: TextStyle(color: cs.onSurface),
                    decoration: _inputDecoration(
                      label: 'Delivery Zone',
                      hint: 'Select your zone',
                      icon: Icons.location_on,
                    ),
                    items: _zones
                        .map((z) => DropdownMenuItem(
                              value: z,
                              child: Text(z, style: TextStyle(color: cs.onSurface)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedZone = v!),
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedVehicle,
                    dropdownColor: cs.surfaceContainer,
                    style: TextStyle(color: cs.onSurface),
                    decoration: _inputDecoration(
                      label: 'Vehicle Type',
                      hint: 'Select your vehicle',
                      icon: Icons.two_wheeler,
                    ),
                    items: _vehicles
                        .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(
                                v[0].toUpperCase() + v.substring(1),
                                style: TextStyle(color: cs.onSurface),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedVehicle = v!),
                  ),
                  const SizedBox(height: 16),

                  // Projected Weekly Income
                  TextFormField(
                    controller: _incomeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: cs.onSurface),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: _inputDecoration(
                      label: 'Weekly Income (₹)',
                      hint: 'e.g. 5000 (optional)',
                      icon: Icons.currency_rupee,
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final val = double.tryParse(v);
                        if (val == null || val <= 0) return 'Enter a valid income amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Register button
                  FilledButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushReplacementNamed(AppRouter.login),
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
