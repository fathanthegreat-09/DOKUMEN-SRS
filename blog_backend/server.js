require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Koneksi Database
const db = mysql.createConnection({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'db_blog_app',
});

db.connect((err) => {
  if (err) throw err;
  console.log('Database connected!');
});

// --- API CATEGORIES ---
app.get('/api/categories', (req, res) => {
  db.query('SELECT * FROM categories', (err, results) => {
    if (err) return res.status(500).json({ message: err.message });
    res.status(200).json(results);
  });
});

// --- API POSTS (CRUD) ---

// 1. Get All Posts
app.get('/api/posts', (req, res) => {
  const query = `
    SELECT posts.*, categories.name AS category_name 
    FROM posts 
    JOIN categories ON posts.category_id = categories.id
    ORDER BY posts.created_at DESC
  `;
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ message: err.message });
    res.status(200).json(results);
  });
});

// 2. Get Post Detail
app.get('/api/posts/:id', (req, res) => {
  const { id } = req.params;
  const query = `
    SELECT posts.*, categories.name AS category_name 
    FROM posts 
    JOIN categories ON posts.category_id = categories.id 
    WHERE posts.id = ?
  `;
  db.query(query, [id], (err, results) => {
    if (err) return res.status(500).json({ message: err.message });
    if (results.length === 0) return res.status(404).json({ message: 'Artikel tidak ditemukan' });
    res.status(200).json(results[0]);
  });
});

// 3. Create Post
app.post('/api/posts', (req, res) => {
  const { title, content, category_id } = req.body;
  if (!title || !content || !category_id) {
    return res.status(400).json({ message: 'Semua field wajib diisi' });
  }

  const query = 'INSERT INTO posts (title, content, category_id) VALUES (?, ?, ?)';
  db.query(query, [title, content, category_id], (err, result) => {
    if (err) return res.status(500).json({ message: err.message });
    res.status(201).json({ id: result.insertId, title, content, category_id, message: 'Artikel berhasil dibuat' });
  });
});

// 4. Update Post
app.put('/api/posts/:id', (req, res) => {
  const { id } = req.params;
  const { title, content, category_id } = req.body;

  const query = 'UPDATE posts SET title = ?, content = ?, category_id = ? WHERE id = ?';
  db.query(query, [title, content, category_id, id], (err, result) => {
    if (err) return res.status(500).json({ message: err.message });
    if (result.affectedRows === 0) return res.status(404).json({ message: 'Artikel tidak ditemukan' });
    res.status(200).json({ message: 'Artikel berhasil diperbarui' });
  });
});

// 5. Delete Post
app.delete('/api/posts/:id', (req, res) => {
  const { id } = req.params;
  db.query('DELETE FROM posts WHERE id = ?', [id], (err, result) => {
    if (err) return res.status(500).json({ message: err.message });
    if (result.affectedRows === 0) return res.status(404).json({ message: 'Artikel tidak ditemukan' });
    res.status(200).json({ message: 'Artikel berhasil dihapus' });
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));