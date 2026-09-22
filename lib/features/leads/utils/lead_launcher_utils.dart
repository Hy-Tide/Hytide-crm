import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class LeadLauncherUtils {
  static Future<void> launchPhone(BuildContext context, String phone) async {
    final clean = phone.trim();
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (context.mounted) {
        await _copyToClipboard(context, clean, 'Phone copied to clipboard');
      }
    } catch (_) {
      if (context.mounted) {
        await _copyToClipboard(context, clean, 'Phone copied to clipboard');
      }
    }
  }

  static Future<void> launchWhatsApp(BuildContext context, String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        await _copyToClipboard(context, phone, 'WhatsApp phone copied to clipboard');
      }
    } catch (_) {
      if (context.mounted) {
        await _copyToClipboard(context, phone, 'WhatsApp phone copied to clipboard');
      }
    }
  }

  static Future<void> launchEmail(BuildContext context, String email) async {
    final clean = email.trim();
    if (clean.isEmpty) return;
    final uri = Uri.parse('mailto:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (context.mounted) {
        await _copyToClipboard(context, clean, 'Email copied to clipboard');
      }
    } catch (_) {
      if (context.mounted) {
        await _copyToClipboard(context, clean, 'Email copied to clipboard');
      }
    }
  }

  static Future<void> _copyToClipboard(BuildContext context, String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
