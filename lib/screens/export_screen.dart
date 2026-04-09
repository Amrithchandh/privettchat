import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/message.dart';
import '../services/chat_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _chatService = ChatService();
  bool _isExporting = false;

  Future<void> _exportAsPdf() async {
    setState(() => _isExporting = true);
    try {
      // Get all messages directly via Future in a real scenario, but for now we listen to stream once
      final stream = _chatService.getMessages();
      final messages = await stream.first; 

      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(level: 0, child: pw.Text("Private Chat Export Document")),
            ...messages.reversed.map((msg) {
              final time = DateFormat('yyyy-MM-dd HH:mm').format(msg.timestamp);
              final sender = msg.senderId.length > 5 ? msg.senderId.substring(0, 5) : msg.senderId;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('[$time] $sender:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(msg.text, style: const pw.TextStyle(fontSize: 12)),
                    if (msg.mediaUrl != null) pw.Text("[Media Attachment]", style: pw.TextStyle(fontSize: 10, color: PdfColors.blue)),
                  ]
                )
              );
            })
          ]
        )
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/chat_export_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported successfully to: ${file.path}'))
        );
        // You can use the 'printing' package to share/print it directly
        await Printing.sharePdf(bytes: await pdf.save(), filename: 'chat_export.pdf');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'))
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Export Chat Data")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 20),
            const Text(
              "Keep a backup of your conversations.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportAsPdf,
              icon: _isExporting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.download),
              label: const Text("Export Full Chat to PDF"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
