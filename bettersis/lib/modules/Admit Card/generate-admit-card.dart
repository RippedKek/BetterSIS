import 'dart:io' as io;
import 'dart:typed_data';
import 'package:bettersis/modules/show_message.dart';
import 'package:bettersis/utils/permission_helper.dart';
import 'package:bettersis/utils/themes.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/utils.dart'; // filename case sensitivity mistake //

class GenerateAdmitCard extends StatefulWidget {
  final String userId;
  final String userName;
  final String userDept;
  final String userProgram;
  final String semester;
  final String examination;
  final String userSemester;

  GenerateAdmitCard({
    required this.semester,
    required this.examination,
    required this.userId,
    required this.userDept,
    required this.userName,
    required this.userProgram,
    required this.userSemester,
  });

  @override
  _GenerateAdmitCardState createState() => _GenerateAdmitCardState();
}

class _GenerateAdmitCardState extends State<GenerateAdmitCard> {
  String? pdfPath;

  @override
  void initState() {
    super.initState();
    _fetchUserAndGenerateAdmitCard();
  }

  Future<void> _fetchUserAndGenerateAdmitCard() async {
    try {
      // Query to find the user document based on userId
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('id', isEqualTo: widget.userId)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userSnapshot.docs.first;

        // Access enrolled courses and registration status
        await _fetchAndVerifyCourses(userDoc);
      } else {
        // Handle user not found
        print('User not found');
        _showErrorMessage("User not found.");
      }
    } catch (e) {
      print('Error fetching user: $e');
      _showErrorMessage("Error fetching user.");
    }
  }

  Future<void> _fetchAndVerifyCourses(DocumentSnapshot userDoc) async {
    try {
      DocumentSnapshot semesterDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userDoc.id)
          .collection('Enrolled Courses')
          .doc(widget.userSemester[0])
          .get();

      if (semesterDoc.exists && semesterDoc['registered'] == true) {
        // User is registered, fetch course list
        QuerySnapshot courseListSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userDoc.id)
            .collection('Enrolled Courses')
            .doc(widget.userSemester[0])
            .collection('Course List')
            .get();

        List<String> registeredCourses = [];

        for (var courseDoc in courseListSnapshot.docs) {
          String courseCode = courseDoc.id;
          String courseTitle = courseDoc['title'];

          // Check if the last character of the course code is an odd number
          int lastDigit =
              int.tryParse(courseCode.substring(courseCode.length - 1)) ?? 0;

          if (lastDigit % 2 != 0) {
            // Add only if the last digit is odd
            registeredCourses.add('$courseCode: $courseTitle');
          }
        }

        if (registeredCourses.isNotEmpty) {
          // Proceed to generate PDF if courses exist
          _generateAndSavePDF(registeredCourses);
        } else {
          _showErrorMessage("No registered theory courses found.");
        }
      } else {
        _showErrorMessage("Register Course for this semester first.");
      }
    } catch (e) {
      print('Error fetching courses: $e');
      _showErrorMessage("Error fetching registered courses.");
    }
  }

  Future<void> _generateAndSavePDF(List<String> registeredCourses) async {
    final pdf = pw.Document();

    final output = await getTemporaryDirectory();
    final filePath = "${output.path}/admit_card.pdf";

    // Load logos
    final iutLogo = (await rootBundle.load('assets/iut_logo.png')).buffer.asUint8List();
    final oicLogo = (await rootBundle.load('assets/oic_logo.jpg')).buffer.asUint8List();

    // Get the current timestamp
    final String generatedDate =
        DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now());

    // Building the PDF structure
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with logos
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(pw.MemoryImage(iutLogo), width: 40),
                  pw.Column(
                    children: [
                      pw.Text("Islamic University of Technology(IUT)",
                          style: pw.TextStyle(fontSize: 18)),
                      pw.Text("(A Subsidiary Organ of the OIC)",
                          style: pw.TextStyle(fontSize: 12)),
                      pw.SizedBox(height: 10),
                      pw.Text("Admit Card",
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              decoration: pw.TextDecoration.underline)),
                    ],
                  ),
                  pw.Image(pw.MemoryImage(oicLogo), width: 50),
                ],
              ),
              pw.SizedBox(height: 10),
              // Subtitle
              pw.Center(
                child: pw.Text(
                  '${widget.semester} Semester 2023-2024 (${widget.examination} Examination)',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 10),

              // User info
              pw.Text('Student ID: ${widget.userId}'),
              pw.Text('Name: ${widget.userName}'),
              pw.Text('Department: ${widget.userDept.toUpperCase()}'),
              pw.Text('Programme: ${widget.userProgram.toUpperCase()}'),
              pw.Text('Semester: ${widget.userSemester}'),
              pw.SizedBox(height: 20),

              // Registered courses
              pw.Text('Registered Theory Courses:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              ...registeredCourses
                  .map((course) => pw.Bullet(text: course))
                  .toList(),
              pw.SizedBox(height: 20),

              // Penalty Section with border
              pw.Container(
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PENALTY OF COMMITTING OFFENCES RELATED TO EXAMINATIONS (GERR ARTICLE 8.0)',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '1. Attempt to communicate with other examinee or examinees:',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '    - First time - Warning by the invigilator.',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '    - Second time - Changing of seats by the invigilator.',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '    - Third time - Expulsion from the examination hall for that paper by the Chief Invigilator.',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '2. Possession of incriminating document or possession of writings related to the subject of examination or copying from any other source or attempting to copy or taking help or attempting to take help from any incriminating document: The minimum punishment is expulsion from Examination Hall and maximum punishment is cancellation of the entire examination (mid semester / semester final) in which s/he is appearing.',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Footer with timestamp
              pw.Center(
                child: pw.Text(
                  'This admit card was generated on $generatedDate',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Write PDF file to the local storage
    final file = io.File(filePath);
    await file.writeAsBytes(await pdf.save());

    // Update the UI with the PDF path
    setState(() {
      pdfPath = filePath; // Save the generated file path
    });
  }

  Future<void> downloadAdmitCard(BuildContext context) async {
    try {
      bool hasPermission =
          await PermissionsHelper.requestStoragePermission(context);
      if (!hasPermission) {
        ShowMessage.error(context, 'Storage permission is required');
        return;
      }

      if (pdfPath == null) {
        ShowMessage.error(context, 'PDF is not yet generated');
        return;
      }

      final baseDir = await getExternalStorageDirectory();
      if (baseDir != null) {
        final customPath = io.Directory(
            '${baseDir.parent.parent.parent.parent.path}/Download/BetterSIS');

        if (!await customPath.exists()) {
          await customPath.create(recursive: true);
        }

        String filePath =
            '${customPath.path}/admit_card_${widget.userProgram}_${widget.userSemester}_${widget.examination}.pdf';
        final file = io.File(pdfPath!);

        await file.copy(filePath);

        ShowMessage.success(context, 'Admit Card downloaded to: $filePath');
      } else {
        ShowMessage.error(context, 'Failed to access storage');
      }
    } catch (e) {
      ShowMessage.error(context, 'Failed to download admit card');
    }
  }

  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = AppTheme.getTheme(widget.userDept);

    return Scaffold(
      body: pdfPath == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 450,
                      child: PDFView(
                        filePath: pdfPath!,
                        enableSwipe: true,
                        swipeHorizontal: true,
                        autoSpacing: false,
                        pageFling: false,
                        onRender: (_pages) {
                          setState(() {});
                        },
                        onError: (error) {
                          print(error.toString());
                        },
                        onPageError: (page, error) {
                          print('$page: ${error.toString()}');
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => downloadAdmitCard(context),
                      icon: const Icon(Icons.download),
                      label: const Text('Download Admit Card'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
