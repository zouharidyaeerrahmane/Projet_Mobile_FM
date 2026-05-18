import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'detail_tache_screen.dart';

class TachesScreen extends ConsumerStatefulWidget {
  const TachesScreen({super.key});
  @override
  ConsumerState<TachesScreen> createState() => _TachesScreenState();
}

class _TachesScreenState extends ConsumerState<TachesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<ComplaintModel> _all = [];
  bool _loading = true;

  final _tabFilters = ['all', 'pending', 'in_progress', 'resolved'];
  final _tabLabels  = ['Toutes', 'En attente', 'En cours', 'Résolues'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().get('/complaints/assigned');
      setState(() {
        _all     = (res.data as List).map((e) => ComplaintModel.fromJson(e)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<ComplaintModel> _forTab(int i) {
    if (i == 0) return _all;
    return _all.where((c) => c.status == _tabFilters[i]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mes tâches'),
            Text(user.fullName,
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
        bottom: TabBar(
          controller     : _tabs,
          isScrollable   : true,
          indicatorColor : Colors.white,
          indicatorWeight: 3,
          labelColor     : Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle     : const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabAlignment   : TabAlignment.start,
          tabs           : _tabLabels.asMap().entries.map((e) {
            final count = _forTab(e.key).length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e.value),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color : Colors.white.withValues(alpha:0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$count',
                        style: const TextStyle(fontSize: 11, color: Colors.white)),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: _loading
        ? const LoadingList()
        : TabBarView(
            controller: _tabs,
            children  : List.generate(4, (i) {
              final items = _forTab(i);
              if (items.isEmpty) {
                return EmptyState(
                  icon    : Icons.task_alt_rounded,
                  title   : 'Aucune tâche',
                  subtitle: i == 0
                    ? 'Aucune réclamation ne vous est assignée.'
                    : 'Aucune tâche dans cette catégorie.',
                );
              }
              return RefreshIndicator(
                onRefresh: _load,
                child    : ListView.builder(
                  padding    : const EdgeInsets.all(16),
                  itemCount  : items.length,
                  itemBuilder: (_, j) => _TacheCard(
                    complaint: items[j],
                    onTap    : () async {
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => DetailTacheScreen(complaint: items[j])));
                      _load();
                    },
                  ),
                ),
              );
            }),
          ),
    );
  }
}

class _TacheCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback   onTap;
  const _TacheCard({required this.complaint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    return Card(
      child: InkWell(
        onTap       : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child  : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width : 42, height: 42,
                    decoration: BoxDecoration(
                      color : c.category.categoryColor.withValues(alpha: 0.12),
                      shape : BoxShape.circle,
                    ),
                    child: Icon(c.category.categoryIcon,
                      color: c.category.categoryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title,
                          style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Row(children: [
                          Text(c.user?.fullName ?? 'Inconnu',
                            style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                          if (c.user?.roomNumber != null) ...[
                            const Text(' — ',
                              style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                            const Icon(Icons.meeting_room_outlined,
                              size: 11, color: AppColors.textHint),
                            const SizedBox(width: 2),
                            Text('Ch. ${c.user!.roomNumber!}',
                              style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  StatusBadge(status: c.status, small: true),
                ],
              ),
              const SizedBox(height: 10),
              CategoryBadge(category: c.category),
              const SizedBox(height: 10),
              Text(c.description,
                maxLines : 2,
                overflow : TextOverflow.ellipsis,
                style    : const TextStyle(
                  fontSize: 13,
                  color   : AppColors.textSecondary,
                  height  : 1.4,
                )),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                    size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(c.dateFormatted,
                    style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint)),
                  const Spacer(),
                  if (c.image != null)
                    const Icon(Icons.image_outlined,
                      size: 14, color: AppColors.accent),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.textHint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
