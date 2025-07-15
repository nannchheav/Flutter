import 'dart:convert';
import 'package:flutter_application_1/models/student.dart';
import 'package:http/http.dart' as http;

class StudentService {
  final String baseUrl = 'http://10.0.2.2:8000/api';

  Future<List<Student>> getStudents() async {
    final response = await http.get(Uri.parse('$baseUrl/students'));
    if (response.statusCode == 200) {
      List jsonData = json.decode(response.body);
      return jsonData.map((student) => Student.fromJson(student)).toList();
    } else {
      throw Exception('Failed to load students');
    }
  }

  Future<void> addStudent(String name, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/students'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add student');
    }
  }

  Future<void> enrollStudentInCourse(int studentId, int courseId) async {
    final url = Uri.parse('http://10.0.2.2:8000/api/enrollments');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'student_id': studentId, 'course_id': courseId}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to enroll student');
    }
  }

  Future<void> updateStudent(int id, String name, String email) async {
    final response = await http.put(
      Uri.parse('$baseUrl/students/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update student');
    }
  }

  Future<void> deleteStudent(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/students/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete student');
    }
  }
}
