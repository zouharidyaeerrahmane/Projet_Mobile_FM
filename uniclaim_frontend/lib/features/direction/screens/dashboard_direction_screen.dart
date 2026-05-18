import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'reclamations_direction_screen.dart';

class DirectionDashboard extends ConsumerStatefulWidget {
  const DirectionDashboard({super.key});
  @override
  ConsumerState<DirectionDashboard> createState() => _DirectionDashboardState();
}

class _DirectionDashboardState extends ConsumerState<DirectionDashboard> {
  Map<String, dynamic> _stats    = {};
  List<ComplaintModel> _recent   = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final [statsRes, recentRes] = await Future.wait([
        ApiService().get('/complaints/stats'),
        ApiService().get('/complaints', params: {'limit': '5', 'page': '1'}),
      ]);
      setState(() {
        _stats  = statsRes.data as Map<String, dynamic>;
        _recent = (recentRes.data['data'] as List)
            .map((e) => ComplaintModel.fromJson(e)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tableau de bord'),
            Text(user.roleLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400,
                color: Colors.white70)),
          ],
        ),
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
      body: _loading
        ? const LoadingList()
        : RefreshIndicator(
            onRefresh: _load,
            child    : SingleChildScrollView(
              physics : const AlwaysScrollableScrollPhysics(),
              padding : const EdgeInsets.all(16),
              child   : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── KPIs ─────────────────────────────────────────
                  _sectionTitle('Statistiques générales'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount  : 2,
                    shrinkWrap      : true,
                    physics         : const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing : 10,
                    childAspectRatio: 1.4,
                    children: [
                      StatCard(
                        label: 'Total',
                        value: '${_stats['total'] ?? 0}',
                        icon : Icons.list_alt_rounded,
                        color: AppColors.primary,
                      ),
                      StatCard(
                        label: 'En attente',
                        value: '${_stats['pending'] ?? 0}',
                        icon : Icons.schedule_rounded,
                        color: AppColors.statusPending,
                      ),
                      StatCard(
                        label: 'En cours',
                        value: '${_stats['in_progress'] ?? 0}',
                        icon : Icons.engineering_rounded,
                        color: AppColors.statusProgress,
                      ),
                      StatCard(
                        label: 'Résolues',
                        value: '${_stats['resolved'] ?? 0}',
                        icon : Icons.check_circle_rounded,
                        color: AppColors.statusResolved,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Graphique camembert ───────────────────────────
                  _sectionTitle('Répartition par statut'),
                  const SizedBox(height: 12),
                  Container(
                    padding   : const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color       : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border      : Border.all(color: const Color(0xFFE8EDF2)),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child : _PieChart(stats: _stats),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing    : 16,
                          runSpacing : 8,
                          children   : [
                            _legend('En attente', AppColors.statusPending),
                            _legend('En cours',   AppColors.statusProgress),
                            _legend('Résolues',   AppColors.statusResolved),
                            _legend('Clôturées',  AppColors.statusClosed),
                            _legend('Annulées',   AppColors.statusCancelled),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Récentes ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle('Réclamations récentes'),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ReclamationsDirectionScreen())),
                        child: const Text('Voir tout →'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_recent.isEmpty)
                    const EmptyState(
                      icon    : Icons.inbox_rounded,
                      title   : 'Aucune réclamation',
                      subtitle: 'Aucune réclamation soumise pour le moment.',
                    )
                  else
                    ..._recent.map((c) => ComplaintCard(
                      complaint: c,
                      showUser : true,
                      onTap    : () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ReclamationsDirectionScreen(
                          initialComplaint: c))),
                    )),

                  const SizedBox(height: 16),

                  // ── Accès rapide ──────────────────────────────────
                  _sectionTitle('Accès rapide'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon    : Icons.list_alt_rounded,
                          label   : 'Toutes les\nréclamations',
                          color   : AppColors.primary,
                          onTap   : () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const ReclamationsDirectionScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon    : Icons.warning_amber_rounded,
                          label   : 'Urgentes',
                          color   : AppColors.error,
                          onTap   : () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const ReclamationsDirectionScreen(
                              filterStatus: 'pending'))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
    style: const TextStyle(
      fontSize  : 15,
      fontWeight: FontWeight.w800,
      color     : AppColors.textPrimary,
    ));

  Widget _legend(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width : 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ],
  );
}

// ── Pie chart ─────────────────────────────────────────────────────
class _PieChart extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _PieChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[];
    final data = [
      {'key': 'pending',     'color': AppColors.statusPending},
      {'key': 'in_progress', 'color': AppColors.statusProgress},
      {'key': 'resolved',    'color': AppColors.statusResolved},
      {'key': 'closed',      'color': AppColors.statusClosed},
      {'key': 'cancelled',   'color': AppColors.statusCancelled},
    ];

    final total = data.fold<int>(0, (sum, d) => sum + ((stats[d['key']] ?? 0) as int));

    for (final d in data) {
      final val = (stats[d['key']] ?? 0) as int;
      if (val == 0) continue;
      final pct = total > 0 ? val / total * 100 : 0;
      sections.add(PieChartSectionData(
        value      : val.toDouble(),
        color      : d['color'] as Color,
        radius     : 70,
        title      : '${pct.toStringAsFixed(0)}%',
        titleStyle : const TextStyle(
          fontSize  : 12,
          fontWeight: FontWeight.w700,
          color     : Colors.white,
        ),
      ));
    }

    if (sections.isEmpty) {
      return const Center(
        child: Text('Pas de données',
          style: TextStyle(color: AppColors.textHint)));
    }

    return PieChart(
      PieChartData(
        sections         : sections,
        centerSpaceRadius: 30,
        sectionsSpace    : 3,
        borderData       : FlBorderData(show: false),
      ),
    );
  }
}

// ── Quick action button ───────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap       : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding   : const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color       : color.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(16),
          border      : Border.all(color: color.withValues(alpha:0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(label,
              style: TextStyle(
                fontSize  : 13,
                fontWeight: FontWeight.w700,
                color     : color,
                height    : 1.3,
              )),
          ],
        ),
      ),
    );
  }
}
