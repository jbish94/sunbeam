import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';

/// Renders a bundled legal document (simple markdown: #, ##, - lists,
/// and paragraphs) from assets/legal/.
class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String assetPath;

  const LegalDocumentScreen({
    Key? key,
    required this.title,
    required this.assetPath,
  }) : super(key: key);

  static const String privacyPolicyAsset = 'assets/legal/privacy_policy.md';
  static const String termsOfServiceAsset = 'assets/legal/terms_of_service.md';
  static const String medicalDisclaimerAsset =
      'assets/legal/medical_disclaimer.md';

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightTheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(6.w),
                child: Text(
                  'Unable to load this document. Please try again later.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildContent(snapshot.data!, theme),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildContent(String markdown, ThemeData theme) {
    final widgets = <Widget>[];
    for (final rawLine in markdown.split('\n')) {
      final line = rawLine.trimRight();
      if (line.isEmpty) continue;
      if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: EdgeInsets.only(top: 2.5.h, bottom: 1.h),
          child: Text(
            line.substring(3),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ));
      } else if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: EdgeInsets.only(bottom: 1.h),
          child: Text(
            line.substring(2),
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ));
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: EdgeInsets.only(left: 3.w, bottom: 0.8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: theme.textTheme.bodyMedium),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: EdgeInsets.only(bottom: 1.2.h),
          child: Text(
            line,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ));
      }
    }
    widgets.add(SizedBox(height: 4.h));
    return widgets;
  }
}
