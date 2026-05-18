import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

class DetailPlainteBruitScreen extends StatefulWidget {
  final NoiseReportModel report;
  const DetailPlainteBruitScreen({super.key, required this.report});
  @override
  State<DetailPlainteBruitScreen> createState() => _State();
}

class _State extends State<DetailPlainteBruitScreen> {
  late NoiseReportModel _report;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title  : const Text('Annuler le signalement ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child    : const Text('Non'),
          ),
          ElevatedButton(
            style    : ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child    : const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _cancelling = true);
    try {
      await ApiService().patch('/noise-reports/${_report.id}/cancel', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content        : Text('Signalement annulé'),
            backgroundColor: AppColors.statusCancelled,
            behavior       : SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
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
        setState(() => _cancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCancel = _report.status == 'pending';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du signalement'),
        actions: [
          if (canCancel)
            TextButton.icon(
              onPressed: _cancelling ? null : _cancel,
              icon : _cancelling
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.cancel_outlined, color: Colors.white, size: 18),
              label: const Text('Annuler', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut
            Center(child: StatusBadge(status: _report.status)),
            const SizedBox(height: 20),

            // Infos chambre
            _InfoCard(
              title: 'Localisation',
              children: [
                _InfoRow(icon: Icons.meeting_room_outlined,
                  label: 'Votre chambre', value: _report.roomNumber),
                _InfoRow(icon: Icons.door_front_door_outlined,
                  label: 'Chambre voisin', value: _report.neighborRoom),
                if (_report.floor != null && _report.floor!.isNotEmpty)
                  _InfoRow(icon: Icons.layers_outlined,
                    label: 'Étage', value: _report.floor!),
                if (_report.block != null && _report.block!.isNotEmpty)
                  _InfoRow(icon: Icons.apartment_outlined,
                    label: 'Bloc', value: _report.block!),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            _InfoCard(
              title: 'Description',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child  : Text(
                    _report.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color   : AppColors.textSecondary,
                      height  : 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Note de l'agent (si présente)
            if (_report.agentNote != null && _report.agentNote!.isNotEmpty) ...[
              _InfoCard(
                title      : 'Réponse de l\'agent de sécurité',
                accentColor: AppColors.security,
                children   : [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.security_rounded,
                        size: 16, color: AppColors.security),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _report.agentNote!,
                          style: const TextStyle(
                            fontSize: 14,
                            color   : AppColors.textSecondary,
                            height  : 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Date
            _InfoCard(
              title: 'Informations',
              children: [
                _InfoRow(icon: Icons.calendar_today_outlined,
                  label: 'Soumis le', value: _report.dateFormatted),
              ],
            ),

            // Explication statut
            const SizedBox(height: 20),
            _StatusTimeline(status: _report.status),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String         title;
  final List<Widget>   children;
  final Color          accentColor;

  const _InfoCard({
    required this.title,
    required this.children,
    this.accentColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding   : const EdgeInsets.all(16),
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
              Container(
                width : 3, height: 16,
                decoration: BoxDecoration(
                  color        : accentColor,
                  borderRadius : BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(title,
                style: const TextStyle(
                  fontSize  : 13,
                  fontWeight: FontWeight.w700,
                  color     : AppColors.textSecondary,
                  letterSpacing: 0.3,
                )),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text('$label : ',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Expanded(
            child: Text(value,
              style: const TextStyle(
                fontSize  : 13,
                fontWeight: FontWeight.w600,
                color     : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'key': 'pending',  'label': 'Soumis',          'icon': Icons.send_rounded},
      {'key': 'reviewed', 'label': 'Examiné',         'icon': Icons.visibility_rounded},
      {'key': 'resolved', 'label': 'Résolu',          'icon': Icons.check_circle_rounded},
    ];

    const order = ['pending', 'reviewed', 'resolved', 'rejected', 'cancelled'];
    final currentIdx = order.indexOf(status);

    return Container(
      padding   : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color       : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border      : Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, size: 16, color: AppColors.textHint),
              SizedBox(width: 8),
              Text('Suivi du signalement',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary, letterSpacing: 0.3,
                )),
            ],
          ),
          const SizedBox(height: 16),
          if (status == 'rejected') ...[
            Row(children: [
              const Icon(Icons.block_rounded, size: 18, color: AppColors.noiseRejected),
              const SizedBox(width: 8),
              const Text('Signalement rejeté',
                style: TextStyle(
                  color     : AppColors.noiseRejected,
                  fontWeight: FontWeight.w600,
                  fontSize  : 14,
                )),
            ]),
          ] else if (status == 'cancelled') ...[
            Row(children: [
              const Icon(Icons.cancel_rounded, size: 18, color: AppColors.statusCancelled),
              const SizedBox(width: 8),
              const Text('Signalement annulé',
                style: TextStyle(
                  color     : AppColors.statusCancelled,
                  fontWeight: FontWeight.w600,
                  fontSize  : 14,
                )),
            ]),
          ] else
            ...steps.asMap().entries.map((entry) {
              final i   = entry.key;
              final s   = entry.value;
              final done = order.indexOf(s['key'] as String) <= currentIdx;
              final active = s['key'] == status;
              final color = active
                  ? (s['key'] as String).statusColor
                  : done
                      ? AppColors.statusResolved
                      : AppColors.textHint;
              return Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width : 28, height: 28,
                        decoration: BoxDecoration(
                          color       : color.withValues(alpha: done ? 0.12 : 0.05),
                          shape       : BoxShape.circle,
                          border      : Border.all(
                            color: done ? color : AppColors.textHint.withValues(alpha: 0.3),
                            width: active ? 2 : 1,
                          ),
                        ),
                        child: Icon(s['icon'] as IconData,
                          size: 14, color: done ? color : AppColors.textHint),
                      ),
                      if (i < steps.length - 1)
                        Container(
                          width : 2, height: 20,
                          color : done ? AppColors.statusResolved.withValues(alpha: 0.3)
                                      : const Color(0xFFE8EDF2),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      s['label'] as String,
                      style: TextStyle(
                        fontSize  : 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color     : done ? AppColors.textPrimary : AppColors.textHint,
                      ),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}
