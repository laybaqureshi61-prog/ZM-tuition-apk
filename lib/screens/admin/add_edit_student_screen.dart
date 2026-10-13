import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services/app_data.dart';

class AddEditStudentScreen extends StatefulWidget {
  final UserModel? studentToEdit;

  const AddEditStudentScreen({super.key, this.studentToEdit});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final AppData _appData = AppData();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _rollController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _addressController = TextEditingController();

  late String _selectedClass;

  @override
  void initState() {
    super.initState();
    final allowed = _appData.classesForCurrentAdmin;
    _selectedClass = allowed.isNotEmpty ? allowed.first : AppData.allClasses.first;

    if (widget.studentToEdit != null) {
      final s = widget.studentToEdit!;
      _nameController.text = s.name;
      _emailController.text = s.email;
      _rollController.text = s.rollNo;
      _parentPhoneController.text = s.parentPhone;
      _addressController.text = s.address;
      if (allowed.contains(s.assignedClass)) {
        _selectedClass = s.assignedClass;
      }
    }
  }

  void _saveStudent() {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Student Name and Email')),
      );
      return;
    }

    if (widget.studentToEdit == null) {
      _appData.addStudentDirectly(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        assignedClass: _selectedClass,
        rollNo: _rollController.text.trim(),
        phone: _parentPhoneController.text.trim(),
        parentPhone: _parentPhoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student added successfully!')),
      );
    } else {
      final updated = UserModel(
        id: widget.studentToEdit!.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: widget.studentToEdit!.password,
        role: 'student',
        status: 'approved',
        assignedClass: _selectedClass,
        rollNo: _rollController.text.trim(),
        phone: _parentPhoneController.text.trim(),
        parentPhone: _parentPhoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      _appData.updateStudent(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student details updated successfully!')),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final allowedClasses = _appData.classesForCurrentAdmin;
    final isEditing = widget.studentToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Student' : 'Add New Student'),
        backgroundColor: const Color(0xFF4F46E5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          color: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Update Student Details' : 'Register New Student',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 20),

                // Student Name
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline, color: Color(0xFF4F46E5)),
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF4F46E5)),
                  ),
                ),
                const SizedBox(height: 16),

                // Class Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Assign Class & Stream',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school_outlined, color: Color(0xFF4F46E5)),
                  ),
                  items: allowedClasses.map((cls) => DropdownMenuItem(value: cls, child: Text(cls))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedClass = val);
                  },
                ),
                const SizedBox(height: 16),

                // Roll Number
                TextField(
                  controller: _rollController,
                  decoration: const InputDecoration(
                    labelText: 'Roll Number / ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF4F46E5)),
                  ),
                ),
                const SizedBox(height: 16),

                // Parent Phone
                TextField(
                  controller: _parentPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Parent Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF4F46E5)),
                  ),
                ),
                const SizedBox(height: 16),

                // Address
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Residential Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home_outlined, color: Color(0xFF4F46E5)),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _saveStudent,
                    child: Text(isEditing ? 'Save Changes' : 'Save Student', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
