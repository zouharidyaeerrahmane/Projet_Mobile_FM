import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'nouvelle_reclamation_screen.dart';
import 'detail_reclamation_screen.dart';
import 'nouvelle_plainte_bruit_screen.dart';
import 'detail_plainte_bruit_screen.dart';

class EtudiantDashboard extends ConsumerStatefulWidget {
  const EtudiantDashboard({super.key});
  @override
  ConsumerState<EtudiantDashboard> createState() => _EtudiantDashboardState();
}

class _EtudiantDashboardState extends ConsumerState<EtudiantDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── Tab 0 : réclamations techniques ──────────────────────────────
  List<ComplaintModel> _allComplaints      = [];
  List<ComplaintModel> _filteredComplaints = [];
  bool   _loadingComplaints = true;
  String _filterComplaints  = 'all';

  final _complaintFilters = [
    {'key': 'all',         'label': 'Toutes'},
    {'key': 'pending',     'label': 'En attente'},
    {'key': 'in_progress', 'label': 'En cours'},
    {'key': 'resolved',    'label': 'Résolues'},
  ];

  // ── Tab 1 : nuisances sonores ────────────────────────────────────
  List<NoiseReportModel> _allNoise      = [];
  List<NoiseReportModel> _filteredNoise = [];
  bool   _loadingNoise = true;
  String _filterNoise  = 'all';

  final _noiseFilters = [
    {'key': 'all',      'label': 'Tous'},
    {'key': 'pending',  'label': 'En attente'},
    {'key': 'reviewed', 'label': 'Examinés'},
    {'key': 'resolved', 'label': 'Résolus'},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadComplaints();
    _loadNoise();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Chargements ──────────────────────────────────────────────────
  Future<void> _loadComplaints() async {
    setState(() => _loadingComplaints = true);
    try {
      final res  = await ApiService().get('/complaints/my');
      final list = (res.data as List).map((e) => ComplaintModel.fromJson(e)).toList();
      setState(() {
        _allComplaints     = list;
        _loadingComplaints = false;
      });
      _applyComplaintFilter(_filterComplaints);
    } catch (_) {
      setState(() => _loadingComplaints = false);
    }
  }

  Future<void> _loadNoise() async {
    setState(() => _loadingNoise = true);
    try {
      final res  = await ApiService().get('/noise-reports/my');
      final list = (res.data as List).map((e) => NoiseReportModel.fromJson(e)).toList();
      setState(() {
        _allNoise     = list;
        _loadingNoise = false;
      });
      _applyNoiseFilter(_filterNoise);
    } catch (_) {
      setState(() => _loadingNoise = false);
    }
  }

  void _applyComplaintFilter(String f) {
    setState(() {
      _filterComplaints   = f;
      _filteredComplaints = f == 'all'
          ? List.from(_allComplaints)
          : _allComplaints.where((c) => c.status == f).toList();
    });
  }

  void _applyNoiseFilter(String f) {
    setState(() {
      _filterNoise   = f;
      _filteredNoise = f == 'all'
          ? List.from(_allNoise)
          : _allNoise.where((r) => r.status == f).toList();
    });
  }

  Map<String, int> get _complaintStats => {
    'total'      : _allComplaints.length,
    'pending'    : _allComplaints.where((c) => c.status == 'pending').length,
    'in_progress': _allComplaints.where((c) => c.status == 'in_progress').length,
    'resolved'   : _allComplaints.where((c) => c.status == 'resolved').length,
  };

  Map<String, int> get _noiseStats => {
    'total'   : _allNoise.length,
    'pending' : _allNoise.where((r) => r.status == 'pending').length,
    'reviewed': _allNoise.where((r) => r.status == 'reviewed').length,
    'resolved': _allNoise.where((r) => r.status == 'resolved').length,
  };

  Future<void> _showRoomSetup(BuildContext context) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.meeting_room_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Text('Votre chambre'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entrez votre numéro de chambre. Il sera utilisé automatiquement dans toutes vos réclamations.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller : ctrl,
              autofocus  : true,
              decoration : InputDecoration(
                hintText   : 'Ex : 204, B-115...',
                prefixIcon : const Icon(Icons.meeting_room_outlined),
                border     : OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              final ok = await ref.read(authProvider.notifier)
                  .updateRoomNumber(ctrl.text.trim());
              if (!context.mounted) return;
              Navigator.pop(context);
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chambre enregistrée !'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('UniClaim'),
            Text('Bonjour, ${user.fullName.split(' ').first}',
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
            tooltip  : 'Actualiser',
            onPressed: () {
              _loadComplaints();
              _loadNoise();
            },
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
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor       : Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor   : Colors.white,
          indicatorWeight  : 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.build_outlined, size: 18),
              text: 'Réclamations',
            ),
            Tab(
              icon: Icon(Icons.volume_up_outlined, size: 18),
              text: 'Bruit voisins',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Bannière chambre non configurée
          if (user.roomNumber == null)
            _RoomBanner(onTap: () => _showRoomSetup(context)),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildComplaintsTab(),
                _buildNoiseTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabCtrl,
        builder  : (_, __) => _tabCtrl.index == 0
          ? FloatingActionButton.extended(
              heroTag        : 'fab_complaint',
              onPressed      : () async {
                await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const NouvelleReclamationScreen()));
                _loadComplaints();
              },
              icon           : const Icon(Icons.add_rounded),
              label          : const Text('Réclamation'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : FloatingActionButton.extended(
              heroTag        : 'fab_noise',
              onPressed      : () async {
                await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const NouvellePlainteBruitScreen()));
                _loadNoise();
              },
              icon           : const Icon(Icons.campaign_rounded),
              label          : const Text('Signaler'),
              backgroundColor: AppColors.security,
              foregroundColor: Colors.white,
            ),
      ),
    );
  }

  // ── Tab 0 : Réclamations techniques ──────────────────────────────
  Widget _buildComplaintsTab() {
    return RefreshIndicator(
      onRefresh: _loadComplaints,
      color    : AppColors.primary,
      child    : _loadingComplaints
        ? const LoadingList()
        : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vue d\'ensemble',
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
                        childAspectRatio : 1.3,
                        children: [
                          StatCard(label: 'Total', value: '${_complaintStats['total']}',
                            icon: Icons.list_alt_rounded, color: AppColors.primary),
                          StatCard(label: 'En attente', value: '${_complaintStats['pending']}',
                            icon: Icons.schedule_rounded, color: AppColors.statusPending),
                          StatCard(label: 'En cours', value: '${_complaintStats['in_progress']}',
                            icon: Icons.engineering_rounded, color: AppColors.statusProgress),
                          StatCard(label: 'Résolues', value: '${_complaintStats['resolved']}',
                            icon: Icons.check_circle_rounded, color: AppColors.statusResolved),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mes réclamations',
                        style: TextStyle(
                          fontSize  : 16,
                          fontWeight: FontWeight.w800,
                          color     : AppColors.textPrimary,
                        )),
                      const SizedBox(height: 12),
                      _FilterRow(
                        filters : _complaintFilters,
                        selected: _filterComplaints,
                        onSelect: _applyComplaintFilter,
                      ),
                    ],
                  ),
                ),
              ),
              _filteredComplaints.isEmpty
                ? SliverFillRemaining(
                    child: EmptyState(
                      icon       : Icons.inbox_rounded,
                      title      : 'Aucune réclamation',
                      subtitle   : 'Appuyez sur + pour soumettre une nouvelle réclamation.',
                      actionLabel: 'Nouvelle réclamation',
                      onAction   : () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const NouvelleReclamationScreen()));
                        _loadComplaints();
                      },
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => ComplaintCard(
                          complaint: _filteredComplaints[i],
                          onTap    : () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => DetailReclamationScreen(
                                complaint: _filteredComplaints[i])));
                            _loadComplaints();
                          },
                        ),
                        childCount: _filteredComplaints.length,
                      ),
                    ),
                  ),
            ],
          ),
    );
  }

  // ── Tab 1 : Nuisances sonores ────────────────────────────────────
  Widget _buildNoiseTab() {
    return RefreshIndicator(
      onRefresh: _loadNoise,
      color    : AppColors.security,
      child    : _loadingNoise
        ? const LoadingList()
        : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mes signalements de bruit',
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
                        childAspectRatio : 1.3,
                        children: [
                          StatCard(label: 'Total', value: '${_noiseStats['total']}',
                            icon: Icons.campaign_rounded, color: AppColors.security),
                          StatCard(label: 'En attente', value: '${_noiseStats['pending']}',
                            icon: Icons.schedule_rounded, color: AppColors.statusPending),
                          StatCard(label: 'Examinés', value: '${_noiseStats['reviewed']}',
                            icon: Icons.visibility_rounded, color: AppColors.noiseReviewed),
                          StatCard(label: 'Résolus', value: '${_noiseStats['resolved']}',
                            icon: Icons.check_circle_rounded, color: AppColors.statusResolved),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Historique',
                        style: TextStyle(
                          fontSize  : 16,
                          fontWeight: FontWeight.w800,
                          color     : AppColors.textPrimary,
                        )),
                      const SizedBox(height: 12),
                      _FilterRow(
                        filters : _noiseFilters,
                        selected: _filterNoise,
                        onSelect: _applyNoiseFilter,
                        activeColor: AppColors.security,
                      ),
                    ],
                  ),
                ),
              ),
              _filteredNoise.isEmpty
                ? SliverFillRemaining(
                    child: EmptyState(
                      icon       : Icons.volume_off_rounded,
                      title      : 'Aucun signalement',
                      subtitle   : 'Appuyez sur Signaler pour déclarer une nuisance sonore.',
                      actionLabel: 'Nouveau signalement',
                      onAction   : () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const NouvellePlainteBruitScreen()));
                        _loadNoise();
                      },
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _NoiseReportCard(
                          report: _filteredNoise[i],
                          onTap : () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => DetailPlainteBruitScreen(
                                report: _filteredNoise[i])));
                            _loadNoise();
                          },
                        ),
                        childCount: _filteredNoise.length,
                      ),
                    ),
                  ),
            ],
          ),
    );
  }
}

