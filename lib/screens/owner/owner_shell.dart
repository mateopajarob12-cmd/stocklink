import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../app_state.dart';
import '../../models.dart';
import '../services/api_service.dart'; 

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});
  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _tab = 0;
  final AppState _state = AppState.instance;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onChange);
  }

  @override
  void dispose() {
    _state.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final pending = _state.pendingApprovalsCount;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _tab,
        children: const [
          _HomeTab(),
          _BusinessesTab(),
          _TeamTab(),
          _ApprovalsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard, color: AppColors.primary),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: AppColors.primary),
            label: 'Sucursales',
          ),
          const NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups, color: AppColors.primary),
            label: 'Equipo',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              backgroundColor: Colors.red,
              child: const Icon(Icons.verified_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              backgroundColor: Colors.red,
              child: const Icon(Icons.verified, color: AppColors.primary),
            ),
            label: 'Aprobaciones',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TAB 1 · INICIO
// ═══════════════════════════════════════════════════════════════
class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String? _businessFilter;

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final today = s.salesToday(businessId: _businessFilter);
    final yesterday = s.salesYesterday(businessId: _businessFilter);
    final double delta = yesterday == 0
        ? 0.0
        : ((today - yesterday) / yesterday) * 100;
    final tickets = s.ticketsToday(businessId: _businessFilter);
    final avg = s.avgTicketToday(businessId: _businessFilter);
    final low = _businessFilter == null
        ? s.businesses
              .expand((b) => s.inventory[b.id] ?? [])
              .where((p) => p.isLowStock)
              .length
        : (s.inventory[_businessFilter] ?? [])
              .where((p) => p.isLowStock)
              .length;

    final week = s.salesLastNDays(businessId: _businessFilter, days: 7);
    final categories = s.salesByCategory(businessId: _businessFilter, days: 7);
    final hours = s.salesByHour(businessId: _businessFilter);
    final top = s.topProducts(businessId: _businessFilter, days: 7, limit: 4);

    final goal = _businessFilter == null
        ? s.dailyGoals.values.fold(0.0, (a, b) => a + b)
        : (s.dailyGoals[_businessFilter] ?? 0);
    final goalPct = goal == 0 ? 0.0 : (today / goal).clamp(0.0, 1.0);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _Header(
            title: 'Panel de Propietario', // <--- CORREGIDO
            subtitle: _businessFilter == null
                ? 'Consolidado general de sucursales'
                : s.businesses.firstWhere((b) => b.id == _businessFilter).name,
            businesses: s.businesses,
            selectedId: _businessFilter,
            onChange: (v) => setState(() => _businessFilter = v),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _GoalCard(
              current: today,
              goal: goal,
              pct: goalPct,
              delta: delta,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.receipt_long,
                    label: 'Tickets hoy',
                    value: '$tickets',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.trending_up,
                    label: 'Ticket promedio',
                    value: '\$${avg.toStringAsFixed(0)}',
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'Productos totales',
                    value: '${_totalProducts(s)}',
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'Stock bajo',
                    value: '$low',
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _SectionTitle(
            title: 'Ventas últimos 7 días',
            trailing:
                'Total: \$${week.fold(0.0, (a, b) => a + b).toStringAsFixed(0)}',
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _BarChart(
              values: week,
              labels: _weekdayLabels(7),
              color: AppColors.primary,
              height: 140,
            ),
          ),
        ),
        if (categories.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: _SectionTitle(title: 'Ventas por categoría (7 días)'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CategoryDonut(data: categories),
            ),
          ),
        ],
        const SliverToBoxAdapter(
          child: _SectionTitle(
            title: 'Horarios pico hoy',
            subtitle: 'Ideal para reforzar personal',
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _HourHeatmap(data: hours),
          ),
        ),
        if (top.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: _SectionTitle(title: 'Top productos (7 días)'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: top
                    .map(
                      (e) => _TopProductTile(
                        product: e.key,
                        units: e.value,
                        maxUnits: top.first.value,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  int _totalProducts(AppState s) {
    if (_businessFilter == null) {
      return s.businesses.fold(
        0,
        (sum, b) => sum + (s.inventory[b.id]?.length ?? 0),
      );
    }
    return s.inventory[_businessFilter]?.length ?? 0;
  }
}

// ═══════════════════════════════════════════════════════════════
//  TAB 2 · SUCURSALES
// ═══════════════════════════════════════════════════════════════
class _BusinessesTab extends StatelessWidget {
  const _BusinessesTab();

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final totals = s.businesses
        .map((b) => MapEntry(b, s.salesToday(businessId: b.id)))
        .toList();
    final maxTotal = totals
        .map((e) => e.value)
        .fold(0.0, (a, b) => a > b ? a : b);
    final totalGlobal = totals.fold(0.0, (a, e) => a + e.value);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Comparativo de hoy',
            subtitle: '¿Cuál sucursal está rindiendo más?',
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total consolidado',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    Text(
                      '\$${totalGlobal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...totals.map((e) {
                  final pct = maxTotal == 0 ? 0.0 : e.value / maxTotal;
                  final meta = s.dailyGoals[e.key.id] ?? 0;
                  final metaPct = meta == 0
                      ? 0.0
                      : (e.value / meta).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.storefront,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.key.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              '\$${e.value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: AppColors.background,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Meta diaria: ${(metaPct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Detalle por sucursal'),
          ...s.businesses.map((b) {
            final today = s.salesToday(businessId: b.id);
            final yest = s.salesYesterday(businessId: b.id);
            final delta = yest == 0 ? 0 : ((today - yest) / yest) * 100;
            final low = (s.inventory[b.id] ?? [])
                .where((p) => p.isLowStock)
                .length;
            final team = s.encargados
                .where((e) => e.businessId == b.id)
                .toList();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (b.active)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 18,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _miniKpi(
                        'Hoy',
                        '\$${today.toStringAsFixed(0)}',
                        deltaColor: delta >= 0 ? Colors.green : Colors.red,
                        delta:
                            '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}%',
                      ),
                      _miniKpi('Stock bajo', '$low', warn: low > 0),
                      _miniKpi('Equipo', '${team.length}'),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _miniKpi(
    String label,
    String value, {
    String? delta,
    Color? deltaColor,
    bool warn = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: warn ? Colors.red.shade400 : AppColors.textDark,
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: 4),
                Text(
                  delta,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: deltaColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TAB 3 · EQUIPO
// ═══════════════════════════════════════════════════════════════
class _TeamTab extends StatelessWidget {
  const _TeamTab();

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(
          title: 'Gestión de Encargados',
          subtitle: 'Actividad y monitoreo en tiempo real',
        ),
        ...s.encargados.map((e) {
          final business = s.businesses.firstWhere((b) => b.id == e.businessId);
          final todaySales = s.salesByEncargado(e.name, days: 1);
          final todayTickets = s.ticketsByEncargado(e.name, days: 1);
          final anomalies = s.detectAnomalies(e);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                          child: Text(
                            e.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: e.online
                                  ? Colors.green
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${business.name} · ${_lastSeen(e.lastActive)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${todaySales.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _chip(Icons.receipt_long, '$todayTickets tickets hoy'),
                    const SizedBox(width: 8),
                    _chip(Icons.phone, e.phone),
                  ],
                ),
                if (anomalies.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...anomalies.map(
                    (a) => Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology_alt,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              a,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        const _SectionTitle(
          title: 'Auditoría reciente',
          subtitle: 'Últimas acciones registradas',
        ),
        ...s.auditEvents
            .take(10)
            .map(
              (ev) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: ev.severity == AuditSeverity.warning
                      ? Border.all(color: Colors.orange.shade200)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      ev.severity == AuditSeverity.warning
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      size: 18,
                      color: ev.severity == AuditSeverity.warning
                          ? Colors.orange.shade700
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ev.action,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${ev.encargadoName} · ${_timeAgo(ev.time)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  static Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  static String _lastSeen(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'En línea ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} d';
  }

  static String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'Hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return 'Hace ${diff.inDays}d';
  }
}

// ═══════════════════════════════════════════════════════════════
//  TAB 4 · APROBACIONES
// ═══════════════════════════════════════════════════════════════
class _ApprovalsTab extends StatelessWidget {
  const _ApprovalsTab();

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final pending = s.pendingApprovals;
    final history = s.approvals
        .where((a) => a.status != ApprovalStatus.pending)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(
          title: 'Pendientes por aprobar',
          subtitle: 'Tu encargado necesita tu visto bueno',
        ),
        if (pending.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Todo al día. No hay solicitudes pendientes.'),
                ),
              ],
            ),
          )
        else
          ...pending.map(
            (r) => _ApprovalCard(
              request: r,
              onApprove: () {
                s.approveRequest(r.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Aprobado: ${r.description}'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              onReject: () {
                s.rejectRequest(r.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Rechazado: ${r.description}'),
                    backgroundColor: Colors.red.shade400,
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        if (history.isNotEmpty) ...[
          const _SectionTitle(title: 'Historial de decisiones'),
          ...history.map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    r.status == ApprovalStatus.approved
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: r.status == ApprovalStatus.approved
                        ? AppColors.primary
                        : Colors.red.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.description,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${r.encargadoName} · ${r.type.label}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${r.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final ApprovalRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final business = s.businesses.firstWhere((b) => b.id == request.businessId);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  request.type.icon,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${request.type.label} · ${request.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${request.encargadoName} · ${business.name}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${request.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.description,
            style: const TextStyle(fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  label: const Text(
                    'Rechazar',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text(
                    'Aprobar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  WIDGETS COMPARTIDOS
// ═══════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Business> businesses;
  final String? selectedId;
  final ValueChanged<String?> onChange;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.businesses,
    required this.selectedId,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar Sesión',
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () {
                  // Cerramos sesión (limpia el token) y volvemos al inicio
                  ApiService.cerrarSesion(); 
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selectedId,
                isExpanded: true,
                dropdownColor: AppColors.primaryDark,
                icon: const Icon(Icons.expand_more, color: Colors.white),
                hint: const Text(
                  'Todas las sucursales',
                  style: TextStyle(color: Colors.white),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Todas las sucursales',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ...businesses.map(
                    (b) => DropdownMenuItem<String?>(
                      value: b.id,
                      child: Text(
                        b.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
                onChanged: onChange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final double current;
  final double goal;
  final double pct;
  final double delta;

  const _GoalCard({
    required this.current,
    required this.goal,
    required this.pct,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final up = delta >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_money, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Ventas de hoy',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: up ? Colors.green.shade500 : Colors.red.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      up ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${delta.abs().toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '\$${current.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Meta diaria \$${goal.toStringAsFixed(0)} · ${(pct * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailing;
  const _SectionTitle({required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double height;

  const _BarChart({
    required this.values,
    required this.labels,
    required this.color,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = values.fold(0.0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(values.length, (i) {
            final v = values[i];
            final h = maxV == 0 ? 0.0 : (v / maxV) * (height - 40);
            final isToday = i == values.length - 1;
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    v == 0 ? '' : '\$${(v / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isToday ? AppColors.primary : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: h.clamp(4.0, height - 40),
                    decoration: BoxDecoration(
                      color: isToday ? color : color.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? AppColors.primary : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _CategoryDonut extends StatelessWidget {
  final Map<String, double> data;
  const _CategoryDonut({required this.data});

  static const _palette = [
    AppColors.primary,
    AppColors.accent,
    Color(0xFF6B4F9E),
    Color(0xFF3B82F6),
    Color(0xFFEF4444),
    Color(0xFF10B981),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (a, e) => a + e.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(120, 120),
                  painter: _DonutPainter(
                    values: entries.map((e) => e.value).toList(),
                    colors: List.generate(
                      entries.length,
                      (i) => _palette[i % _palette.length],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '\$${(total / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(entries.length, (i) {
                final e = entries[i];
                final pct = total == 0 ? 0.0 : (e.value / total) * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _palette[i % _palette.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          e.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;
    const stroke = 16.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    double start = -pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.values != values || old.colors != colors;
}

class _HourHeatmap extends StatelessWidget {
  final Map<int, double> data;
  const _HourHeatmap({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxV = data.values.fold(0.0, (a, b) => a > b ? a : b);
    const startHour = 8;
    const endHour = 21;
    final hours = List.generate(endHour - startHour + 1, (i) => startHour + i);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: hours.map((h) {
              final v = data[h] ?? 0;
              final intensity = maxV == 0 ? 0.0 : (v / maxV);
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      height: 40 + intensity * 40,
                      decoration: BoxDecoration(
                        color: intensity == 0
                            ? AppColors.background
                            : AppColors.primary.withOpacity(
                                0.25 + intensity * 0.75,
                              ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${h}h',
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los bloques más oscuros son tus horas de mayor facturación.',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _TopProductTile extends StatelessWidget {
  final Product product;
  final int units;
  final int maxUnits;
  const _TopProductTile({
    required this.product,
    required this.units,
    required this.maxUnits,
  });

  @override
  Widget build(BuildContext context) {
    final pct = maxUnits == 0 ? 0.0 : units / maxUnits;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_drink, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: AppColors.background,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$units u.',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _weekdayLabels(int days) {
  const names = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  final today = DateTime.now().weekday;
  return List.generate(days, (i) {
    final day = days - 1 - i;
    final wd = ((today - day - 1) % 7 + 7) % 7;
    return names[wd];
  });
}