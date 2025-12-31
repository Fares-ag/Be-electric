import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignatureWidget extends StatefulWidget {
  const SignatureWidget({required this.title, super.key, this.description});
  final String title;
  final String? description;

  @override
  State<SignatureWidget> createState() => _SignatureWidgetState();
}

class _SignatureWidgetState extends State<SignatureWidget> {
  final SignatureController _controller = SignatureController(
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSignature() {
    _controller.clear();
  }

  void _saveSignature() {
    if (_controller.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide a signature'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _controller.toPngBytes().then((bytes) {
      if (bytes != null && mounted) {
        // Convert bytes to base64 string for storage
        final base64String = base64Encode(bytes);
        // Return as data URL for easy display
        final dataUrl = 'data:image/png;base64,$base64String';
        Navigator.pop(context, dataUrl);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            TextButton(
              onPressed: _clearSignature,
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: _saveSignature,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.description ?? 'Please sign in the box below',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),

            // Signature Pad
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Signature(
                  controller: _controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveSignature,
                      child: const Text('Save Signature'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
