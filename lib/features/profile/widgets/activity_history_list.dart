import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/activity_model.dart';
import '../../admin/admin_dashboard_screen.dart'; // We'll create this later

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
        // Role check for Admin Dashboard Button
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: firestoreService.streamUserDocument(uid),
          builder: (context, docSnapshot) {
            if (docSnapshot.hasData && docSnapshot.data!.exists) {
              final role = docSnapshot.data!.data()?['role'] as String?;
              if (role == 'admin') {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.6),
                          AppColors.primaryDark.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                          label: const Text(
                            'Admin Dashboard',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminDashboardScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              }
            }
            return const SizedBox.shrink();
          },
        ),
        
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
