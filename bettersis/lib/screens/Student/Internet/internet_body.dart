import 'dart:convert';
import 'package:bettersis/modules/loading_spinner.dart';
import 'package:bettersis/screens/Student/Internet/usage_details_modal.dart';
import 'package:bettersis/utils/themes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InternetBody extends StatefulWidget {
  final String userName;
  final String userId;
  final String userDept;

  const InternetBody(
      {super.key,
      required this.userName,
      required this.userId,
      required this.userDept});

  @override
  State<InternetBody> createState() => _InternetBodyState();
}

class _InternetBodyState extends State<InternetBody> {
  bool isLoading = true;
  String totalUsage = "12,000";
  List<Map<String, dynamic>> usageHistory = [];

  Future<void> _storeUsageDataInFirestore(
      String totalUsage, List<Map<String, dynamic>> usageHistory) async {
    try {
      final documentRef =
          FirebaseFirestore.instance.collection('Internet').doc(widget.userId);

      await documentRef.set({
        'totalUsage': totalUsage,
        'usageHistory': usageHistory,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error storing data in Firestore: $e');
    }
  }

  Future<void> _fetchInternetUsage(String username, String password) async {
    final url = Uri.parse('http://127.0.0.1:8000/api/get-usage/');

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        var minutesUsed = data['usage'][0].toString();

        if (minutesUsed.length == 4) {
          minutesUsed =
              '${minutesUsed[0]},${minutesUsed[1]}${minutesUsed[2]}${minutesUsed[3]}';
        } else if (minutesUsed.length == 5) {
          minutesUsed =
              '${minutesUsed[0]}${minutesUsed[1]},${minutesUsed[2]}${minutesUsed[3]}${minutesUsed[4]}';
        }

        List<Map<String, dynamic>> formattedUsageHistory =
            List<Map<String, dynamic>>.from(
                (data['usage'].sublist(1) as List).map((item) => {
                      'start': item[0],
                      'end': item[1],
                      'duration': item[2],
                      'mb': item[3],
                      'location': item[4],
                      'mac': item[5],
                    }));

        setState(() {
          totalUsage = minutesUsed;
          usageHistory = formattedUsageHistory.reversed.toList();
        });

        await _storeUsageDataInFirestore(totalUsage, usageHistory);
      } else {
        setState(() {
          totalUsage = "12,000";
        });
      }
    } catch (error) {
      setState(() {
        totalUsage = "12,000";
      });
    }
  }

  Future<void> fetchInternetCredsFromFirestore() async {
    setState(() {
      isLoading = true;
    });

    final documentRef =
        FirebaseFirestore.instance.collection('Internet').doc(widget.userId);

    try {
      final documentSnapshot = await documentRef.get();

      if (documentSnapshot.exists) {
        final data = documentSnapshot.data() as Map<String, dynamic>;

        final username = data['username'];
        final password = data['password'];

        await _fetchInternetUsage(username, password);
      }
    } catch (e) {
      print('Error fetching tokens: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchInittialDataFromFirestore() async {
    setState(() {
      isLoading = true;
    });

    try {
      final documentRef =
          FirebaseFirestore.instance.collection('Internet').doc(widget.userId);
      final documentSnapshot = await documentRef.get();

      if (documentSnapshot.exists) {
        final data = documentSnapshot.data();

        if (data != null) {
          setState(() {
            totalUsage = data['totalUsage'] ?? "12,000";
            usageHistory =
                List<Map<String, dynamic>>.from(data['usageHistory'] ?? []);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchInittialDataFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = AppTheme.getTheme(widget.userDept);
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    return Stack(
      children: [
        Container(
          color: theme.primaryColor,
          width: screenWidth,
          height: screenHeight,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 26.0),
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Column(
                  children: [
                    Text(
                      widget.userName,
                      style: TextStyle(
                        fontSize: 0.062 * screenWidth,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.userId,
                      style: TextStyle(
                        fontSize: 0.037 * screenWidth,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Minutes Used',
                      style: TextStyle(
                        fontSize: screenWidth * 0.037,
                        fontWeight: FontWeight.w500,
                        color: theme.secondaryHeaderColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            totalUsage,
                            style: TextStyle(
                              fontSize: screenWidth * 0.07,
                              fontWeight: FontWeight.w700,
                              color: theme.secondaryHeaderColor,
                            ),
                          ),
                          Text(
                            'out of',
                            style: TextStyle(
                              fontSize: screenWidth * 0.046,
                              fontWeight: FontWeight.w700,
                              color: theme.secondaryHeaderColor,
                            ),
                          ),
                          Text(
                            '12,000',
                            style: TextStyle(
                              fontSize: screenWidth * 0.07,
                              fontWeight: FontWeight.w700,
                              color: theme.secondaryHeaderColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              InkWell(
                onTap: fetchInternetCredsFromFirestore,
                child: Container(
                  padding: const EdgeInsets.only(top: 26, bottom: 16),
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                      Text(
                        "REFRESH",
                        style: TextStyle(
                          fontSize: 0.032 * screenWidth,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenHeight * 0.02),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'USAGE HISTORY',
                        style: TextStyle(
                          color: theme.secondaryHeaderColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: usageHistory.length,
                          itemBuilder: (context, index) {
                            final usage = usageHistory[index];
                            return Card(
                              margin: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.01),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  foregroundColor: theme.primaryColor,
                                  backgroundColor: Colors.transparent,
                                  child: const Icon(Icons.circle_rounded),
                                ),
                                title: Text(usage['location']),
                                subtitle: Text(usage['start'].split(' ')[0]),
                                trailing: Text(
                                  '${usage['duration'].split(' ')[0]} Mins',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors
                                        .transparent, // To allow tapping outside to close
                                    isScrollControlled: true,
                                    builder: (BuildContext context) {
                                      return UsageDetailsModal(
                                          usage: usage, theme: theme);
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'View More >>',
                          style: TextStyle(color: theme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isLoading) const LoadingSpinner(),
      ],
    );
  }
}
