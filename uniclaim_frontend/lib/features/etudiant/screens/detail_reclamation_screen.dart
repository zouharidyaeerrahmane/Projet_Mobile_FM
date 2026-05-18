import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

class DetailReclamationScreen extends StatefulWidget {
  final ComplaintModel complaint;
  const DetailReclamationScreen({super.key, required this.complaint});
  @override
  State<DetailReclamationScreen> createState() => _State();
}

class _State extends State<DetailReclamationScreen> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title : const Text('Annuler la réclamation ?'),
        content: const Text(
          'Cette action est irréversible. Voulez-vous vraiment annuler cette réclamation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            style    : ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child    : const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _cancelling = true);

    try {
      await ApiService().patch(
        '/complaints/${widget.complaint.id}/cancel', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content        : Text('Réclamation annulée'),
            backgroundColor: AppColors.warning,
            behavior       : SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _rate() async {
    double note = 4;
    final ctrl  = TextEditingController();

    await showModalBottomSheet(
      context      : context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color        : Colors.white,
            borderRadius : BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              const Text('Évaluer l\'intervention',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Comment s\'est passée l\'intervention ?',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 24),
              RatingBar.builder(
                initialRating   : note,
                minRating       : 1,
                itemCount       : 5,
                itemSize        : 40,
                itemPadding     : const EdgeInsets.symmetric(horizontal: 4),
                itemBuilder     : (_, __) =>
                  const Icon(Icons.star_rounded, color: Color(0xFFFFC107)),
                onRatingUpdate  : (r) => note = r,
              ),
              const SizedBox(height: 20),
              TextField(
                controller : ctrl,
                maxLines   : 3,
                decoration : const InputDecoration(
                  labelText: 'Commentaire (optionnel)',
                  border   : OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width : double.infinity,
                height: 50,
                child : ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ApiService().patch(
                        '/complaints/${widget.complaint.id}/rate',
                        {'rating': note.toInt(), 'comment': ctrl.text},
                      );
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Merci pour votre évaluation !'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      navigator.pop();
                    } catch (_) {}
                  },
                  child: const Text('Envoyer l\'évaluation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    final canCancel = c.status == 'pending';
    final canRate   = c.status == 'resolved';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail réclamation'),
        actions: [
          if (canCancel)
            _cancelling
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)))
              : IconButton(
                  icon   : const Icon(Icons.cancel_outlined),
                  tooltip: 'Annuler',
                  onPressed: _cancel,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child  : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Carte principale ──────────────────────────────────
            Container(
              padding   : const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color        : Colors.white,
                borderRadius : BorderRadius.circular(16),
                border       : Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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

                  _infoRow(Icons.calendar_today_outlined,
                    'Soumise le', '${c.dateFormatted} à ${c.timeFormatted}'),
                  const SizedBox(height: 12),
                  _infoRow(Icons.tag_rounded,
                    'Référence', '#${c.id}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Description ───────────────────────────────────────
            _section('Description',
              child: Text(c.description,
                style: const TextStyle(
                  fontSize: 14,
                  color   : AppColors.textSecondary,
                  height  : 1.6,
                ))),

            // ── Photo ─────────────────────────────────────────────
            if (c.image != null) ...[
              const SizedBox(height: 16),
              _section('Photo jointe',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    '${ApiService.baseUrl.replaceAll('/api', '')}/uploads/${c.image}',
                    fit          : BoxFit.cover,
                    width        : double.infinity,
                    errorBuilder : (_, __, ___) => Container(
                      height: 120,
                      color : Colors.grey[100],
                      child : const Center(
                        child: Icon(Icons.broken_image_outlined,
                          color: Colors.grey, size: 40)),
                    ),
                  ),
                )),
            ],

            // ── Évaluation ────────────────────────────────────────
            if (canRate) ...[
              const SizedBox(height: 24),
              Container(
                padding   : const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color        : AppColors.success.withValues(alpha:0.06),
                  borderRadius : BorderRadius.circular(16),
                  border       : Border.all(
                    color: AppColors.success.withValues(alpha:0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 36),
                    const SizedBox(height: 12),
                    const Text('Problème résolu !',
                      style: TextStyle(
                        fontSize  : 16,
                        fontWeight: FontWeight.w800,
                        color     : AppColors.success,
                      )),
                    const SizedBox(height: 6),
                    const Text('Donnez votre avis sur l\'intervention',
                      style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width : double.infinity,
                      child : ElevatedButton.icon(
                        style    : ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success),
                        onPressed: _rate,
                        icon : const Icon(Icons.star_rounded),
                        label: const Text('Évaluer l\'intervention'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Annulation info ───────────────────────────────────
            if (canCancel) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style    : OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side           : const BorderSide(color: AppColors.error),
                  padding        : const EdgeInsets.symmetric(vertical: 14),
                  shape          : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _cancel,
                icon : const Icon(Icons.cancel_outlined),
                label: const Text('Annuler cette réclamation'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String title, {required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color        : Colors.white,
      borderRadius : BorderRadius.circular(16),
      border       : Border.all(color: const Color(0xFFE8EDF2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
          style: const TextStyle(
            fontSize  : 13,
            fontWeight: FontWeight.w700,
            color     : AppColors.textSecondary,
            letterSpacing: 0.3,
          )),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );

  Widget _infoRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.textHint),
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
            fontWeight: FontWeight.w500,
          )),
      ),
    ],
  );
}
