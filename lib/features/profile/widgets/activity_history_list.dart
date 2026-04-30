import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/activity_model.dart';

class ActivityHistoryList extends StatelessWidget {
  const ActivityHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final uid = authProvider.user?.id;

    if (uid == null) {
      return const Center(child: Text('Please log in.'));
    }

    final firestoreService = FirestoreService();

    return Column(
      children: [
        
        // Activity List Stream
        SizedBox(
          height: 350,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: firestoreService.streamUserActivities(uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading history.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No activity history found.',
                    style: TextStyle(color: AppColors.darkTextSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final activity = ActivityModel.fromMap(docs[index].id, data);
                  return _buildHistoryCard(activity);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(ActivityModel activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1), // Thin 1px glass border
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        activity.prompt,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      activity.formattedDate,
                      style: const TextStyle(
                        color: AppColors.darkTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getSnippet(activity.response),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSnippet(String text) {
    // Remove markdown formatting generically if desired, or just take first N chars.
    final cleanText = text.replaceAll(RegExp(r'\n+'), ' ').trim();
    if (cleanText.length > 100) {
      return '${cleanText.substring(0, 100)}...';
    }
    return cleanText;
  }
}
