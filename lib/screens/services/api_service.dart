import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models.dart';

class ApiService {
  // URL de la nube en Render
  static const String baseUrl = 'https://stocklink-api-x46s.onrender.com/api';
  
  static String? _token;

  // Función para limpiar el token al cerrar sesión
  static void cerrarSesion() {
    _token = null;
  }

  // Login devuelve el ROL (String) o nulo si falla
  Future<String?> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _token = data['access_token'];
      print("✅ TOKEN GUARDADO EN FLUTTER: $_token");
      return data['rol']; // Devuelve 'propietario' o 'encargado'
    }
    print("❌ LOGIN FALLÓ: ${res.statusCode}");
    return null; // Si falla
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<List<Product>> fetchProducts() async {
    print("🔍 ENVIANDO TOKEN A LA API: $_token");
    
    final res = await http.get(Uri.parse('$baseUrl/products'), headers: _headers);
    
    print("📦 RESPUESTA DE LA API (Status): ${res.statusCode}");

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
    throw Exception('Error al cargar productos o token inválido: ${res.statusCode}');
  }

  Future<void> createProduct(Product p) async {
    final res = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: _headers,
      body: jsonEncode({
        'code': p.code,
        'name': p.name,
        'category': p.category,
        'stock': p.stock,
        'minStock': p.minStock,
        'price': p.price,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('No se pudo guardar el producto (${res.statusCode})');
    }
  }

  Future<void> registerSale(double total, String encargado) async {
    final res = await http.post(
      Uri.parse('$baseUrl/sales'),
      headers: _headers,
      body: jsonEncode({'total': total, 'encargado': encargado}),
    );
    if (res.statusCode != 200) {
      throw Exception('Error al registrar la venta');
    }
  }
}