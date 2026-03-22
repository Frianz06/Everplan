import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_task_manager/screens/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String username;
  final String role;
  final String company;

  const DashboardScreen({
    super.key,
    required this.username,
    required this.role,
    required this.company,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Color bgColor = const Color.fromRGBO(249, 248, 244, 1);
  final Color buttonColor = const Color.fromRGBO(105, 139, 106, 1);
  final Color textColor = const Color.fromRGBO(63, 70, 62, 1);
  final Color cardColor = Colors.white;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  void _showTaskDialog({String? targetUid, String? docId, String? title, String? desc, String? deadline}) {
    final titleController = TextEditingController(text: title);
    final descController = TextEditingController(text: desc);
    final deadlineController = TextEditingController(text: deadline);
    
    final effectiveUid = targetUid ?? _uid;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(docId == null ? "Create New Task" : "Update Task",
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Task Title",
                    labelStyle: TextStyle(color: buttonColor),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: buttonColor)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Description (Optional)"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: deadlineController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Deadline (Optional)",
                    suffixIcon: Icon(Icons.calendar_today, size: 20),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      setDialogState(() {
                        deadlineController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (titleController.text.isNotEmpty && effectiveUid != null) {
                  final taskData = {
                    'title': titleController.text,
                    'desc': descController.text,
                    'deadline': deadlineController.text,
                    'updatedAt': FieldValue.serverTimestamp(),
                    'company': widget.company, 
                  };

                  // Use subcollections: users -> {uid} -> tasks
                  if (docId == null) {
                    taskData['createdAt'] = FieldValue.serverTimestamp();
                    await _firestore.collection('users').doc(effectiveUid).collection('tasks').add(taskData);
                  } else {
                    await _firestore.collection('users').doc(effectiveUid).collection('tasks').doc(docId).update(taskData);
                  }

                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(docId == null ? "Save Task" : "Update", style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView( 
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome, ${widget.username}",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 4),
                        Text("${widget.role} — ${widget.company}",
                            style: TextStyle(fontSize: 14, color: buttonColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showTaskDialog(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: buttonColor, shape: BoxShape.circle),
                            child: const Icon(Icons.add, color: Colors.white, size: 26),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.logout_rounded, color: textColor.withAlpha(128)),
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                
                if (widget.role == 'Project Manager') ...[
                  const SizedBox(height: 40),
                  Text("Manage Employees", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 15),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('users')
                        .where('company', isEqualTo: widget.company)
                        .where('role', isEqualTo: 'Employee')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: LinearProgressIndicator());
                      
                      var employees = snapshot.data!.docs;
                      
                      // IMPROVEMENT: Empty State for PMs
                      if (employees.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: buttonColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text(
                              "No employees registered for ${widget.company} yet.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: buttonColor, fontWeight: FontWeight.w500),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: employees.length,
                        itemBuilder: (context, index) {
                          var empData = employees[index].data() as Map<String, dynamic>;
                          String empId = employees[index].id;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color: cardColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                            child: ExpansionTile(
                              shape: const Border(),
                              title: Text(empData['fullName'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text("View & Assign Tasks"),
                              children: [
                                ListTile(
                                  leading: Icon(Icons.add_task, color: buttonColor),
                                  title: const Text("Assign New Task"),
                                  onTap: () => _showTaskDialog(targetUid: empId),
                                ),
                                _buildEmployeeTaskStream(empId),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],

                const SizedBox(height: 40),
                Text(widget.role == 'Project Manager' ? "My Private Tasks" : "Your Tasks", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 15),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .doc(_uid)
                      .collection('tasks')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: buttonColor));
                    }

                    final taskDocs = snapshot.data?.docs ?? [];
                    if (taskDocs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: Text("No tasks found.", style: TextStyle(color: Colors.grey[400]))),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: taskDocs.length,
                      itemBuilder: (context, index) {
                        var doc = taskDocs[index];
                        var data = doc.data() as Map<String, dynamic>;
                        
                        // DATA INTEGRITY FIX: Handle null createdAt
                        DateTime createdDate = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                        String formattedDate = DateFormat('MMM dd, yyyy').format(createdDate);

                        return _buildTaskCard(
                          _uid!, 
                          doc.id,
                          data['title'] ?? '',
                          formattedDate,
                          data['deadline'] ?? '',
                          data['desc'] ?? '',
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeTaskStream(String empId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').doc(empId).collection('tasks').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var tasks = snapshot.data!.docs;
        if (tasks.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text("No tasks assigned."));

        return Column(
          children: tasks.map((taskDoc) {
            var taskData = taskDoc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(taskData['title'] ?? 'No Title'),
              subtitle: Text(taskData['deadline'] ?? 'No deadline'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _firestore.collection('users').doc(empId).collection('tasks').doc(taskDoc.id).delete(),
              ),
              onTap: () => _showTaskDialog(
                targetUid: empId,
                docId: taskDoc.id,
                title: taskData['title'],
                desc: taskData['desc'],
                deadline: taskData['deadline'],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTaskCard(String targetUid, String docId, String title, String created, String deadline, String desc) {
    return GestureDetector(
      onTap: () => _showTaskDialog(
        targetUid: targetUid,
        docId: docId,
        title: title,
        desc: desc,
        deadline: deadline,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.check_circle_outline_rounded, color: buttonColor.withAlpha(153), size: 28),
              onPressed: () async {
                await _firestore.collection('users').doc(targetUid).collection('tasks').doc(docId).delete();
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(desc, style: TextStyle(color: textColor.withAlpha(153), fontSize: 13)),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text("Created: $created", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      if (deadline.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Text("Due: $deadline",
                            style: TextStyle(color: Colors.red[300], fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}