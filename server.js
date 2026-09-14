require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
});

db.connect((err) => {
  if (err) {
    console.error('Error conectando a MySQL:', err.message);
    return;
  }
  console.log('Conectado a la base de datos MySQL (stocklink)');
});

// Traer todos los productos
app.get('/productos', (req, res) => {
  db.query('SELECT * FROM productos', (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: 'Error al consultar productos' });
    }
    res.json(results);
  });
});

// Agregar un producto nuevo
app.post('/productos', (req, res) => {
  const { negocio_id, nombre, categoria, stock, stock_minimo, precio } = req.body;

  if (!negocio_id || !nombre || precio === undefined) {
    return res.status(400).json({ error: 'Faltan campos obligatorios' });
  }

  const sql = 'INSERT INTO productos (negocio_id, nombre, categoria, stock, stock_minimo, precio) VALUES (?, ?, ?, ?, ?, ?)';
  const valores = [negocio_id, nombre, categoria, stock || 0, stock_minimo || 0, precio];

  db.query(sql, valores, (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: 'Error al crear el producto' });
    }
    res.status(201).json({ id: result.insertId, negocio_id, nombre, categoria, stock, stock_minimo, precio });
  });
});

app.listen(process.env.PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${process.env.PORT}`);
});