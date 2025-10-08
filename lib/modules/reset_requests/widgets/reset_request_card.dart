import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ResetRequestCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final int index;
  final VoidCallback? onDelete;

  const ResetRequestCard({
    super.key,
    required this.doc,
    required this.index,
    this.onDelete,
  });

  @override
  State<ResetRequestCard> createState() => _ResetRequestCardState();
}

class _ResetRequestCardState extends State<ResetRequestCard>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    // Staggered animation
    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _animController.forward();
    });
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown time";
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final email = data['email'] ?? 'Unknown Email';
    final timestamp = data['timestamp'] as Timestamp?;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Card(
        color: Colors.white.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.orangeAccent,
            child: Icon(Icons.vpn_key, color: Colors.white),
          ),
          title: Text(
            email,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "Requested on: ${_formatTimestamp(timestamp)}",
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: widget.onDelete,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
}
