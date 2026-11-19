import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../app_state.dart';
import '../../models.dart';
import '../product_form_screen.dart';
import '../services/api_service.dart'; // <-- IMPORTANTE: Agregado

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final AppState _state = AppState.instance;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _state.addListener(_onChange);
    
    // Esto espera a que la API responda y luego refresca la pantalla
    _state.cargarProductosDesdeApi().then((_) {
      if (mounted) setState(() {});
    });
  }
  
  @override
  void dispose() {
    _state.removeListener(_onChange);
    _tab.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final low = _state.lowStockProducts.length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('StockLink · Punto de Venta'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Cerramos sesión y limpiamos el token
              ApiService.cerrarSesion(); 
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(
              icon: Icon(Icons.inventory_2_outlined),
              text: 'Inventario',
            ),
            const Tab(icon: Icon(Icons.point_of_sale), text: 'Punto de venta'),
            Tab(
              icon: const Icon(Icons.receipt_long_outlined),
              text: 'Historial${low > 0 ? ' ($low)' : ''}',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_InventoryTab(), _PosTab(), _HistoryTab()],
      ),
    );
  }
}

// ═══════════════ TAB 1: INVENTARIO ═══════════════
class _InventoryTab extends StatefulWidget {
  const _InventoryTab();
  @override
  State<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<_InventoryTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final list = _query.isEmpty
        ? state.products
        : state.products
              .where(
                (p) =>
                    p.name.toLowerCase().contains(_query.toLowerCase()) ||
                    p.code.contains(_query),
              )
              .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final created = await Navigator.of(context).push<Product>(
                  MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                );
                if (created != null) {
                  try {
                    await state.crearProducto(created);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('No se pudo guardar: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add_box_rounded, color: AppColors.primary),
              label: const Text(
                'Agregar producto',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o código...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final p = list[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: p.isLowStock
                      ? Border.all(color: Colors.red.shade300, width: 1.2)
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p.category}  ·  Código: ${p.code}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 14,
                                color: p.isLowStock
                                    ? Colors.red
                                    : Colors.black45,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Stock: ${p.stock}  (mín ${p.minStock})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: p.isLowStock
                                      ? Colors.red
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${p.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════ TAB 2: PUNTO DE VENTA ═══════════════
class _PosTab extends StatefulWidget {
  const _PosTab();
  @override
  State<_PosTab> createState() => _PosTabState();
}

class _PosTabState extends State<_PosTab> {
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();
  final Map<String, int> _cart = {};
  String? _error;
  String? _info;
  static const _currentBusinessId = 'b1';

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _addByCode() {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    final state = AppState.instance;
    final p = state.findByCode(code);
    if (p == null) {
      setState(() {
        _error = 'Producto no encontrado: $code';
        _info = null;
      });
      return;
    }
    final inCart = _cart[p.code] ?? 0;
    if (inCart + 1 > p.stock) {
      setState(() {
        _error = 'Stock insuficiente de ${p.name} (queda ${p.stock - inCart})';
        _info = null;
      });
      return;
    }
    setState(() {
      _cart[p.code] = inCart + 1;
      _error = null;
      _info = 'Agregado: ${p.name}';
      _codeController.clear();
    });
    _codeFocus.requestFocus();
  }

  void _removeItem(String code) {
    setState(() {
      final q = _cart[code] ?? 0;
      if (q <= 1) {
        _cart.remove(code);
      } else {
        _cart[code] = q - 1;
      }
    });
  }

  Future<void> _confirmSale() async {
    if (_cart.isEmpty) return;
    final state = AppState.instance;
    try {
      final items = _cart.entries
          .map(
            (e) =>
                SaleItem(product: state.findByCode(e.key)!, quantity: e.value),
          )
          .toList();
      final sale = await state.registrarVentaApi(
        items: items,
        businessId: _currentBusinessId,
        encargado: 'Encargado Demo',
      );
      if (!mounted) return;
      setState(() {
        _cart.clear();
        _error = null;
        _info =
            'Venta ${sale.id} registrada · Total \$${sale.total.toStringAsFixed(0)}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final cartEntries = _cart.entries.toList();
    double total = 0;
    for (final e in cartEntries) {
      final p = state.findByCode(e.key)!;
      total += p.price * e.value;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  focusNode: _codeFocus,
                  autofocus: true,
                  onSubmitted: (_) => _addByCode(),
                  decoration: InputDecoration(
                    hintText: 'Escanea o escribe el código del producto',
                    prefixIcon: const Icon(Icons.qr_code_scanner),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _addByCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _banner(_error!, Colors.red.shade400, Icons.error_outline),
          ),
        if (_info != null && _error == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _banner(
              _info!,
              AppColors.primary,
              Icons.check_circle_outline,
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: cartEntries.isEmpty
              ? const Center(
                  child: Text(
                    'Aún no hay productos en la venta',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cartEntries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final e = cartEntries[i];
                    final p = state.findByCode(e.key)!;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${p.code} · \$${p.price.toStringAsFixed(0)} c/u',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _removeItem(p.code),
                          ),
                          Text(
                            'x${e.value}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '\$${(p.price * e.value).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: cartEntries.isEmpty ? null : _confirmSale,
                  icon: const Icon(Icons.point_of_sale),
                  label: const Text(
                    'Confirmar venta',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _banner(String text, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════ TAB 3: HISTORIAL ═══════════════
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final sales = state.sales;

    if (sales.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Todavía no hay ventas registradas.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                state.undoLastSale();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Última venta revertida'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: const Icon(Icons.undo, color: Colors.red),
              label: const Text(
                'Deshacer última venta',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: sales.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final s = sales[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          s.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$${s.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.itemCount} ítems · ${s.encargado} · ${s.time.hour}:${s.time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const Divider(height: 16),
                    ...s.items.map(
                      (it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                it.product.name,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              'x${it.quantity}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}