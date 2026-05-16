const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const multer = require('multer');
const bodyParser = require('body-parser');
const path = require('path');


const app = express();
const PORT = 3000;


// =======================
// MIDDLEWARE
// =======================
app.use(cors());
app.use(bodyParser.json());
app.use(express.json());


// Serve images from public folder
app.use('/images', express.static('public/images'));


// =======================
// MYSQL CONNECTION
// =======================
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'password',
  database: 'database'
});


db.connect(err => {
  if (err) throw err;
  console.log('Connected to MySQL');
});


// =======================
// MULTER (IMAGE UPLOAD)
// =======================
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'public/images');
  },
  filename: (req, file, cb) => {
    const uniqueName = Date.now() + path.extname(file.originalname);
    cb(null, uniqueName);
  }
});


const upload = multer({ storage });


// =======================
// LOGIN API
// =======================
app.post('/login', (req, res) => {
  const { email, password } = req.body;


  const sql = 'SELECT * FROM users WHERE email = ? AND password = ?';


  db.query(sql, [email, password], (err, result) => {
    if (err) return res.status(500).json(err);


    if (result.length > 0) {
      res.json({ message: 'Login successful' });
    } else {
      res.status(401).json({ message: 'Invalid credentials' });
    }
  });
});


// =======================
// CREATE PRODUCT
// =======================
app.post('/products', upload.single('image'), (req, res) => {
  const { name, price } = req.body;
  const image = req.file ? req.file.filename : '';


  const sql = 'INSERT INTO products (name, price, image_url) VALUES (?, ?, ?)';


  db.query(sql, [name, price, image], (err, result) => {
    if (err) return res.status(500).json(err);


    res.json({
      message: 'Product added',
      id: result.insertId
    });
  });
});


// =======================
// READ PRODUCTS
// =======================
app.get('/products', (req, res) => {
  const sql = 'SELECT * FROM products';


  db.query(sql, (err, result) => {
    if (err) return res.status(500).json(err);


    res.json(result);
  });
});


// =======================
// UPDATE PRODUCT
// =======================
app.put('/products/:id', (req, res) => {
  const { name, price } = req.body;
  const id = req.params.id;


  const sql = 'UPDATE products SET name=?, price=? WHERE id=?';


  db.query(sql, [name, price, id], (err, result) => {
    if (err) return res.status(500).json(err);


    res.json({ message: 'Product updated' });
  });
});


// =======================
// DELETE PRODUCT
// =======================
app.delete('/products/:id', (req, res) => {
  const id = req.params.id;


  const sql = 'DELETE FROM products WHERE id=?';


  db.query(sql, [id], (err, result) => {
    if (err) return res.status(500).json(err);


    res.json({ message: 'Product deleted' });
  });
});


// =======================
// START SERVER
// =======================
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
