import 'package:bettersis/modules/bettersis_appbar.dart';
import 'package:bettersis/screens/Misc/appdrawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bettersis/screens/Student/Result/final_page.dart';
import 'package:bettersis/screens/Student/Result/midpage.dart';
import 'package:bettersis/utils/themes.dart';
import 'package:flutter/material.dart';
import '../../../modules/Result/graphical_result.dart';
import 'quiz_page.dart';

class ResultPage extends StatefulWidget {
  final VoidCallback onLogout;
  final Map<String, dynamic> userData;

  const ResultPage({super.key, required this.onLogout, required this.userData});

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final PageController _pageController = PageController(initialPage: 0);

  double _latestGPA = 0.0;
  double _calculatedCGPA = 0.0;
  double _completedCredits = 0.0;
  bool _isLoadingCG = true;
  bool _isLoadingCred = true;

  Future<void> _fetchCompletedCredits() async {
    try {
      double totalCredits = 0.0;
      int userSemester = int.parse(widget.userData['semester'][0]);

      DocumentSnapshot coursesDoc = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(widget.userData['dept'])
          .get();

      for (int semester = 1; semester <= userSemester; semester++) {
        QuerySnapshot semesterCourses = await FirebaseFirestore.instance
            .collection('Courses')
            .doc(widget.userData['dept'])
            .collection(semester.toString())
            .get();

        for (var courseDoc in semesterCourses.docs) {
          Map<String, dynamic> courseData =
              courseDoc.data() as Map<String, dynamic>;
          double credit = (courseData['credit'] as num).toDouble();
          totalCredits += credit;
        }
      }

      setState(() {
        _completedCredits = totalCredits;
        _isLoadingCred = false;
      });
    } catch (error) {
      print('Error fetching Total Credits: $error');
      setState(() {
        _isLoadingCred = false;
      });
    }
  }

  Future<void> _fetchGPAAndCalculateCGPA() async {
    try {
      double totalGPA = 0.0;
      int semesterCount = 0;
      double latestGPA = 0.0;

      QuerySnapshot semesterResults = await FirebaseFirestore.instance
          .collection('Results')
          .doc('Final')
          .collection(widget.userData['id'])
          .get();

      if (semesterResults.docs.isNotEmpty) {
        int last = semesterResults.docs.length;

        var lastSemester =
            semesterResults.docs[last - 1].data() as Map<String, dynamic>?;
        if (lastSemester == null ||
            lastSemester['gpa'] == null ||
            lastSemester['gpa'] == 0.0) {
          semesterResults.docs.removeLast();
        }

        if (semesterResults.docs.isNotEmpty) {
          for (var doc in semesterResults.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            double gpa = (data['gpa'] is int)
                ? (data['gpa'] as int).toDouble()
                : data['gpa'] ?? 0.0;

            totalGPA += gpa;
            semesterCount++;
          }

          var latestSemester =
              semesterResults.docs[last - 2].data() as Map<String, dynamic>?;
          if (latestSemester != null && latestSemester['gpa'] != null) {
            latestGPA = (latestSemester['gpa'] is int)
                ? (latestSemester['gpa'] as int).toDouble()
                : latestSemester['gpa'];
          }
        }

        setState(() {
          _latestGPA = latestGPA;
          _calculatedCGPA =
              semesterCount > 0 ? totalGPA / (semesterCount - 1) : 0.0;
          _isLoadingCG = false;
        });
      } else {
        setState(() {
          _latestGPA = 0.0;
          _calculatedCGPA = 0.0;
          _isLoadingCG = false;
        });
      }
    } catch (error) {
      print('Error fetching GPA: $error');
      setState(() {
        _isLoadingCG = false;
      });
    }
  }

  void _showGraphicalResultDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return GraphicalResult(userData: widget.userData);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchGPAAndCalculateCGPA();
    _fetchCompletedCredits();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = AppTheme.getTheme(widget.userData['dept']);
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Theme(
      data: theme,
      child: Scaffold(
        drawer: CustomAppDrawer(theme: theme),
        appBar: BetterSISAppBar(
          onLogout: widget.onLogout,
          theme: theme,
          title: 'Result',
        ),
        body: Column(
          children: [
            // Display Student Information
            Container(
              color: theme.primaryColor,
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.37,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Name: \n${widget.userData['name']}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Student ID:\n${widget.userData['id']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.035,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Current AY:\n2023-2024',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.035,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Current Semester:\n${widget.userData['semester']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.035,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(0),
                                child: Text(
                                  'Completed Credits:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _isLoadingCred
                                  ? SizedBox(
                                      width: screenWidth * 0.08,
                                      child: LinearProgressIndicator(
                                        backgroundColor:
                                            Colors.white.withOpacity(0.5),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _completedCredits.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.035,
                                      ),
                                    ),
                            ],
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // GPA Card
                        Flexible(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: theme.secondaryHeaderColor,
                                width: 2,
                              ),
                            ),
                            child: Card(
                              color: Colors.white.withOpacity(0.7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                child: Column(
                                  children: [
                                    Text(
                                      'GPA',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    _isLoadingCG
                                        ? const CircularProgressIndicator()
                                        : Text(
                                            _latestGPA.toStringAsFixed(2),
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.045,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.05),
                        // CGPA Card with GestureDetector
                        Flexible(
                          child: GestureDetector(
                            onTap: _showGraphicalResultDialog,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: theme.secondaryHeaderColor,
                                  width: 2,
                                ),
                              ),
                              child: Card(
                                color: Colors.white.withOpacity(0.7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: EdgeInsets.all(screenWidth * 0.03),
                                  child: Column(
                                    children: [
                                      Text(
                                        'CGPA',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.01),
                                      _isLoadingCG
                                          ? const CircularProgressIndicator()
                                          : Text(
                                              _calculatedCGPA
                                                  .toStringAsFixed(2),
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.045,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                children: [
                  QuizPage(
                      userId: widget.userData['id'],
                      userSemester: widget.userData['semester'],
                      theme: theme),
                  Midpage(
                      userId: widget.userData['id'],
                      userSemester: widget.userData['semester'],
                      theme: theme),
                  FinalPage(
                      userId: widget.userData['id'],
                      userSemester: widget.userData['semester'],
                      theme: theme,
                      userDept: widget.userData['dept']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
* void addMoney(double amount) {
  setState(() {
    balance += amount;
  });

  updateBalance(widget.userData['studentId'], balance);
}

*
*/