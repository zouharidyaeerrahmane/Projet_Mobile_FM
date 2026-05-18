import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

class DetailDirectionScreen extends StatefulWidget {
  final ComplaintModel complaint;
  const DetailDirectionScreen({super.key, required this.complaint});
  @override
  State<DetailDirectionScreen> createState() => _State();
}

class _State extends State<DetailDirectionScreen> {
  bool _updating = false;

  Future<void> _changeStatus(String status, String label) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape  : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title  : Text('Passer en "$label" ?'),
        content: const Text('Cette action sera enregistrée dans le journal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _updating = true);

    try {
      await ApiService().patch(
        '/complaints/${widget.complaint.id}/admin-status',
        {'status': status},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour : $label'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail réclamation'),
        actions: [
          if (_updating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child  : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── En-tête ───────────────────────────────────────────
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(c.title,
                          style: const TextStyle(
                            fontSize  : 18,
                            fontWeight: FontWeight.w800,
                            color     : AppColors.textPrimary,
                          )),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge(status: c.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFEEF2F7)),
                  const SizedBox(height: 16),
                  if (c.user != null) ...[
                    _row(Icons.person_outline_rounded,
                      'Étudiant', c.user!.fullName),
                    const SizedBox(height: 10),
                    _row(Icons.email_outlined, 'Email', c.user!.email),
                    const SizedBox(height: 10),
                  ],
                  _row(Icons.calendar_today_outlined,
                    'Date', '${c.dateFormatted} à ${c.timeFormatted}'),
                  const SizedBox(height: 10),
                  _row(Icons.tag_rounded, 'Référence', '#${c.id}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Description ───────────────────────────────────────
            _card('Description', child: Text(c.description,
              style: const TextStyle(
                fontSize: 14,
                color   : AppColors.textPrimary,
                height  : 1.6,
              ))),

            // ── Photo ─────────────────────────────────────────────
            if (c.image != null) ...[
              const SizedBox(height: 16),
              _card('Photo jointe', child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  '${ApiService.baseUrl.replaceAll('/api', '')}/uploads/${c.image}',
                  fit         : BoxFit.cover,
                  width       : double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color : Colors.grey[100],
                    child : const Center(
                      child: Icon(Icons.broken_image_outlined,
                        color: Colors.grey, size: 36)),
                  ),
                ),
              )),
            ],

            // ── Actions direction ─────────────────────────────────
            const SizedBox(height: 24),
            const Text('Actions',
              style: TextStyle(
                fontSize  : 15,
                fontWeight: FontWeight.w800,
                color     : AppColors.textPrimary,
              )),
            const SizedBox(height: 12),

            _actionBtn(
              icon   : Icons.engineering_rounded,
              label  : 'Mettre en cours',
              color  : AppColors.statusProgress,
              onTap  : () => _changeStatus('in_progress', 'En cours'),
              enabled: c.status == 'pending' || c.status == 'waiting',
            ),
            const SizedBox(height: 10),
            _actionBtn(
              icon   : Icons.check_circle_rounded,
              label  : 'Marquer comme résolu',
              color  : AppColors.statusResolved,
              onTap  : () => _changeStatus('resolved', 'Résolu'),
              enabled: c.status != 'resolved' && c.status != 'closed',
            ),
            const SizedBox(height: 10),
            _actionBtn(
              icon   : Icons.lock_rounded,
              label  : 'Clôturer la réclamation',
              color  : AppColors.statusClosed,
              onTap  : () => _changeStatus('closed', 'Clôturée'),
              enabled: c.status == 'resolved',
            ),
            const SizedBox(height: 10),
            _actionBtn(
              icon   : Icons.cancel_rounded,
              label  : 'Annuler (doublon / erreur)',
              color  : AppColors.error,
              onTap  : () => _changeStatus('cancelled', 'Annulée'),
              enabled: c.status != 'closed' && c.status != 'cancelled',
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, {required Widget child}) {
    return Container(
      padding   : const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color       : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border      : Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: const TextStyle(
              fontSize  : 13,
              fontWeight: FontWeight.w700,
              color     : AppColors.textSecondary,
            )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: AppColors.textHint),
      const SizedBox(width: 8),
      Text('$label : ',
        style: const TextStyle(
          fontSize  : 13,
          fontWeight: FontWeight.w600,
          color     : AppColors.textSecondary,
        )),
      Expanded(
        child: Text(value,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
      ),
    ],
  );

  Widget _actionBtn({
    required IconData     icon,
    required String       label,
    required Color        color,
    required VoidCallback onTap,
    required bool         enabled,
  }) {
    return AnimatedOpacity(
      opacity : enabled ? 1.0 : 0.35,
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap       : enabled && !_updating ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding   : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color       : color.withValues(alpha:0.07),
            borderRadius: BorderRadius.circular(12),
            border      : Border.all(color: color.withValues(alpha:0.25)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                  style: TextStyle(
                    fontSize  : 14,
                    fontWeight: FontWeight.w600,
                    color     : color,
                  )),
              ),
              Icon(Icons.chevron_right_rounded,
                color: color.withValues(alpha:0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
