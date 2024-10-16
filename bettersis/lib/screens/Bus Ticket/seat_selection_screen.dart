import 'package:bettersis/modules/bettersis_appbar.dart';
import 'package:bettersis/screens/Misc/appdrawer.dart';
import 'package:bettersis/utils/themes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'seat_actions.dart';
import 'seat_grid.dart';
import 'seat_legend.dart';
import '../../modules/Bus Ticket/seat_provider.dart';

class SeatSelectionScreen extends StatelessWidget {
  final String userId;
  final String userDept;
  final VoidCallback onLogout;

  const SeatSelectionScreen({
    super.key,
    required this.userId,
    required this.userDept,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    ThemeData theme = AppTheme.getTheme(userDept);

    return ChangeNotifierProvider<SeatProvider>(
      create: (_) => SeatProvider(userId)..fetchSeats(),
      child: Scaffold(
        drawer: CustomAppDrawer(theme: theme),
        appBar: BetterSISAppBar(
          onLogout: onLogout,
          theme: theme,
          title: 'TRANSPORTATION',
        ),
        body: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                child: SeatLegend(),
              ),
              Expanded(
                child: SeatGrid(),
              ),
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.02),
                child: SeatActions(userId: userId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
