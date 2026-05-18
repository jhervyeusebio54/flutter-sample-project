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
  password: '#JJeusebio678213',
  database: 'flutterdb'
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
  const id = req.params.id;
  const contentType = req.headers['content-type'] || '';

  if (contentType.includes('multipart/form-data')) {
    upload.single('image')(req, res, (err) => {
      if (err) return res.status(500).json({ error: err.message });

      console.log('BODY:', req.body);
      console.log('FILE:', req.file);

      const { name, price } = req.body;
      const image = req.file.filename;
      const sql = 'UPDATE products SET name=?, price=?, image_url=? WHERE id=?';
      db.query(sql, [name, price, image, id], (dbErr) => {
        if (dbErr) return res.status(500).json(dbErr);
        res.json({ message: 'Product updated' });
      });
    });
  } else {
    const { name, price } = req.body;
    const sql = 'UPDATE products SET name=?, price=? WHERE id=?';
    db.query(sql, [name, price, id], (dbErr) => {
      if (dbErr) return res.status(500).json(dbErr);
      res.json({ message: 'Product updated' });
    });
  }
});

app.delete('/products/:id', (req, res) => {
  const id = req.params.id;
  console.log('DELETE id:', id);

  const sql = 'DELETE FROM products WHERE id=?';

  db.query(sql, [id], (err, result) => {
    if (err) {
      console.log('DELETE ERROR:', err);
      return res.status(500).json(err);
    }
    console.log('DELETE RESULT:', result);
    res.json({ message: 'Product deleted' });
  });
});
// =======================
// ORDERS
// =======================
app.post('/orders', (req, res) => {
  const { items, total } = req.body;
  const sql = 'INSERT INTO orders (total, created_at) VALUES (?, NOW())';

  db.query(sql, [total], (err, result) => {
    if (err) return res.status(500).json(err);

    const orderId = result.insertId;
    const orderItems = items.map(item => [
      orderId,
      item.id,
      item.name,
      item.quantity,
      item.price,
    ]);

    const itemSql = 'INSERT INTO order_items (order_id, product_id, name, quantity, price) VALUES ?';
    db.query(itemSql, [orderItems], (err2) => {
      if (err2) return res.status(500).json(err2);
      res.json({ message: 'Order placed', orderId });
    });
  });
});

app.get('/orders', (req, res) => {
  const sql = `
    SELECT o.id, o.total, o.created_at,
      JSON_ARRAYAGG(
        JSON_OBJECT(
          'product_id', oi.product_id,
          'name', oi.name,
          'quantity', oi.quantity,
          'price', oi.price
        )
      ) AS items
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    GROUP BY o.id
    ORDER BY o.created_at DESC
  `;
  db.query(sql, (err, result) => {
    if (err) return res.status(500).json(err);
    res.json(result);
  });
});

// =======================
// CART (persist per session key)
// =======================
app.post('/cart', (req, res) => {
  const { session_key, product_id, name, price, quantity } = req.body;
  const checkSql = 'SELECT * FROM cart WHERE session_key=? AND product_id=?';

  db.query(checkSql, [session_key, product_id], (err, result) => {
    if (err) return res.status(500).json(err);

    if (result.length > 0) {
      const updateSql = 'UPDATE cart SET quantity=quantity+? WHERE session_key=? AND product_id=?';
      db.query(updateSql, [quantity, session_key, product_id], (err2) => {
        if (err2) return res.status(500).json(err2);
        res.json({ message: 'Cart updated' });
      });
    } else {
      const insertSql = 'INSERT INTO cart (session_key, product_id, name, price, quantity) VALUES (?,?,?,?,?)';
      db.query(insertSql, [session_key, product_id, name, price, quantity], (err2) => {
        if (err2) return res.status(500).json(err2);
        res.json({ message: 'Added to cart' });
      });
    }
  });
});

app.get('/cart/:session_key', (req, res) => {
  const sql = 'SELECT * FROM cart WHERE session_key=?';
  db.query(sql, [req.params.session_key], (err, result) => {
    if (err) return res.status(500).json(err);
    res.json(result);
  });
});

app.put('/cart', (req, res) => {
  const { session_key, product_id, quantity } = req.body;
  if (quantity <= 0) {
    const sql = 'DELETE FROM cart WHERE session_key=? AND product_id=?';
    db.query(sql, [session_key, product_id], (err) => {
      if (err) return res.status(500).json(err);
      res.json({ message: 'Item removed' });
    });
  } else {
    const sql = 'UPDATE cart SET quantity=? WHERE session_key=? AND product_id=?';
    db.query(sql, [quantity, session_key, product_id], (err) => {
      if (err) return res.status(500).json(err);
      res.json({ message: 'Cart updated' });
    });
  }
});

app.delete('/cart/:session_key', (req, res) => {
  const sql = 'DELETE FROM cart WHERE session_key=?';
  db.query(sql, [req.params.session_key], (err) => {
    if (err) return res.status(500).json(err);
    res.json({ message: 'Cart cleared' });
  });
});
// =======================
// START SERVER
// =======================
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
