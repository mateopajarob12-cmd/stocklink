DROP DATABASE IF EXISTS stocklink;
CREATE DATABASE stocklink;
USE stocklink;

CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    contrasena VARCHAR(255) NOT NULL,
    rol ENUM('dueño', 'encargado') NOT NULL
);

CREATE TABLE negocios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    dueño_id INT NOT NULL,
    FOREIGN KEY (dueño_id) REFERENCES usuarios(id)
);

CREATE TABLE productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    negocio_id INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    categoria VARCHAR(100),
    stock INT NOT NULL DEFAULT 0,
    stock_minimo INT NOT NULL DEFAULT 0,
    precio DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (negocio_id) REFERENCES negocios(id)
);

CREATE TABLE ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (producto_id) REFERENCES productos(id)
);

INSERT INTO usuarios (nombre, correo, contrasena, rol) VALUES
('Luis Rodríguez', 'luis@stocklink.com', '12345', 'dueño'),
('Mateo Pájaro', 'mateo@stocklink.com', '12345', 'encargado');

INSERT INTO negocios (nombre, dueño_id) VALUES
('Tienda Central', 1),
('Licorera', 1);

INSERT INTO productos (negocio_id, nombre, categoria, stock, stock_minimo, precio) VALUES
(1, 'Coca-Cola 400ml', 'Bebidas', 50, 10, 3500),
(1, 'Agua Cristal 600ml', 'Bebidas', 80, 15, 2000),
(1, 'Arroz Diana 500g', 'Abarrotes', 40, 8, 3200),
(1, 'Aceite Girasol 1L', 'Abarrotes', 25, 5, 9800),
(1, 'Jabón Rey 300g', 'Aseo', 30, 10, 2500),
(1, 'Leche Alpina 1L', 'Lácteos', 20, 5, 4200),
(1, 'Pan Bimbo Tajado', 'Panadería', 15, 5, 6500),
(1, 'Huevos AA x30', 'Abarrotes', 12, 3, 18000),
(1, 'Café Águila Roja 500g', 'Abarrotes', 18, 4, 15500),
(1, 'Azúcar Manuelita 1kg', 'Abarrotes', 35, 8, 4500),
(1, 'Sal Refisal 500g', 'Abarrotes', 40, 10, 1800),
(1, 'Papas Margarita 30g', 'Snacks', 60, 15, 1900),
(1, 'Chocolatina Jet', 'Snacks', 70, 20, 1500),
(1, 'Detergente Fab 500g', 'Aseo', 22, 5, 5200),
(1, 'Papel Higiénico Familia x4', 'Aseo', 28, 6, 6800),
(1, 'Crema Dental Colgate', 'Aseo', 32, 8, 5900),
(1, 'Shampoo Savital 350ml', 'Aseo', 18, 4, 8900),
(1, 'Gaseosa Postobón 1.5L', 'Bebidas', 24, 6, 5500),
(1, 'Atún Van Camps', 'Abarrotes', 26, 6, 4900),
(1, 'Pasta La Muñeca 500g', 'Abarrotes', 33, 8, 2800),
(2, 'Aguardiente Antioqueño 750ml', 'Licores', 30, 8, 32000),
(2, 'Ron Medellín Añejo 750ml', 'Licores', 25, 6, 45000),
(2, 'Whisky Old Parr 750ml', 'Licores', 10, 3, 95000),
(2, 'Vodka Smirnoff 750ml', 'Licores', 15, 4, 58000),
(2, 'Tequila José Cuervo 750ml', 'Licores', 8, 2, 78000),
(2, 'Cerveza Águila Lata', 'Cervezas', 120, 30, 2800),
(2, 'Cerveza Club Colombia Lata', 'Cervezas', 90, 25, 3200),
(2, 'Cerveza Corona 355ml', 'Cervezas', 60, 15, 4800),
(2, 'Cerveza Poker Botella', 'Cervezas', 100, 25, 2600),
(2, 'Vino Santa Helena Tinto', 'Vinos', 20, 5, 28000),
(2, 'Vino Concha y Toro Reserva', 'Vinos', 18, 5, 42000),
(2, 'Champaña Baron B', 'Vinos', 12, 3, 65000),
(2, 'Ginebra Bombay Sapphire 750ml', 'Licores', 9, 2, 89000),
(2, 'Old Parr 12 años 750ml', 'Licores', 6, 2, 165000),
(2, 'Aguardiente Néctar Verde 750ml', 'Licores', 28, 7, 30000),
(2, 'Ron Viejo de Caldas 750ml', 'Licores', 22, 6, 38000),
(2, 'Cola & Pola Lata', 'Mezcladores', 80, 20, 2500),
(2, 'Agua Tónica Schweppes', 'Mezcladores', 50, 12, 3800),
(2, 'Hielo Bolsa 5kg', 'Otros', 40, 10, 6000),
(2, 'Cigarrillos Marlboro Box', 'Otros', 45, 10, 8500);

INSERT INTO ventas (producto_id, cantidad, fecha) VALUES
(1, 3, '2026-09-01 09:15:00'),
(2, 5, '2026-09-01 10:30:00'),
(3, 2, '2026-09-02 11:00:00'),
(6, 4, '2026-09-02 14:45:00'),
(12, 6, '2026-09-03 08:20:00'),
(9, 2, '2026-09-03 09:50:00'),
(21, 4, '2026-09-04 18:10:00'),
(26, 12, '2026-09-04 19:30:00'),
(28, 8, '2026-09-05 20:00:00'),
(22, 2, '2026-09-05 21:15:00'),
(35, 15, '2026-09-06 17:40:00'),
(23, 1, '2026-09-06 22:00:00'),
(37, 6, '2026-09-07 16:20:00'),
(31, 3, '2026-09-07 19:00:00');