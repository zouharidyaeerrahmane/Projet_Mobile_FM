import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

class DetailTacheScreen extends StatefulWidget {
  final ComplaintModel complaint;
  const DetailTacheScreen({super.key, required this.complaint});
  @override
  State<DetailTacheScreen> createState() => _State();
}

class _State extends State<DetailTacheScreen> {
  final _commentCtrl = TextEditingController();
  String? _selectedStatus;
  bool    _loading = false;

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'in_progress', 'label': 'Prendre en charge',
     'icon': Icons.engineering_rounded,     'color': AppColors.statusProgress},
    {'value': 'waiting',     'label': 'En attente de pièce',
     'icon': Icons.hourglass_top_rounded,   'color': AppColors.statusWaiting},
    {'value': 'resolved',    'label': 'Marquer comme résolu',
     'icon': Icons.check_circle_rounded,    'color': AppColors.statusResolved},
    {'value': 'cancelled',   'label': 'Escalader / Annuler',
     'icon': Icons.report_problem_rounded,  'color': AppColors.error},
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.complaint.status;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content        : Text('Un commentaire est obligatoire'),
          backgroundColor: AppColors.warning,
          behavior       : SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService().patch(
        '/complaints/${widget.complaint.id}/status',
        {
          'status' : _selectedStatus,
          'comment': _commentCtrl.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Statut mis à jour avec succès'),
            ]),
            backgroundColor: AppColors.success,
            behavior       : SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    final currentIsFinal = ['resolved', 'closed', 'cancelled'].contains(c.status);

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la tâche')),
      body  : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child  : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Info réclamation ──────────────────────────────────
            Container(
              padding   : const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color       : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border      : Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(c.title,
                          style: const TextStyle(
                            fontSize  : 17,
                            fontWeight: FontWeight.w800,
                            color     : AppColors.textPrimary,
                          )),
                      ),
                      StatusBadge(status: c.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Catégorie
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child  : CategoryBadge(category: c.category),
                  ),
                  if (c.user != null) ...[
                    _infoRow(Icons.person_outline_rounded,
                      'Étudiant', c.user!.fullName),
                    const SizedBox(height: 10),
                    if (c.user!.roomNumber != null) ...[
                      _infoRow(Icons.meeting_room_outlined,
                        'Chambre', c.user!.roomNumber!),
                      const SizedBox(height: 10),
                    ],
                    _infoRow(Icons.email_outlined,
                      'Email', c.user!.email),
                    const SizedBox(height: 10),
                  ],
                  _infoRow(Icons.calendar_today_outlined,
                    'Date', '${c.dateFormatted} à ${c.timeFormatted}'),
                  const SizedBox(height: 10),
                  _infoRow(Icons.tag_rounded, 'Réf', '#${c.id}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Description ───────────────────────────────────────
            Container(
              padding   : const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color       : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border      : Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description du problème',
                    style: TextStyle(
                      fontSize  : 13,
                      fontWeight: FontWeight.w700,
                      color     : AppColors.textSecondary,
                    )),
                  const SizedBox(height: 10),
                  Text(c.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color   : AppColors.textPrimary,
                      height  : 1.6,
                    )),
                ],
              ),
            ),

            // ── Photo jointe ──────────────────────────────────────
            if (c.image != null) ...[
              const SizedBox(height: 16),
              Container(
                padding   : const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color       : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border      : Border.all(color: const Color(0xFFE8EDF2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Photo soumise par l\'étudiant',
                      style: TextStyle(
                        fontSize  : 13,
                        fontWeight: FontWeight.w700,
                        color     : AppColors.textSecondary,
                      )),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        '${ApiService.baseUrl.replaceAll('/api', '')}/uploads/${c.image}',
                        fit         : BoxFit.cover,
                        width       : double.infinity,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          height: 80,
                          child : Center(child: Icon(Icons.broken_image_outlined,
                            color: Colors.grey, size: 36)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Mise à jour statut ────────────────────────────────
            if (!currentIsFinal) ...[
              const SizedBox(height: 24),
              const Text('Mettre à jour le statut',
                style: TextStyle(
                  fontSize  : 15,
                  fontWeight: FontWeight.w800,
                  color     : AppColors.textPrimary,
                )),
              const SizedBox(height: 12),

              // Options de statut
              ...(_statusOptions.map((opt) {
                final sel = _selectedStatus == opt['value'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedStatus = opt['value'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin  : const EdgeInsets.only(bottom: 10),
                    padding : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color       : sel
                        ? (opt['color'] as Color).withValues(alpha:0.08)
                        : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border      : Border.all(
                        color: sel
                          ? opt['color'] as Color
                          : const Color(0xFFDDE3EA),
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(opt['icon'] as IconData,
                          color: sel
                            ? opt['color'] as Color
                            : AppColors.textHint,
                          size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(opt['label'] as String,
                            style: TextStyle(
                              fontSize  : 14,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                              color     : sel
                                ? opt['color'] as Color
                                : AppColors.textPrimary,
                            )),
                        ),
                        if (sel)
                          Icon(Icons.check_circle_rounded,
                            color: opt['color'] as Color, size: 20),
                      ],
                    ),
                  ),
                );
              })),

              const SizedBox(height: 16),

              // Commentaire obligatoire
              const Text('Commentaire *',
                style: TextStyle(
                  fontSize  : 13,
                  fontWeight: FontWeight.w700,
                  color     : AppColors.textSecondary,
                )),
              const SizedBox(height: 8),
              TextFormField(
                controller : _commentCtrl,
                maxLines   : 3,
                decoration : const InputDecoration(
                  hintText  : 'Décrivez les actions effectuées ou les raisons du changement...',
                  border    : OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 54,
                child : ElevatedButton.icon(
                  onPressed: _loading ? null : _update,
                  icon : _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.save_rounded),
                  label: Text(_loading ? 'Enregistrement...' : 'Enregistrer le statut'),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding   : const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color       : AppColors.textHint.withValues(alpha:0.08),
                  borderRadius: BorderRadius.circular(12),
                  border      : Border.all(color: AppColors.textHint.withValues(alpha:0.2)),
                ),
                child: const Row(children: [
                  Icon(Icons.lock_rounded, color: AppColors.textHint, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cette réclamation est finalisée et ne peut plus être modifiée.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: AppColors.textHint),
      const SizedBox(width: 8),
      Text('$label : ',
        style: const TextStyle(
          fontSize  : 13,
          color     : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        )),
      Expanded(
        child: Text(value,
          style: const TextStyle(
            fontSize  : 13,
            color     : AppColors.textPrimary,
          )),
      ),
    ],
  );
}
