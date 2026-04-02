import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/app_theme.dart';

/// A combined sign-up / sign-in form that authenticates via Supabase.
/// Calls [onAuthSuccess] after a successful auth event.
class AuthFormWidget extends StatefulWidget {
  final void Function(BuildContext context) onAuthSuccess;

  const AuthFormWidget({Key? key, required this.onAuthSuccess})
      : super(key: key);

  @override
  State<AuthFormWidget> createState() => _AuthFormWidgetState();
}

class _AuthFormWidgetState extends State<AuthFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _awaitingConfirmation = false;
  bool _resetEmailSent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final emailOk = _emailController.text.trim().isNotEmpty &&
        _emailController.text.contains('@');
    final passwordOk = _passwordController.text.length >= 6;
    final nameOk = !_isSignUp || _nameController.text.trim().length >= 2;
    return emailOk && passwordOk && nameOk;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      if (_isSignUp) {
        final name = _nameController.text.trim();
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': name},
        );
        if (!mounted) return;
        // session == null means Supabase requires email confirmation
        if (response.session == null) {
          setState(() => _awaitingConfirmation = true);
          return;
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }

      if (mounted) widget.onAuthSuccess(context);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Something went wrong. Please try again.'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter your email address above first.'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) setState(() => _resetEmailSent = true);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_awaitingConfirmation) return _buildConfirmationMessage();
    if (_resetEmailSent) return _buildResetSentMessage();
    return _buildForm();
  }

  Widget _buildConfirmationMessage() {
    return Column(
      children: [
        Container(
          width: 18.w,
          height: 18.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_unread_outlined,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 9.w,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Check your inbox',
          style: AppTheme.lightTheme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          'We sent a confirmation link to\n${_emailController.text.trim()}',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          'Click the link in the email to activate your account, then come back and sign in.',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 3.h),
        TextButton(
          onPressed: () => setState(() {
            _awaitingConfirmation = false;
            _isSignUp = false;
          }),
          child: Text(
            'I confirmed my email — Sign in',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetSentMessage() {
    return Column(
      children: [
        Container(
          width: 18.w,
          height: 18.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_reset,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 9.w,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Reset link sent',
          style: AppTheme.lightTheme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          'Check ${_emailController.text.trim()} for a password reset link.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 3.h),
        TextButton(
          onPressed: () => setState(() => _resetEmailSent = false),
          child: Text(
            'Back to Sign In',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      onChanged: () => setState(() {}),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModeToggle(),
          SizedBox(height: 3.h),
          if (_isSignUp) ...[
            _buildNameField(),
            SizedBox(height: 2.h),
          ],
          _buildEmailField(),
          SizedBox(height: 2.h),
          _buildPasswordField(),
          if (!_isSignUp) ...[
            SizedBox(height: 1.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isSubmitting ? null : _sendPasswordReset,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: 3.h),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Row(
      children: [
        Expanded(
          child: _ModeTab(
            label: 'Create Account',
            selected: _isSignUp,
            onTap: () => setState(() => _isSignUp = true),
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _ModeTab(
            label: 'Sign In',
            selected: !_isSignUp,
            onTap: () => setState(() => _isSignUp = false),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Full Name',
        hintText: 'Your name',
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (v) {
        if (_isSignUp && (v == null || v.trim().length < 2)) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'you@example.com',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: (v) {
        if (v == null || !v.contains('@')) return 'Enter a valid email';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: _isSignUp ? 'At least 6 characters' : 'Your password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isFormValid && !_isSubmitting ? _submit : null,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _isSignUp ? 'Create Account' : 'Sign In',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            color: selected
                ? AppTheme.lightTheme.colorScheme.onPrimary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
