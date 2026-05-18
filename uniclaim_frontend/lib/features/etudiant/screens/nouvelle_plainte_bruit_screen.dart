import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_theme.dart';

class NouvellePlainteBruitScreen extends ConsumerStatefulWidget {
  const NouvellePlainteBruitScreen({super.key});
  @override
  ConsumerState<NouvellePlainteBruitScreen> createState() => _State();
}

class _State extends ConsumerState<NouvellePlainteBruitScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _neighborCtrl = TextEditingController();
  final _floorCtrl    = TextEditingController();
  final _blockCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _neighborCtrl.dispose();
    _floorCtrl.dispose();
    _blockCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService().post('/noise-reports', {
        'neighborRoom': _neighborCtrl.text.trim(),
        'floor'       : _floorCtrl.text.trim().isEmpty ? null : _floorCtrl.text.trim(),
        'block'       : _blockCtrl.text.trim().isEmpty ? null : _blockCtrl.text.trim(),
        'description' : _descCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Signalement envoyé à l\'agent de sécurité !'),
            ]),
            backgroundColor: AppColors.success,
            behavior       : SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content        : Text('Erreur : $e'),
            backgroundColor: AppColors.error,
            behavior       : SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;

    return Scaffold(
      appBar: AppBar(title: const Text('Signaler du bruit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chambre du plaignant — automatique
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color       : AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border      : Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.meeting_room_rounded,
                      color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Votre chambre (automatique)',
                            style: TextStyle(
                              fontSize  : 11,
                              fontWeight: FontWeight.w600,
                              color     : AppColors.primary,
                              letterSpacing: 0.3,
                            )),
                          const SizedBox(height: 2),
                          Text(
                            user.roomNumber ?? '—',
                            style: const TextStyle(
                              fontSize  : 16,
                              fontWeight: FontWeight.w800,
                              color     : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.lock_outline_rounded,
                      size: 16, color: AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info sécurité
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color       : AppColors.security.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border      : Border.all(color: AppColors.security.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security_rounded, color: AppColors.security, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Votre signalement sera transmis directement à l\'agent de sécurité.',
                        style: TextStyle(
                          fontSize: 12,
                          color   : AppColors.security,
                          height  : 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _label('Chambre du voisin concerné *'),
              const SizedBox(height: 8),
              TextFormField(
                controller  : _neighborCtrl,
                decoration  : const InputDecoration(
                  hintText  : 'Ex : 205 ou 304 (au-dessus)',
                  prefixIcon: Icon(Icons.door_front_door_outlined),
                ),
                validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Chambre du voisin requise' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Étage (optionnel)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _floorCtrl,
                          decoration: const InputDecoration(
                            hintText  : 'Ex : 2ème',
                            prefixIcon: Icon(Icons.layers_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Bloc (optionnel)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _blockCtrl,
                          decoration: const InputDecoration(
                            hintText  : 'Ex : Bloc A',
                            prefixIcon: Icon(Icons.apartment_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _label('Description des nuisances *'),
              const SizedBox(height: 8),
              TextFormField(
                controller : _descCtrl,
                maxLines   : 5,
                decoration : const InputDecoration(
                  hintText  : 'Type de bruit, horaires, fréquence...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 64),
                    child  : Icon(Icons.volume_up_outlined),
                  ),
                ),
                validator: (v) =>
                  v == null || v.trim().length < 10
                    ? 'Description trop courte (min. 10 caractères)' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon : _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.send_rounded),
                  label: Text(_loading ? 'Envoi en cours...' : 'Envoyer le signalement'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
    style: const TextStyle(
      fontSize     : 13,
      fontWeight   : FontWeight.w700,
      color        : AppColors.textSecondary,
      letterSpacing: 0.3,
    ));
}