// ── Bannière chambre non configurée ─────────────────────────────
class _RoomBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _RoomBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width  : double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color  : AppColors.warning.withValues(alpha: 0.12),
        child  : Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Numéro de chambre non configuré — appuyez pour le définir',
                style: TextStyle(
                  fontSize  : 12,
                  color     : AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: AppColors.warning),
          ],
        ),
      ),
    );
  }
}

// ── Filtre chips réutilisable ────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final List<Map<String, String>> filters;
  final String       selected;
  final void Function(String) onSelect;
  final Color        activeColor;

  const _FilterRow({
    required this.filters,
    required this.selected,
    required this.onSelect,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final sel = selected == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label         : Text(f['label']!),
              selected      : sel,
              onSelected    : (_) => onSelect(f['key']!),
              selectedColor : activeColor,
              checkmarkColor: Colors.white,
              labelStyle    : TextStyle(
                color     : sel ? Colors.white : AppColors.textSecondary,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                fontSize  : 13,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: sel ? activeColor : const Color(0xFFDDE3EA)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Carte signalement bruit ───────────────────────────────────────
class _NoiseReportCard extends StatelessWidget {
  final NoiseReportModel report;
  final VoidCallback     onTap;

  const _NoiseReportCard({required this.report, required this.onTap});

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
                  Container(
                    width : 36, height: 36,
                    decoration: BoxDecoration(
                      color : AppColors.security.withValues(alpha: 0.1),
                      shape : BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up_rounded,
                      size: 18, color: AppColors.security),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chambre ${report.roomNumber} → Voisin ${report.neighborRoom}',
                          style: const TextStyle(
                            fontSize  : 14,
                            fontWeight: FontWeight.w700,
                            color     : AppColors.textPrimary,
                          ),
                        ),
                        if (report.locationLabel.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(report.locationLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color   : AppColors.textHint,
                            )),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: report.status),
                ],
              ),
              const SizedBox(height: 10),
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
                  const Icon(Icons.calendar_today_outlined,
                    size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(report.dateFormatted,
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  if (report.agentNote != null && report.agentNote!.isNotEmpty) ...[
                    const Spacer(),
                    const Icon(Icons.comment_outlined,
                      size: 13, color: AppColors.security),
                    const SizedBox(width: 3),
                    const Text('Réponse',
                      style: TextStyle(fontSize: 12, color: AppColors.security)),
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
