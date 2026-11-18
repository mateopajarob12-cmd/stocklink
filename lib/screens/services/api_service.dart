import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static String? _token; // <--- ¡EL TRUCO ESTÁ AQUÍ! (static para que sea global)

  Future<bool> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _token = data['access_token'];
      print("✅ TOKEN GUARDADO EN FLUTTER: $_token");
      return true;
    }
    print("❌ LOGIN FALLÓ: ${res.statusCode}");
    return false;
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