import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'detail_direction_screen.dart';

class ReclamationsDirectionScreen extends StatefulWidget {
  final String?        filterStatus;
  final ComplaintModel? initialComplaint;
  const ReclamationsDirectionScreen({
    super.key,
    this.filterStatus,
    this.initialComplaint,
  });
  @override
  State<ReclamationsDirectionScreen> createState() => _State();
}

class _State extends State<ReclamationsDirectionScreen> {
  List<ComplaintModel> _items   = [];
  bool   _loading  = true;
  String _status   = 'all';
  String _search   = '';
  int    _page     = 1;
  int    _total    = 0;
  bool   _hasMore  = true;

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _status = widget.filterStatus ?? 'all';
    _scrollCtrl.addListener(_onScroll);
    _load(reset: true);

    if (widget.initialComplaint != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => DetailDirectionScreen(
            complaint: widget.initialComplaint!)));
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      if (_hasMore && !_loading) _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) { _page = 1; _items = []; _hasMore = true; }
    if (!_hasMore) return;
    setState(() => _loading = true);

    try {
      final params = <String, String>{
        'page' : '$_page',
        'limit': '15',
        if (_status != 'all') 'status': _status,
        if (_search.isNotEmpty) 'search': _search,
      };
      final res = await ApiService().get('/complaints', params: params);
      final data  = res.data['data']  as List;
      final total = res.data['total'] as int;

      setState(() {
        _items.addAll(data.map((e) => ComplaintModel.fromJson(e)));
        _total   = total;
        _hasMore = _items.length < total;
        _page++;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  final _statusFilters = [
    {'key': 'all',         'label': 'Toutes'},
    {'key': 'pending',     'label': 'En attente'},
    {'key': 'in_progress', 'label': 'En cours'},
    {'key': 'waiting',     'label': 'En attente pièce'},
    {'key': 'resolved',    'label': 'Résolues'},
    {'key': 'closed',      'label': 'Clôturées'},
    {'key': 'cancelled',   'label': 'Annulées'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Réclamations'),
            Text('$_total au total',
              style: const TextStyle(fontSize: 12,
                fontWeight: FontWeight.w400, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _load(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barre de recherche ──────────────────────────────────
          Container(
            color  : AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child  : TextField(
              controller : _searchCtrl,
              style      : const TextStyle(color: Colors.white),
              decoration : InputDecoration(
                hintText  : 'Rechercher par titre ou description...',
                hintStyle : TextStyle(color: Colors.white.withValues(alpha:0.6)),
                prefixIcon: Icon(Icons.search_rounded,
                  color: Colors.white.withValues(alpha:0.7)),
                suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon : const Icon(Icons.clear_rounded, color: Colors.white70),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                        _load(reset: true);
                      })
                  : null,
                filled     : true,
                fillColor  : Colors.white.withValues(alpha:0.15),
                border     : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide  : BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) {
                setState(() => _search = v);
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_search == v) _load(reset: true);
                });
              },
            ),
          ),

          // ── Filtres statut ──────────────────────────────────────
          Container(
            height    : 48,
            color     : Colors.white,
            child     : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount      : _statusFilters.length,
              itemBuilder    : (_, i) {
                final f   = _statusFilters[i];
                final sel = _status == f['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child  : FilterChip(
                    label    : Text(f['label']!),
                    selected : sel,
                    onSelected: (_) {
                      setState(() => _status = f['key']!);
                      _load(reset: true);
                    },
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color     : sel ? Colors.white : AppColors.textSecondary,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      fontSize  : 12,
                    ),
                    padding        : const EdgeInsets.symmetric(horizontal: 4),
                    backgroundColor: const Color(0xFFF0F4F8),
                    side           : BorderSide.none,
                    visualDensity  : VisualDensity.compact,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EDF2)),

          // ── Liste ───────────────────────────────────────────────
          Expanded(
            child: _items.isEmpty && !_loading
              ? EmptyState(
                  icon    : Icons.inbox_rounded,
                  title   : 'Aucune réclamation',
                  subtitle: _search.isNotEmpty
                    ? 'Aucun résultat pour "$_search"'
                    : 'Aucune réclamation dans cette catégorie.',
                )
              : ListView.builder(
                  controller : _scrollCtrl,
                  padding    : const EdgeInsets.all(16),
                  itemCount  : _items.length + (_hasMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child  : Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    return ComplaintCard(
                      complaint: _items[i],
                      showUser : true,
                      onTap    : () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DetailDirectionScreen(
                            complaint: _items[i])));
                        _load(reset: true);
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
