
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models.dart';

class ApiService {
  // Si pruebas en Chrome usa 127.0.0.1. Si usas emulador de Android usa 10.0.2.2
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Traer productos de la base de datos
  Future<List<Product>> fetchProducts() async {
    final res = await http.get(Uri.parse('$baseUrl/products'));
    if (res.statusCode == 200) {
      List data = jsonDecode(res.body);
      return data.map((e) => Product(
        code: e['code'],
        name: e['name'],
        category: e['category'],
        stock: e['stock'],
        minStock: e['minStock'],
        price: e['price'].toDouble(),
      )).toList();
    }
    throw Exception('Error al cargar productos');
  }

  // Enviar una venta a la base de datos
  Future<void> registerSale(double total, String encargado) async {
    final res = await http.post(
      Uri.parse('$baseUrl/sales'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'total': total,
        'encargado': encargado,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Error al registrar la venta');
    }
  }
}