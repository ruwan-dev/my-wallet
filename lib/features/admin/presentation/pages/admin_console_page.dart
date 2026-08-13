import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/shimmer_tile.dart';

class AdminConsolePage extends StatelessWidget {
  const AdminConsolePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Admin Console', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Background Orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6D28D9).withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.2),
              ),
            ),
          ),
          
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                }
                if (!snapshot.hasData) return const ShimmerTile();

                final users = snapshot.data!.docs;

                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found in database.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final email = data['email'] ?? 'No email';
                    final isPremium = data['isPremium'] ?? false;
                    final isAdmin = data['isAdmin'] ?? false;
                    final forceSync = data['forceSync'] ?? false;

                    return _UserCard(
                      id: doc.id,
                      email: email,
                      isPremium: isPremium,
                      isAdmin: isAdmin,
                      forceSync: forceSync,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String id;
  final String email;
  final bool isPremium;
  final bool isAdmin;
  final bool forceSync;

  const _UserCard({
    required this.id,
    required this.email,
    required this.isPremium,
    required this.isAdmin,
    required this.forceSync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: isAdmin ? Colors.amber.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2),
                      radius: 24,
                      child: Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person,
                        color: isAdmin ? Colors.amber : Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: $id',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.5)),
                        ),
                        child: const Text('ADMIN', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else if (isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purpleAccent.withOpacity(0.5)),
                        ),
                        child: const Text('PREMIUM', style: TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                if (!isAdmin) ...[
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('Premium Status', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 12),
                          Switch(
                            value: isPremium,
                            activeColor: Colors.purpleAccent,
                            onChanged: (value) {
                              FirebaseFirestore.instance.collection('users').doc(id).update({
                                'isPremium': value,
                              });
                            },
                          ),
                        ],
                      ),
                      if (isPremium)
                        ElevatedButton.icon(
                          onPressed: forceSync ? null : () {
                            FirebaseFirestore.instance.collection('users').doc(id).update({
                              'forceSync': true,
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sync requested for next login!')),
                            );
                          },
                          icon: Icon(
                            forceSync ? Icons.check_circle : Icons.sync, 
                            size: 16, 
                            color: forceSync ? Colors.greenAccent : Colors.white
                          ),
                          label: Text(forceSync ? 'Sync Pending' : 'Trigger Sync'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: forceSync ? Colors.green.withOpacity(0.2) : Colors.purpleAccent.withOpacity(0.2),
                            foregroundColor: forceSync ? Colors.greenAccent : Colors.purpleAccent,
                            elevation: 0,
                            side: BorderSide(color: forceSync ? Colors.greenAccent.withOpacity(0.5) : Colors.purpleAccent.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
