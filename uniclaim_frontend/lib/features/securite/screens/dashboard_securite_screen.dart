import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'detail_noise_report_screen.dart';

class SecuriteDashboard extends ConsumerStatefulWidget {
  const SecuriteDashboard({super.key});
  @override
  ConsumerState<SecuriteDashboard> createState() => _SecuriteDashboardState();
}

class _SecuriteDashboardState extends ConsumerState<SecuriteDashboard> {
  List<NoiseReportModel>  _reports    = [];
  Map<String, dynamic>    _stats      = {};
  bool   _loading = true;
  String _filter  = 'all';
  String _search  = '';
  int    _page    = 1;
  int    _total   = 0;
  static const int _limit = 15;

  final _filters = [
    {'key': 'all',      'label': 'Tous'},
    {'key': 'pending',  'label': 'En attente'},
    {'key': 'reviewed', 'label': 'Examinés'},
    {'key': 'resolved', 'label': 'Résolus'},
    {'key': 'rejected', 'label': 'Rejetés'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) _page = 1;
    setState(() => _loading = true);
    try {
      final params = <String, dynamic>{
        'page'  : '$_page',
        'limit' : '$_limit',
        if (_filter != 'all') 'status': _filter,
        if (_search.isNotEmpty) 'search': _search,
      };
      final [statsRes, listRes] = await Future.wait([
        ApiService().get('/noise-reports/stats'),
        ApiService().get('/noise-reports', params: params),
      ]);
      setState(() {
        _stats   = statsRes.data as Map<String, dynamic>;
        _reports = (listRes.data['data'] as List)
            .map((e) => NoiseReportModel.fromJson(e)).toList();
        _total   = listRes.data['total'] as int;
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.security,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nuisances Sonores'),
            Text(user.fullName,
              style: const TextStyle(
                fontSize  : 12,
                fontWeight: FontWeight.w400,
                color     : Colors.white70,
              )),
          ],
        ),
        actions: [
          IconButton(
            icon     : const Icon(Icons.refresh_rounded),
            onPressed: () => _load(),
          ),
          PopupMenuButton(
            icon      : const Icon(Icons.more_vert_rounded),
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
      body: RefreshIndicator(
        onRefresh: () => _load(),
        color    : AppColors.security,
        child    : _loading
          ? const LoadingList()
          : CustomScrollView(
              slivers: [
                // ── Stats ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tableau de bord sécurité',
                          style: TextStyle(
                            fontSize  : 13,
                            fontWeight: FontWeight.w600,
                            color     : AppColors.textSecondary,
                            letterSpacing: 0.5,
                          )),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount   : 2,
                          shrinkWrap       : true,
                          physics          : const NeverScrollableScrollPhysics(),
                          crossAxisSpacing : 10,
                          mainAxisSpacing  : 10,
                          childAspectRatio : 1.35,
                          children: [
                            StatCard(label: 'Total', value: '${_stats['total'] ?? 0}',
                              icon: Icons.campaign_rounded, color: AppColors.security),
                            StatCard(label: 'En attente', value: '${_stats['pending'] ?? 0}',
                              icon: Icons.schedule_rounded, color: AppColors.statusPending),
                            StatCard(label: 'Examinés', value: '${_stats['reviewed'] ?? 0}',
                              icon: Icons.visibility_rounded, color: AppColors.noiseReviewed),
                            StatCard(label: 'Résolus', value: '${_stats['resolved'] ?? 0}',
                              icon: Icons.check_circle_rounded, color: AppColors.statusResolved),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Barre recherche ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText    : 'Chercher par chambre, bloc...',
                        prefixIcon  : const Icon(Icons.search_rounded),
                        filled      : true,
                        fillColor   : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide  : const BorderSide(color: Color(0xFFDDE3EA)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide  : const BorderSide(color: Color(0xFFDDE3EA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide  : const BorderSide(
                            color: AppColors.security, width: 2),
                        ),
                      ),
                      onChanged: (v) {
                        _search = v.trim();
                        _load();
                      },
                    ),
                  ),
                ),

                // ── Filtres ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Signalements',
                              style: TextStyle(
                                fontSize  : 16,
                                fontWeight: FontWeight.w800,
                                color     : AppColors.textPrimary,
                              )),
                            Text('$_total résultat${_total > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 13,
                                color   : AppColors.textSecondary,
                              )),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _filters.map((f) {
                              final sel = _filter == f['key'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label         : Text(f['label']!),
                                  selected      : sel,
                                  onSelected    : (_) {
                                    _filter = f['key']!;
                                    _load();
                                  },
                                  selectedColor : AppColors.security,
                                  checkmarkColor: Colors.white,
                                  labelStyle    : TextStyle(
                                    color     : sel ? Colors.white : AppColors.textSecondary,
                                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                    fontSize  : 13,
                                  ),
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                    color: sel
                                      ? AppColors.security
                                      : const Color(0xFFDDE3EA),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Liste ──────────────────────────────────────────
                _reports.isEmpty
                  ? SliverFillRemaining(
                      child: EmptyState(
                        icon    : Icons.volume_off_rounded,
                        title   : 'Aucun signalement',
                        subtitle: 'Aucun signalement ne correspond aux filtres sélectionnés.',
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      sliver : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            if (i == _reports.length) {
                              return _reports.length < _total
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: TextButton(
                                      onPressed: () {
                                        _page++;
                                        _load(reset: false);
                                      },
                                      child: const Text('Charger plus'),
                                    ),
                                  )
                                : const SizedBox.shrink();
                            }
                            return _AgentNoiseCard(
                              report: _reports[i],
                              onTap : () async {
                                await Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => DetailNoiseReportScreen(
                                    report: _reports[i])));
                                _load();
                              },
                            );
                          },
                          childCount: _reports.length + 1,
                        ),
                      ),
                    ),
              ],
            ),
      ),
    );
  }
}

// ── Carte vue agent ───────────────────────────────────────────────
class _AgentNoiseCard extends StatelessWidget {
  final NoiseReportModel report;
  final VoidCallback     onTap;

  const _AgentNoiseCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap       : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chambre ${report.roomNumber} → Chambre ${report.neighborRoom}',
                          style: const TextStyle(
                            fontSize  : 14,
                            fontWeight: FontWeight.w700,
                            color     : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (report.locationLabel.isNotEmpty)
                          Text(report.locationLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color   : AppColors.textHint,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: report.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.description,
                maxLines : 2,
                overflow : TextOverflow.ellipsis,
                style    : const TextStyle(
                  fontSize: 13,
                  color   : AppColors.textSecondary,
                  height  : 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(report.user?.fullName ?? 'Étudiant',
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  const SizedBox(width: 12),
                  const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(report.dateFormatted,
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  if (report.status == 'pending') ...[
                    const Spacer(),
                    Container(
                      width : 8, height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.statusPending,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('Nouveau',
                      style: TextStyle(
                        fontSize  : 12,
                        fontWeight: FontWeight.w600,
                        color     : AppColors.statusPending,
                      )),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
