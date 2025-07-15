import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  bool _loading = false;
  bool _loadingCourses = true;
  List<Map<String, dynamic>> _courses = [];

  bool _isEditing = false;
  int? _editingCourseId;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() => _loadingCourses = true);
    try {
      final res = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/courses'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data =
            decoded is List
                ? decoded
                : (decoded['data'] is List ? decoded['data'] : []);
        setState(() {
          _courses = List<Map<String, dynamic>>.from(data);
          _loadingCourses = false;
        });
      } else {
        throw Exception('Failed to fetch: ${res.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCourses = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Load error: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    final jsonBody = jsonEncode({'title': title, 'description': description});

    try {
      final uri =
          _isEditing && _editingCourseId != null
              ? Uri.parse('http://10.0.2.2:8000/api/courses/$_editingCourseId')
              : Uri.parse('http://10.0.2.2:8000/api/courses');

      final res =
          _isEditing
              ? await http.put(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                body: jsonBody,
              )
              : await http.post(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                body: jsonBody,
              );

      setState(() => _loading = false);

      if ([200, 201, 204].contains(res.statusCode)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Course updated' : 'Course added'),
          ),
        );
        _titleController.clear();
        _descController.clear();
        setState(() {
          _isEditing = false;
          _editingCourseId = null;
        });
        await _fetchCourses();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${res.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submit error: $e')));
    }
  }

  Future<void> _deleteCourse(int? id) async {
    if (id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid course ID')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Course'),
            content: const Text('Are you sure you want to delete this course?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final res = await http.delete(
        Uri.parse('http://10.0.2.2:8000/api/courses/$id'),
        headers: {'Accept': 'application/json'},
      );

      if ([200, 204].contains(res.statusCode)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Course deleted')));
        await _fetchCourses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${res.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete error: $e')));
    }
  }

  void _startEditCourse(Map<String, dynamic> course) {
    setState(() {
      _isEditing = true;
      _editingCourseId =
          course['id'] is int
              ? course['id']
              : int.tryParse(course['id'].toString());
      _titleController.text = course['title']?.toString() ?? '';
      _descController.text = course['description']?.toString() ?? '';
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _editingCourseId = null;
      _titleController.clear();
      _descController.clear();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Courses')),
      body:
          _loadingCourses
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Courses',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_courses.isEmpty)
                      const Center(child: Text('No courses available.')),
                    ..._courses.map((course) {
                      final id = course['id'];
                      final title = course['title']?.toString() ?? 'No Title';
                      final desc =
                          course['description']?.toString() ?? 'No Description';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: ListTile(
                          leading: const Icon(
                            Icons.book,
                            color: Colors.deepPurple,
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(desc),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _startEditCourse(course),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => _deleteCourse(
                                      id is int
                                          ? id
                                          : int.tryParse(id.toString()),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const Divider(height: 40),
                    Text(
                      _isEditing ? 'Edit Course' : 'Add New Course',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Course Title',
                              prefixIcon: const Icon(Icons.title),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Enter title'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              prefixIcon: const Icon(Icons.description),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: Icon(
                                    _isEditing ? Icons.save : Icons.add,
                                  ),
                                  label: Text(_isEditing ? 'Update' : 'Add'),
                                  onPressed: _loading ? null : _submit,
                                ),
                              ),
                              if (_isEditing) ...[
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _cancelEdit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade300,
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
