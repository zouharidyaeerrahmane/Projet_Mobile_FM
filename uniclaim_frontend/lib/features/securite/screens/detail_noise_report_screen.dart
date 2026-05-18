import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

class DetailNoiseReportScreen extends StatefulWidget {
  final NoiseReportModel report;
  const DetailNoiseReportScreen({super.key, required this.report});
  @override
  State<DetailNoiseReportScreen> createState() => _State();
}

class _State extends State<DetailNoiseReportScreen> {
  late NoiseReportModel _report;
  bool _saving = false;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _noteCtrl.text = _report.agentNote ?? '';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title  : Text('Passer à « ${status.statusLabel} » ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Note pour l\'étudiant (optionnel) :'),
            const SizedBox(height: 8),
            TextField(
              controller  : _noteCtrl,
              maxLines    : 3,
              decoration  : InputDecoration(
                hintText    : 'Ex : Étudiant chambre ${_report.neighborRoom} averti...',
                border      : OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child    : const Text('Annuler'),
          ),
          ElevatedButton(
            style    : ElevatedButton.styleFrom(
              backgroundColor: status.statusColor,
            ),
            onPressed: () => Navigator.pop(context, true),
            child    : const Text('Confirmer',
              style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final res = await ApiService().patch(
        '/noise-reports/${_report.id}/status',
        {
          'status'   : status,
          'agentNote': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        },
      );
      setState(() {
        _report = NoiseReportModel.fromJson(res.data);
        _saving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour : ${status.statusLabel}'),
            backgroundColor: status.statusColor,
            behavior       : SnackBarBehavior.floating,
          ),
        );
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
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = ['resolved', 'rejected', 'cancelled'].contains(_report.status);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.security,
        title          : const Text('Détail du signalement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête étudiant
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color       : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border      : Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: Row(
                children: [
                  Container(
                    width : 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.security.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                      color: AppColors.security, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_report.user?.fullName ?? 'Étudiant',
                          style: const TextStyle(
                            fontSize  : 15,
                            fontWeight: FontWeight.w700,
                            color     : AppColors.textPrimary,
                          )),
                        Text(_report.user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color   : AppColors.textSecondary,
                          )),
                      ],
                    ),
                  ),
                  StatusBadge(status: _report.status),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Détails localisation
            _SectionCard(
              title: 'Localisation du problème',
              icon : Icons.location_on_outlined,
              color: AppColors.security,
              children: [
                _Row(label: 'Chambre plaignant', value: _report.roomNumber,
                  icon: Icons.meeting_room_outlined),
                _Row(label: 'Chambre voisin', value: _report.neighborRoom,
                  icon: Icons.door_front_door_outlined),
                if (_report.floor != null && _report.floor!.isNotEmpty)
                  _Row(label: 'Étage', value: _report.floor!,
                    icon: Icons.layers_outlined),
                if (_report.block != null && _report.block!.isNotEmpty)
                  _Row(label: 'Bloc', value: _report.block!,
                    icon: Icons.apartment_outlined),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            _SectionCard(
              title: 'Description des nuisances',
              icon : Icons.volume_up_outlined,
              color: AppColors.security,
              children: [
                Text(_report.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color   : AppColors.textSecondary,
                    height  : 1.6,
                  )),
              ],
            ),
            const SizedBox(height: 16),

            // Note agent existante
            if (_report.agentNote != null && _report.agentNote!.isNotEmpty) ...[
              _SectionCard(
                title: 'Votre note',
                icon : Icons.comment_outlined,
                color: AppColors.security,
                children: [
                  Text(_report.agentNote!,
                    style: const TextStyle(
                      fontSize: 14,
                      color   : AppColors.textSecondary,
                      height  : 1.6,
                    )),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Date
            _SectionCard(
              title: 'Informations',
              icon : Icons.info_outline_rounded,
              color: AppColors.textHint,
              children: [
                _Row(label: 'Soumis le', value: _report.dateFormatted,
                  icon: Icons.calendar_today_outlined),
              ],
            ),

            // Actions (si pas clôturé)
            if (!isClosed) ...[
              const SizedBox(height: 24),
              const Text('Actions',
                style: TextStyle(
                  fontSize  : 15,
                  fontWeight: FontWeight.w800,
                  color     : AppColors.textPrimary,
                )),
              const SizedBox(height: 12),
              if (_report.status == 'pending') ...[
                _ActionButton(
                  label    : 'Marquer comme examiné',
                  icon     : Icons.visibility_rounded,
                  color    : AppColors.noiseReviewed,
                  loading  : _saving,
                  onPressed: () => _updateStatus('reviewed'),
                ),
                const SizedBox(height: 10),
              ],
              if (_report.status == 'pending' || _report.status == 'reviewed') ...[
                _ActionButton(
                  label    : 'Marquer comme résolu',
                  icon     : Icons.check_circle_rounded,
                  color    : AppColors.statusResolved,
                  loading  : _saving,
                  onPressed: () => _updateStatus('resolved'),
                ),
                const SizedBox(height: 10),
                _ActionButton(
                  label    : 'Rejeter (non fondé)',
                  icon     : Icons.block_rounded,
                  color    : AppColors.noiseRejected,
                  loading  : _saving,
                  onPressed: () => _updateStatus('rejected'),
                  outlined : true,
                ),
              ],
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String       title;
  final IconData     icon;
  final Color        color;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
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
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(title,
                style: TextStyle(
                  fontSize     : 13,
                  fontWeight   : FontWeight.w700,
                  color        : color,
                  letterSpacing: 0.3,
                )),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE8EDF2)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;

  const _Row({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textHint),
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

class _ActionButton extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final Color        color;
  final bool         loading;
  final VoidCallback onPressed;
  final bool         outlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width : double.infinity,
        height: 48,
        child : OutlinedButton.icon(
          onPressed: loading ? null : onPressed,
          icon : loading
            ? SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: color, strokeWidth: 2))
            : Icon(icon, color: color, size: 18),
          label: Text(label, style: TextStyle(color: color)),
          style: OutlinedButton.styleFrom(
            side        : BorderSide(color: color),
            shape       : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
    return SizedBox(
      width : double.infinity,
      height: 48,
      child : ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon : loading
          ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape          : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
