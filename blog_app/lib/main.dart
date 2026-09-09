import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://localhost:5000/api';

void main() {
  runApp(const BlogApp());
}

class BlogApp extends StatelessWidget {
  const BlogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fathan Times',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFA1A5B7), // Slate background
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5), // Indigo 600
          primary: const Color(0xFF4F46E5),
        ),
        useMaterial3: true,
      ),
      home: const PostListScreen(),
    );
  }
}

// --- SCREEN: DAFTAR ARTIKEL ---
class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  List posts = [];
  bool isLoading = true;

  Future<void> fetchPosts() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/posts'));
      if (res.statusCode == 200) {
        setState(() {
          posts = jsonDecode(res.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> deletePost(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/posts/$id'));
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artikel berhasil dihapus')),
      );
      fetchPosts();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Tailwind Gray-100
      appBar: AppBar(
        title: const Text('FathanTimes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B), // Tailwind Slate-800
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchPosts,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final item = posts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF), // Indigo-50
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['category_name'] ?? 'General',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            item['title'],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['content'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PostDetailScreen(id: item['id'])),
                        );
                        fetchPosts();
                      },
                      trailing: PopupMenuButton(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PostFormScreen(post: item)),
                            );
                            fetchPosts();
                          } else if (value == 'delete') {
                            deletePost(item['id']);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4F46E5),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostFormScreen()),
          );
          fetchPosts();
        },
      ),
    );
  }
}

// --- SCREEN: DETAIL ARTIKEL ---
class PostDetailScreen extends StatelessWidget {
  final int id;
  const PostDetailScreen({super.key, required this.id});

  Future<Map<String, dynamic>> fetchDetail() async {
    final res = await http.get(Uri.parse('$baseUrl/posts/$id'));
    return jsonDecode(res.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black), elevation: 0),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchDetail(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(6)),
                  child: Text(data['category_name'], style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text(data['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                const SizedBox(height: 16),
                Text(data['content'], style: const TextStyle(fontSize: 16, color: Color(0xFF374151), height: 1.5)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- SCREEN: FORM TAMBAH & EDIT ---
class PostFormScreen extends StatefulWidget {
  final Map? post;
  const PostFormScreen({super.key, this.post});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List categories = [];
  int? selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _titleController.text = widget.post!['title'];
      _contentController.text = widget.post!['content'];
      selectedCategory = widget.post!['category_id'];
    }
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/categories'));
    if (res.statusCode == 200) {
      setState(() {
        categories = jsonDecode(res.body);
        if (selectedCategory == null && categories.isNotEmpty) {
          selectedCategory = categories[0]['id'];
        }
      });
    }
  }

  Future<void> savePost() async {
    final body = jsonEncode({
      'title': _titleController.text,
      'content': _contentController.text,
      'category_id': selectedCategory,
    });

    final headers = {'Content-Type': 'application/json'};

    if (widget.post == null) {
      await http.post(Uri.parse('$baseUrl/posts'), headers: headers, body: body);
    } else {
      await http.put(Uri.parse('$baseUrl/posts/${widget.post!['id']}'), headers: headers, body: body);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(widget.post == null ? 'Tambah Artikel' : 'Edit Artikel'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
              items: categories.map<DropdownMenuItem<int>>((cat) {
                return DropdownMenuItem<int>(
                  value: cat['id'],
                  child: Text(cat['name']),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedCategory = val),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Judul Artikel', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Isi Konten', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: savePost,
                child: const Text('Simpan', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}