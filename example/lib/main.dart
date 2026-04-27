import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: TestScreen());
  }
}

/// Test cases for prefer_screenutil lint rule.
class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ✅ CORRECT — should NOT be flagged
          SizedBox(width: 16.w, height: 8.h),
          SizedBox(width: 0, height: 0),
          const SizedBox.shrink(),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Container(),
          ),
          Text(
            'Hello',
            style: TextStyle(fontSize: 14.sp),
          ),

          // ❌ WRONG — should be flagged
          // expect_lint: prefer_screenutil
          SizedBox(width: 16),
          // expect_lint: prefer_screenutil
          SizedBox(height: 8),
          Padding(
            // expect_lint: prefer_screenutil
            padding: EdgeInsets.all(16),
            child: Container(),
          ),
          Text(
            'Hello',
            style: TextStyle(
              // expect_lint: prefer_screenutil
              fontSize: 14,
            ),
          ),
          // expect_lint: prefer_screenutil
          Icon(Icons.add, size: 24),
        ],
      ),
    );
  }
}
