# StockLink — App (Flutter)

Aplicación de gestión de inventario y ventas para pequeños comercios, con vistas distintas para **encargado** y **propietario**. Proyecto de Desarrollo de Software (Equipo 2).
La app consume la API: [`stocklink-api`](https://github.com/mateopajarob12-cmd/stocklink-api).

**Integrantes:** Luis Miguel Rodríguez Vega · Mateo Enrique Pájaro Bossio
**Docente:** Marco Antonio Almanza Ibarra

## Estado del proyecto

Prototipo académico. Según el SRS v2.0, de 20 requerimientos: **1 cumplido, 13 parciales y 6 no alcanzados**.

| Funciona | Parcial | No alcanzado |
|---|---|---|
| Login con JWT y dos roles. Consulta y creación de productos. Registro de ventas con validación de stock en el servidor. | Dashboard del propietario, reportes, deshacer venta y auditoría (datos en memoria). Alertas de stock bajo (solo visuales). | Multi-negocio, cuentas de encargado reales, escaneo con cámara, modo offline y exportar PDF/Excel. |

## Funcionalidades

- **Encargado:** inventario (listar y crear productos), punto de venta por código y historial.
- **Propietario:** dashboard con indicadores y gráficos, sucursales, equipo y aprobaciones (estos últimos con datos de demostración).

## Instalación y prueba

**Requisitos:** Flutter SDK instalado. La app usa la API desplegada en Render, así que **no hace falta levantar backend local**.

```bash
flutter pub get
flutter run -d chrome   # o -d windows
```

La primera petición puede tardar unos segundos si la API estaba dormida. Documentación de la API: https://stocklink-api-x46s.onrender.com/docs

| Rol | Correo | Contraseña |
|---|---|---|
| Propietario | `propietario@stocklink.com` | `123` |
| Encargado | `encargado@stocklink.com` | `123` |

Son credenciales de demostración definidas en el código de la API.

## Estructura

```
lib/
├── main.dart            # Punto de entrada
├── app_state.dart       # Estado en memoria (métricas, sucursales, aprobaciones)
├── models.dart          # Modelos: Product, Sale, etc.
├── theme.dart
└── screens/
    ├── login_screen.dart
    ├── admin/           # Vista del encargado
    ├── owner/           # Vista del propietario
    └── services/        # api_service.dart (cliente HTTP de la API)
```

## Código legado

`server.js` y `database.sql` (raíz) son del diseño inicial (Node/Express) y **no se usan** en la versión final.

## Limitaciones conocidas

Usuarios y clave JWT fijos en la API, dashboard calculado con datos en memoria y sin modo offline. Detalle completo en el SRS v2.0.
