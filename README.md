# Flutter Inventory App

A full-stack inventory management system built with Flutter (web/mobile) and Node.js + MySQL. Features a dark-mode UI, product management, customer shopping cart, and order checkout.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Node.js + Express |
| Database | MySQL |
| Image storage | Local filesystem (`public/images/`) |

---

## Features

- **Auth** — Login with email and password
- **Products** — Add, edit, delete, search, and sort inventory
- **Image upload** — Pick and update product images
- **Customer mode** — Modal shop view with add-to-cart
- **Cart** — Persisted per session in the database
- **Checkout** — Places order and saves to database with receipt dialog
- **Orders** — Stored with line items in relational tables

---

## Project Structure

```
flutter_project/
├── frontend/               # Flutter app
│   └── lib/
│       ├── main.dart
│       ├── login_page.dart
│       ├── product_list_page.dart
│       ├── add_product_page.dart
│       ├── edit_product_page.dart
│       └── customer_modal.dart
└── backend/                # Node.js server
    ├── server.js
    └── public/
        └── images/         # Uploaded product images
```

---

## Database Setup

Run the following SQL in your MySQL client to create the database and all required tables.

```sql
CREATE DATABASE flutterdb;
USE flutterdb;

-- Users table (for login)
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL
);

-- Insert a default admin user
INSERT INTO users (email, password) VALUES ('admin@example.com', 'password123');

-- Products table
CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  image_url VARCHAR(255) DEFAULT ''
);

-- Orders table
CREATE TABLE orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  total DECIMAL(10, 2) NOT NULL,
  created_at DATETIME
);

-- Order items table
CREATE TABLE order_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  name VARCHAR(255),
  quantity INT,
  price DECIMAL(10, 2),
  FOREIGN KEY (order_id) REFERENCES orders(id)
);

-- Cart table (persists per session key)
CREATE TABLE cart (
  id INT AUTO_INCREMENT PRIMARY KEY,
  session_key VARCHAR(100) NOT NULL,
  product_id INT NOT NULL,
  name VARCHAR(255),
  price DECIMAL(10, 2),
  quantity INT DEFAULT 1
);
```

---

## Backend Setup

### Prerequisites

- Node.js v18+
- MySQL 8+

### Install dependencies

```bash
cd backend
npm install express mysql cors multer body-parser
```

### Configure database connection

In `server.js`, update the MySQL connection:

```javascript
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'your_password',
  database: 'flutterdb'
});
```

### Create image directory

```bash
mkdir -p backend/public/images
```

### Run the server

```bash
node server.js
```

Server runs at `http://localhost:3000`.

---

## Frontend Setup

### Prerequisites

- Flutter SDK 3.x+
- Chrome (for web) or Android/iOS emulator

### Install dependencies

```bash
cd frontend
flutter pub get
```

### Required packages (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.0.0
  image_picker: ^1.0.0
```

### Run the app

```bash
# Web
flutter run -d chrome

# Android
flutter run -d android
```

> **Note:** If running on a physical device or emulator, replace `http://localhost:3000` with your machine's local IP address (e.g. `http://192.168.1.x:3000`) in all Dart files.

---

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/login` | Authenticate user |
| `GET` | `/products` | Get all products |
| `POST` | `/products` | Create product (multipart) |
| `PUT` | `/products/:id` | Update product (JSON or multipart) |
| `DELETE` | `/products/:id` | Delete product |
| `GET` | `/cart/:session_key` | Get cart items |
| `POST` | `/cart` | Add item to cart |
| `PUT` | `/cart` | Update cart item quantity |
| `DELETE` | `/cart/:session_key` | Clear cart |
| `POST` | `/orders` | Place order |
| `GET` | `/orders` | Get all orders |

---

## Screenshots

> Add screenshots here after running the app.

| Login | Inventory | Customer Modal |
|---|---|---|
| *(screenshot)* | *(screenshot)* | *(screenshot)* |

---

## Known Limitations

- Passwords are stored in plain text — add bcrypt hashing before deploying
- Session keys are generated randomly per modal open, not tied to a user account
- No JWT auth — the login only checks the database and grants full access
- Images are stored on disk, not a cloud storage provider

---

## License

MIT
