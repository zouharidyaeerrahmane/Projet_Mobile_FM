import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});
  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  List<UserModel> _users   = [];
  bool            _loading = true;
  String          _roleFilter = 'all';

  final _roleFilters = [
    {'key': 'all',        'label': 'Tous'},
    {'key': 'student',    'label': 'Étudiants'},
    {'key': 'technician', 'label': 'Techniciens'},
    {'key': 'agent',      'label': 'Agents'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final params = _roleFilter != 'all' ? {'role': _roleFilter} : null;
      final res = await ApiService().get('/users', params: params);
      setState(() {
        _users   = (res.data as List).map((e) => UserModel.fromJson(e)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showCreateDialog() {
    final fullNameCtrl = TextEditingController();
    final emailCtrl    = TextEditingController();
    final passCtrl     = TextEditingController();
    String role        = 'student';
    final formKey      = GlobalKey<FormState>();

    showModalBottomSheet(
      context            : context,
      isScrollControlled : true,
      backgroundColor    : Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color       : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Créer un compte',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),

                TextFormField(
                  controller: fullNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person_outline_rounded)),
                  validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requis' : null,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) =>
                    v == null || !v.contains('@') ? 'Email invalide' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock_outlined)),
                  validator: (v) =>
                    v == null || v.length < 6 ? 'Min. 6 caractères' : null,
                ),
                const SizedBox(height: 12),

                // Rôle
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(
                    labelText : 'Rôle',
                    prefixIcon: Icon(Icons.badge_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'student',    child: Text('Étudiant')),
                    DropdownMenuItem(value: 'technician', child: Text('Technicien')),
                    DropdownMenuItem(value: 'agent',      child: Text('Agent de direction')),
                    DropdownMenuItem(value: 'admin',      child: Text('Administrateur')),
                  ],
                  onChanged: (v) => setModal(() => role = v!),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ApiService().post('/users', {
                        'fullName': fullNameCtrl.text.trim(),
                        'email'   : emailCtrl.text.trim(),
                        'password': passCtrl.text,
                        'role'    : role,
                      });
                      navigator.pop();
                      _load();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Compte créé avec succès'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Erreur : $e'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Créer le compte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des comptes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Déconnexion'),
                ])),
            ],
            onSelected: (v) async {
              if (v == 'logout') {
                await ref.read(authProvider.notifier).logout();
                if (!context.mounted) return;
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres rôle
          Container(
            height : 56,
            color  : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child  : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount      : _roleFilters.length,
              itemBuilder    : (_, i) {
                final f   = _roleFilters[i];
                final sel = _roleFilter == f['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child  : FilterChip(
                    label    : Text(f['label']!),
                    selected : sel,
                    onSelected: (_) {
                      setState(() => _roleFilter = f['key']!);
                      _load();
                    },
                    selectedColor : AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color     : sel ? Colors.white : AppColors.textSecondary,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      fontSize  : 12,
                    ),
                    backgroundColor: const Color(0xFFF0F4F8),
                    side           : BorderSide.none,
                    visualDensity  : VisualDensity.compact,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EDF2)),

          Expanded(
            child: _loading
              ? const LoadingList()
              : _users.isEmpty
                ? const EmptyState(
                    icon    : Icons.people_outline_rounded,
                    title   : 'Aucun utilisateur',
                    subtitle: 'Aucun compte dans cette catégorie.',
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child    : ListView.builder(
                      padding    : const EdgeInsets.all(16),
                      itemCount  : _users.length,
                      itemBuilder: (_, i) => _UserCard(user: _users[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed      : _showCreateDialog,
        icon           : const Icon(Icons.person_add_rounded),
        label          : const Text('Nouveau compte'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  const _UserCard({required this.user});

  Color get _roleColor {
    switch (user.role) {
      case 'admin'      : return AppColors.error;
      case 'agent'      : return AppColors.statusProgress;
      case 'technician' : return AppColors.accent;
      default           : return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child  : Row(
          children: [
            UserAvatar(user: user, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName,
                    style: const TextStyle(
                      fontSize  : 14,
                      fontWeight: FontWeight.w700,
                      color     : AppColors.textPrimary,
                    )),
                  const SizedBox(height: 2),
                  Text(user.email,
                    style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color       : _roleColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(user.roleLabel,
                style: TextStyle(
                  fontSize  : 11,
                  fontWeight: FontWeight.w700,
                  color     : _roleColor,
                )),
            ),
          ],
        ),
      ),
    );
  }
}
