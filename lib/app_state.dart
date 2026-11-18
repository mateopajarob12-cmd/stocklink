// lib/app_state.dart
// Estado global en memoria de StockLink.
// El encargado (web) escribe aquí; el dueño (móvil) lee de aquí.
// Más adelante este archivo se reemplaza por llamadas al backend real.
import 'screens/services/api_service.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  AppState._() {
    _seedSales();
    _seedAudit();
  }
  static final AppState instance = AppState._();
    // Instancia del servicio de la API
  final ApiService _api = ApiService();

  // Función para traer los productos de XAMPP
  Future<void> cargarProductosDesdeApi() async {
    try {
      final productos = await _api.fetchProducts();
      
      // Esto reemplaza los productos falsos por los de la base de datos real
      inventory[currentBusinessId] = productos; 
      
      notifyListeners();
    } catch (e) {
      print("Error cargando productos: $e");
    }
  }

  // ── Negocio activo (para el encargado web) ──
  String currentBusinessId = 'b1';

  // ── Sucursales ──
  final List<Business> businesses = [
    const Business(id: 'b1', name: 'Tienda Central', location: 'Centro'),
    const Business(id: 'b2', name: 'Sucursal Norte', location: 'Norte'),
  ];

  // ── Meta diaria por sucursal (para gamificar) ──
  final Map<String, double> dailyGoals = {
    'b1': 500000,
    'b2': 250000,
  };

  // ── Inventario por negocio ──
  // ── Inventario por negocio (Inicia vacío, la API lo llena) ──
  final Map<String, List<Product>> inventory = {
    'b1': [],
    'b2': [],
  };

  // ── Encargados ──
  final List<Encargado> encargados = [
    Encargado(
      id: 'e1', name: 'Ana Gómez', businessId: 'b1',
      phone: '+57 300 111 2233',
      hiredAt: DateTime.now().subtract(const Duration(days: 180)),
      lastActive: DateTime.now().subtract(const Duration(minutes: 2)),
      online: true,
    ),
    Encargado(
      id: 'e2', name: 'Carlos Ruiz', businessId: 'b1',
      phone: '+57 300 444 5566',
      hiredAt: DateTime.now().subtract(const Duration(days: 60)),
      lastActive: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Encargado(
      id: 'e3', name: 'María Torres', businessId: 'b2',
      phone: '+57 300 777 8899',
      hiredAt: DateTime.now().subtract(const Duration(days: 90)),
      lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
      online: true,
    ),
  ];

  // ── Ventas e historial ──
  final List<Sale> sales = [];

  // ── Aprobaciones ──
  final List<ApprovalRequest> approvals = [
    ApprovalRequest(
      id: 'A-101', type: ApprovalType.discount, businessId: 'b1',
      encargadoId: 'e1', encargadoName: 'Ana Gómez',
      description: 'Descuento 15% en compra mayorista',
      amount: 18500,
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    ApprovalRequest(
      id: 'A-102', type: ApprovalType.cancel, businessId: 'b1',
      encargadoId: 'e1', encargadoName: 'Ana Gómez',
      description: 'Anular venta V-2043 (cliente arrepentido)',
      amount: 34000,
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
    ),
    ApprovalRequest(
      id: 'A-103', type: ApprovalType.restock, businessId: 'b1',
      encargadoId: 'e2', encargadoName: 'Carlos Ruiz',
      description: 'Reponer 24 Coca-Cola (se agota hoy)',
      amount: 156000,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ApprovalRequest(
      id: 'A-104', type: ApprovalType.expense, businessId: 'b2',
      encargadoId: 'e3', encargadoName: 'María Torres',
      description: 'Retiro para pago de domicilio',
      amount: 25000,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    ApprovalRequest(
      id: 'A-090', type: ApprovalType.discount, businessId: 'b1',
      encargadoId: 'e1', encargadoName: 'Ana Gómez',
      description: 'Descuento 10% cliente frecuente',
      amount: 5000,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: ApprovalStatus.approved,
    ),
  ];

  // ── Auditoría ──
  final List<AuditEvent> auditEvents = [];

  // ═══════════════════════════════════════════════════════════
  //  INVENTARIO (interfaz usada por el admin web)
  // ═══════════════════════════════════════════════════════════
  List<Product> get products => inventory[currentBusinessId] ?? [];

  List<Product> get lowStockProducts =>
      products.where((p) => p.isLowStock).toList();

  Product? findByCode(String code) {
    final c = code.trim();
    for (final p in products) {
      if (p.code == c) return p;
    }
    return null;
  }

  void addProduct(Product p) {
    inventory.putIfAbsent(currentBusinessId, () => []).add(p);
    _log(currentBusinessId, 'Encargado Demo',
        'Agregó producto: ${p.name}', AuditSeverity.normal);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  VENTAS
  // ═══════════════════════════════════════════════════════════
  List<Sale> salesOfBusiness(String id) =>
      sales.where((s) => s.businessId == id).toList();

  Sale registerSale({
    required List<SaleItem> items,
    required String businessId,
    required String encargado,
  }) {
    if (items.isEmpty) throw Exception('La venta está vacía');
    for (final it in items) {
      if (it.product.stock < it.quantity) {
        throw Exception('Stock insuficiente: ${it.product.name}');
      }
    }
    for (final it in items) {
      it.product.stock -= it.quantity;
    }
    final sale = Sale(
      id: 'V-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      businessId: businessId,
      time: DateTime.now(),
      items: items,
      encargado: encargado,
    );
    sales.insert(0, sale);
    _log(businessId, encargado,
        'Registró venta ${sale.id} · \$${sale.total.toStringAsFixed(0)}',
        AuditSeverity.normal);
    notifyListeners();
    return sale;
  }

  void undoLastSale({String? businessId}) {
    final bid = businessId ?? currentBusinessId;
    final idx = sales.indexWhere((s) => s.businessId == bid);
    if (idx == -1) return;
    final last = sales.removeAt(idx);
    for (final it in last.items) {
      it.product.stock += it.quantity;
    }
    _log(bid, 'Encargado Demo',
        'Deshizo venta ${last.id}', AuditSeverity.warning);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  APROBACIONES
  // ═══════════════════════════════════════════════════════════
  List<ApprovalRequest> get pendingApprovals =>
      approvals.where((a) => a.status == ApprovalStatus.pending).toList();

  int get pendingApprovalsCount => pendingApprovals.length;

  void approveRequest(String id) {
    final r = approvals.firstWhere((a) => a.id == id);
    r.status = ApprovalStatus.approved;
    _log(r.businessId, 'Dueño',
        'Aprobó ${r.type.label.toLowerCase()}: ${r.description}',
        AuditSeverity.normal);
    notifyListeners();
  }

  void rejectRequest(String id) {
    final r = approvals.firstWhere((a) => a.id == id);
    r.status = ApprovalStatus.rejected;
    _log(r.businessId, 'Dueño',
        'Rechazó ${r.type.label.toLowerCase()}: ${r.description}',
        AuditSeverity.warning);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  MÉTRICAS PARA EL DUEÑO
  // ═══════════════════════════════════════════════════════════
  double salesToday({String? businessId}) {
    final now = DateTime.now();
    return sales
        .where((s) => businessId == null || s.businessId == businessId)
        .where((s) =>
            s.time.year == now.year &&
            s.time.month == now.month &&
            s.time.day == now.day)
        .fold(0.0, (sum, s) => sum + s.total);
  }

  double salesYesterday({String? businessId}) {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return sales
        .where((s) => businessId == null || s.businessId == businessId)
        .where((s) =>
            s.time.year == y.year &&
            s.time.month == y.month &&
            s.time.day == y.day)
        .fold(0.0, (sum, s) => sum + s.total);
  }

  int ticketsToday({String? businessId}) {
    final now = DateTime.now();
    return sales
        .where((s) => businessId == null || s.businessId == businessId)
        .where((s) =>
            s.time.year == now.year &&
            s.time.month == now.month &&
            s.time.day == now.day)
        .length;
  }

  double avgTicketToday({String? businessId}) {
    final n = ticketsToday(businessId: businessId);
    if (n == 0) return 0;
    return salesToday(businessId: businessId) / n;
  }

  /// Ventas por día para gráfica (últimos N días).
  List<double> salesLastNDays({String? businessId, int days = 7}) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final day = now.subtract(Duration(days: days - 1 - i));
      return sales
          .where((s) => businessId == null || s.businessId == businessId)
          .where((s) =>
              s.time.year == day.year &&
              s.time.month == day.month &&
              s.time.day == day.day)
          .fold(0.0, (sum, s) => sum + s.total);
    });
  }

  /// Ventas por categoría en los últimos N días.
  Map<String, double> salesByCategory({String? businessId, int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final map = <String, double>{};
    for (final s in sales) {
      if (businessId != null && s.businessId != businessId) continue;
      if (s.time.isBefore(cutoff)) continue;
      for (final it in s.items) {
        map[it.product.category] =
            (map[it.product.category] ?? 0) + it.subtotal;
      }
    }
    return map;
  }

  /// Horas con más ventas hoy (0-23).
  Map<int, double> salesByHour({String? businessId}) {
    final now = DateTime.now();
    final map = <int, double>{};
    for (final s in sales) {
      if (businessId != null && s.businessId != businessId) {
        continue;
      }
      if (s.time.year != now.year ||
          s.time.month != now.month ||
          s.time.day != now.day) {
        continue;
      }
      map[s.time.hour] = (map[s.time.hour] ?? 0) + s.total;
    }
    return map;
  }

  /// Top productos (por unidades vendidas) en últimos N días.
  List<MapEntry<Product, int>> topProducts({
    String? businessId,
    int days = 7,
    int limit = 5,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final counts = <String, int>{};
    final productsByCode = <String, Product>{};
    for (final s in sales) {
      if (businessId != null && s.businessId != businessId) continue;
      if (s.time.isBefore(cutoff)) continue;
      for (final it in s.items) {
        counts[it.product.code] = (counts[it.product.code] ?? 0) + it.quantity;
        productsByCode[it.product.code] = it.product;
      }
    }
    final list = counts.entries
        .map((e) => MapEntry(productsByCode[e.key]!, e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(limit).toList();
  }

  // Ventas por encargado (por defecto hoy).
  double salesByEncargado(String name, {int days = 1}) {
    final startOfDay = DateTime.now()
        .subtract(Duration(days: days - 1));
    final from = DateTime(startOfDay.year, startOfDay.month, startOfDay.day);
    return sales
        .where((s) => s.encargado == name && s.time.isAfter(from))
        .fold(0.0, (sum, s) => sum + s.total);
  }

  int ticketsByEncargado(String name, {int days = 1}) {
    final startOfDay = DateTime.now()
        .subtract(Duration(days: days - 1));
    final from = DateTime(startOfDay.year, startOfDay.month, startOfDay.day);
    return sales
        .where((s) => s.encargado == name && s.time.isAfter(from))
        .length;
  }

  /// Detección de anomalías simples — compara la actividad de hoy con el
  /// promedio de los últimos 7 días.
  List<String> detectAnomalies(Encargado e) {
    final flags = <String>[];
    final today = salesByEncargado(e.name, days: 1);
    final week = salesByEncargado(e.name, days: 7);
    final avgDay = week / 7;
    if (avgDay > 0 && today > avgDay * 2 && today > 100000) {
      flags.add('Ventas hoy 2× por encima del promedio');
    }
    if (e.name == 'Ana Gómez' && today > 0) {
      flags.add('3 anulaciones hoy (promedio: 0.2)');
    }
    return flags;
  }

  // ═══════════════════════════════════════════════════════════
  //  SEED DATA
  // ═══════════════════════════════════════════════════════════
  void _seedSales() {
    final rnd = Random(42);
    final now = DateTime.now();
    final hourPool = [8, 9, 10, 11, 11, 12, 12, 13, 14, 15, 16, 17, 18, 19, 19, 20];

    for (int d = 6; d >= 0; d--) {
      final day = now.subtract(Duration(days: d));
      final isWeekend = day.weekday >= 6;
      final count = (isWeekend ? 18 : 12) + rnd.nextInt(6);

      for (int i = 0; i < count; i++) {
        final hour = hourPool[rnd.nextInt(hourPool.length)];
        final time = DateTime(
            day.year, day.month, day.day, hour, rnd.nextInt(60));
                if (time.isAfter(now)) {
          continue;
        }

        final bId = rnd.nextBool() ? 'b1' : 'b2';
        final inv = inventory[bId]!;
                if (inv.isEmpty) continue; // Evita errores si el inventario está vacío
        final encs = encargados.where((e) => e.businessId == bId).toList();
        final enc = encs[rnd.nextInt(encs.length)];

        final numItems = 1 + rnd.nextInt(3);
        final picked = <Product>{};
        int safety = 0;
        while (picked.length < numItems && safety++ < 20) {
          picked.add(inv[rnd.nextInt(inv.length)]);
        }

        final items = picked
            .map((p) =>
                SaleItem(product: p, quantity: 1 + rnd.nextInt(3)))
            .toList();

        sales.add(Sale(
          id: 'V-${1000 + sales.length + (d * 100)}',
          businessId: bId,
          time: time,
          items: items,
          encargado: enc.name,
        ));
      }
    }
    sales.sort((a, b) => b.time.compareTo(a.time));
  }

  void _seedAudit() {
    auditEvents.addAll([
      AuditEvent(
        id: 'L-${DateTime.now().millisecondsSinceEpoch}',
        businessId: 'b1',
        encargadoName: 'Ana Gómez',
        action: 'Inició sesión en el punto de venta',
        time: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      AuditEvent(
        id: 'L-${DateTime.now().millisecondsSinceEpoch + 1}',
        businessId: 'b1',
        encargadoName: 'Ana Gómez',
        action: 'Solicitó descuento del 15%',
        time: DateTime.now().subtract(const Duration(minutes: 8)),
        severity: AuditSeverity.warning,
      ),
      AuditEvent(
        id: 'L-${DateTime.now().millisecondsSinceEpoch + 2}',
        businessId: 'b2',
        encargadoName: 'María Torres',
        action: 'Cerró caja del turno mañana',
        time: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ]);
  }

  void _log(String bId, String who, String action,
      [AuditSeverity sev = AuditSeverity.normal]) {
    auditEvents.insert(
      0,
      AuditEvent(
        id: 'L-${DateTime.now().microsecondsSinceEpoch}',
        businessId: bId,
        encargadoName: who,
        action: action,
        time: DateTime.now(),
        severity: sev,
      ),
    );
  }
}