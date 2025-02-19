import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShowCode extends StatelessWidget {
  final Map<String, String> classroom;
  final ThemeData theme;

  const ShowCode({
    super.key,
    required this.classroom,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;

    return Card(
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
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
        title: Text(classroom['course']!),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              classroom['code']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: classroom['code']!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
