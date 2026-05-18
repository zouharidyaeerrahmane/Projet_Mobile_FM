import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _obscure    = true;
  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync   : this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier)
        .login(_emailCtrl.text, _passCtrl.text);
    if (!ok || !mounted) return;

    final role = ref.read(authProvider).user?.role;
    switch (role) {
      case 'student'    : context.go('/etudiant');    break;
      case 'technician' : context.go('/technicien');  break;
      case 'agent'      :
      case 'admin'      : context.go('/direction');   break;
      case 'security'   : context.go('/securite');    break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A2E6E), Color(0xFF0D47A1), Color(0xFF1565C0)],
            begin : Alignment.topLeft,
            end   : Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      // Logo
                      Container(
                        width : 80, height: 80,
                        decoration: BoxDecoration(
                          color        : Colors.white.withValues(alpha:0.15),
                          shape        : BoxShape.circle,
                          border       : Border.all(color: Colors.white.withValues(alpha:0.3), width: 2),
                        ),
                        child: const Icon(Icons.apartment_rounded,
                          color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 20),
                      const Text('UniClaim',
                        style: TextStyle(
                          color     : Colors.white,
                          fontSize  : 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        )),
                      const SizedBox(height: 6),
                      Text('Gestion des réclamations',
                        style: TextStyle(
                          color  : Colors.white.withValues(alpha:0.7),
                          fontSize: 14,
                        )),
                      const SizedBox(height: 40),

                      // Card formulaire
                      Container(
                        decoration: BoxDecoration(
                          color        : Colors.white,
                          borderRadius : BorderRadius.circular(24),
                          boxShadow    : [
                            BoxShadow(
                              color  : Colors.black.withValues(alpha:0.2),
                              blurRadius: 30,
                              offset : const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Connexion',
                                style: TextStyle(
                                  fontSize  : 22,
                                  fontWeight: FontWeight.w800,
                                  color     : AppColors.textPrimary,
                                )),
                              const SizedBox(height: 4),
                              const Text('Entrez vos identifiants pour continuer',
                                style: TextStyle(
                                  fontSize: 13,
                                  color   : AppColors.textSecondary,
                                )),
                              const SizedBox(height: 28),

                              // Email
                              TextFormField(
                                controller  : _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration  : const InputDecoration(
                                  labelText  : 'Adresse email',
                                  prefixIcon : Icon(Icons.email_outlined),
                                ),
                                validator: (v) =>
                                  v == null || !v.contains('@')
                                    ? 'Email invalide' : null,
                              ),
                              const SizedBox(height: 16),

                              // Mot de passe
                              TextFormField(
                                controller : _passCtrl,
                                obscureText: _obscure,
                                decoration : InputDecoration(
                                  labelText : 'Mot de passe',
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                    onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) =>
                                  v == null || v.length < 4
                                    ? 'Mot de passe requis' : null,
                                onFieldSubmitted: (_) => _login(),
                              ),

                              // Erreur
                              if (auth.error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color        : AppColors.error.withValues(alpha:0.08),
                                    borderRadius : BorderRadius.circular(10),
                                    border       : Border.all(
                                      color: AppColors.error.withValues(alpha:0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                        color: AppColors.error, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(auth.error!,
                                          style: const TextStyle(
                                            color  : AppColors.error,
                                            fontSize: 13,
                                          )),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),

                              // Bouton connexion
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: auth.loading ? null : _login,
                                  child    : auth.loading
                                    ? const SizedBox(
                                        width : 22, height: 22,
                                        child : CircularProgressIndicator(
                                          color      : Colors.white,
                                          strokeWidth: 2.5,
                                        ))
                                    : const Text('Se connecter',
                                        style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text('UniClaim v1.0 — Projet Académique',
                        style: TextStyle(
                          color  : Colors.white.withValues(alpha:0.4),
                          fontSize: 11,
                        )),
                    ],
                  ),
                ),
              ),
          ),
        ),
      ),
    );
  }
}
