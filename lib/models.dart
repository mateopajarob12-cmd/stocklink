// lib/models.dart
// Modelos base de StockLink.
// En este paso solo viven aquí los que NO dependen de otros modelos.
// Product, Sale y SaleItem se agregan en pasos siguientes.

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
// Sucursales / negocios del dueño
// ─────────────────────────────────────────────────────────
class Business {
  final String id;
  final String name;
  final String location;
  final bool active;

  const Business({
    required this.id,
    required this.name,
    required this.location,
    this.active = true,
  });
}

// ─────────────────────────────────────────────────────────
// Encargado (empleado del dueño)
// ─────────────────────────────────────────────────────────
class Encargado {
  final String id;
  final String name;
  final String businessId;
  final String phone;
  final DateTime hiredAt;
  bool online;
  DateTime lastActive;

  Encargado({
    required this.id,
    required this.name,
    required this.businessId,
    required this.phone,
    required this.hiredAt,
    required this.lastActive,
    this.online = false,
  });
}

// ─────────────────────────────────────────────────────────
// Aprobaciones que el encargado le pide al dueño
// ─────────────────────────────────────────────────────────
enum ApprovalType { discount, cancel, restock, expense }

extension ApprovalTypeX on ApprovalType {
  String get label {
    switch (this) {
      case ApprovalType.discount:
        return 'Descuento';
      case ApprovalType.cancel:
        return 'Anulación';
      case ApprovalType.restock:
        return 'Reabastecimiento';
      case ApprovalType.expense:
        return 'Gasto / retiro';
    }
  }

  IconData get icon {
    switch (this) {
      case ApprovalType.discount:
        return Icons.percent;
      case ApprovalType.cancel:
        return Icons.cancel_outlined;
      case ApprovalType.restock:
        return Icons.local_shipping_outlined;
      case ApprovalType.expense:
        return Icons.receipt_outlined;
    }
  }
}

enum ApprovalStatus { pending, approved, rejected }

class ApprovalRequest {
  final String id;
  final ApprovalType type;
  final String businessId;
  final String encargadoId;
  final String encargadoName;
  final String description;
  final double amount;
  final DateTime createdAt;
  ApprovalStatus status;

  ApprovalRequest({
    required this.id,
    required this.type,
    required this.businessId,
    required this.encargadoId,
    required this.encargadoName,
    required this.description,
    required this.amount,
    required this.createdAt,
    this.status = ApprovalStatus.pending,
  });
}

// ─────────────────────────────────────────────────────────
// Auditoría (quién hizo qué y cuándo)
// ─────────────────────────────────────────────────────────
enum AuditSeverity { normal, warning, critical }

class AuditEvent {
  final String id;
  final String businessId;
  final String encargadoName;
  final String action;
  final DateTime time;
  final AuditSeverity severity;

  AuditEvent({
    required this.id,
    required this.businessId,
    required this.encargadoName,
    required this.action,
    required this.time,
    this.severity = AuditSeverity.normal,
  });
}

// ─────────────────────────────────────────────────────────
// Producto (usado por inventario, POS y ventas)
// ─────────────────────────────────────────────────────────
class Product {
  final String code;      // Código de barras / código de venta
  final String name;
  final String category;
  int stock;
  final int minStock;
  final double price;

  Product({
    required this.code,
    required this.name,
    required this.category,
    required this.stock,
    required this.minStock,
    required this.price,
  });

  bool get isLowStock => stock <= minStock;
}

// ─────────────────────────────────────────────────────────
// Ítem de venta (un producto + cantidad)
// ─────────────────────────────────────────────────────────
class SaleItem {
  final Product product;
  final int quantity;

  SaleItem({
    required this.product,
    required this.quantity,
  });

  double get subtotal => product.price * quantity;
}

// ─────────────────────────────────────────────────────────
// Venta completa (la que registra el POS del encargado)
// ─────────────────────────────────────────────────────────
class Sale {
  final String id;
  final String businessId;
  final DateTime time;
  final List<SaleItem> items;
  final String encargado;

  Sale({
    required this.id,
    required this.businessId,
    required this.time,
    required this.items,
    required this.encargado,
  });

  double get total => items.fold(0.0, (sum, i) => sum + i.subtotal);
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
}