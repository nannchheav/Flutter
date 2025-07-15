import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/student.dart';
import 'package:http/http.dart' as http;

class EnrollStudentScreen extends StatefulWidget {
  const EnrollStudentScreen({super.key});

  @override
  State<EnrollStudentScreen> createState() => _EnrollStudentScreenState();
}

class _EnrollStudentScreenState extends State<EnrollStudentScreen> {
  List<Student> _students = [];
  List<dynamic> _courses = [];
  List<dynamic> _enrollments = [];

  Student? _selectedStudent;
  int? _selectedCourseId;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final studentRes = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/students'),
      );
      final courseRes = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/courses'),
      );
      final enrollRes = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/enrollments'),
      );

      if (studentRes.statusCode == 200 &&
          courseRes.statusCode == 200 &&
          enrollRes.statusCode == 200) {
        final sd = jsonDecode(studentRes.body);
        final cd = jsonDecode(courseRes.body);
        final ed = jsonDecode(enrollRes.body);

        final studentsList = sd is List ? sd : (sd['data'] ?? []);
        final coursesList = cd is List ? cd : (cd['data'] ?? []);
        final enrollList = ed is List ? ed : (ed['data'] ?? []);

        setState(() {
          _students =
              studentsList.map<Student>((e) => Student.fromJson(e)).toList();
          _courses = coursesList;
          _enrollments = enrollList;
          if (_courses.isNotEmpty &&
              !_courses.any((c) => c['id'] == _selectedCourseId)) {
            _selectedCourseId = null;
          }
          _loading = false;
        });
      } else {
        throw Exception('Failed to fetch resources');
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  Future<void> _enrollStudent() async {
    if (_selectedStudent == null || _selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both student and course')),
      );
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/enrollments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': _selectedStudent!.id,
          'course_id': _selectedCourseId,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enrolled successfully')));
        _loadData();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${res.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error enrolling student: $e')));
    }
  }

  Future<void> _updateEnrollment(
    int enrollmentId,
    int studentId,
    int courseId,
  ) async {
    try {
      final res = await http.put(
        Uri.parse('http://10.0.2.2:8000/api/enrollments/$enrollmentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'student_id': studentId, 'course_id': courseId}),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Updated successfully')));
        _loadData();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: ${res.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating enrollment: $e')));
    }
  }

  Future<void> _deleteEnrollment(int enrollmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Delete this enrollment?'),
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

    if (confirm == true) {
      try {
        final res = await http.delete(
          Uri.parse('http://10.0.2.2:8000/api/enrollments/$enrollmentId'),
        );
        if (res.statusCode == 200) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Deleted successfully')));
          _loadData();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Delete failed: ${res.body}')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting enrollment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Enrollments')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Enrollments',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_enrollments.isEmpty)
                      const Text('No enrollments found.'),
                    ..._enrollments.map((e) {
                      final student = e['student'];
                      final course = e['course'];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade300,
                            child: Text(
                              student['name'][0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(student['name']),
                          subtitle: Text('Course: ${course['title']}'),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.deepPurple,
                                ),
                                onPressed: () async {
                                  int? tempCourseId = course['id'];
                                  final updatedCourseId = await showDialog<int>(
                                    context: context,
                                    builder: (ctx) {
                                      return AlertDialog(
                                        title: const Text('Update Enrollment'),
                                        content: DropdownButtonFormField<int>(
                                          value: tempCourseId,
                                          decoration: const InputDecoration(
                                            labelText: 'Select New Course',
                                          ),
                                          items:
                                              _courses.map<
                                                DropdownMenuItem<int>
                                              >((c) {
                                                return DropdownMenuItem<int>(
                                                  value: c['id'],
                                                  child: Text(c['title']),
                                                );
                                              }).toList(),
                                          onChanged:
                                              (val) => tempCourseId = val,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(ctx, null),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  ctx,
                                                  tempCourseId,
                                                ),
                                            child: const Text('Update'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (updatedCourseId != null &&
                                      updatedCourseId != course['id']) {
                                    await _updateEnrollment(
                                      e['id'],
                                      student['id'],
                                      updatedCourseId,
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteEnrollment(e['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const Divider(height: 40),
                    const Text(
                      'Enroll a New Student',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Student>(
                      value: _selectedStudent,
                      decoration: InputDecoration(
                        labelText: 'Select Student',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      items:
                          _students
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.name),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (val) => setState(() => _selectedStudent = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedCourseId,
                      decoration: InputDecoration(
                        labelText: 'Select Course',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.book_outlined),
                      ),
                      items:
                          _courses
                              .map<DropdownMenuItem<int>>(
                                (c) => DropdownMenuItem<int>(
                                  value: c['id'],
                                  child: Text(c['title']),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (val) => setState(() => _selectedCourseId = val),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Enroll Student'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _enrollStudent,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
