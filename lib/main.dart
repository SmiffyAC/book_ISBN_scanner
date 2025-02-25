import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'api_key.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barcode Scanner Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BarcodeScannerScreen(),
    );
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  // Controller to manage camera behavior
  final MobileScannerController controller = MobileScannerController();

  // Replace this with your actual Google Books API key
  final String _googleBooksApiKey = googleBooksApiKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (barcode, args) async {
              final String? code = barcode.rawValue;
              if (code == null) {
                debugPrint('Failed to scan Barcode');
                return;
              }

              debugPrint('Barcode found! $code');

              // Attempt to fetch book details from Google Books
              final bookData = await fetchBookData(code, _googleBooksApiKey);

              if (!mounted) return; // Ensure widget is still in the tree

              if (bookData == null) {
                // Show a simple dialog or message that nothing was found
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('No Book Found'),
                    content: Text('No book data was found for ISBN: $code'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } else {
                // If we have book data, show it in a dialog
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(bookData['title'] ?? 'Unknown Title'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Authors: ${bookData['authors']?.join(', ') ?? 'N/A'}'),
                        Text('Page Count: ${bookData['pageCount'] ?? 'N/A'}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          // Optionally, place an overlay or crosshair widget here on top of the camera preview
        ],
      ),
    );
  }
}

/// Fetches basic book data (title, authors, pageCount) from Google Books,
/// given an ISBN and your Google Books API key.
/// Returns null if no book info is found.
Future<Map<String, dynamic>?> fetchBookData(String isbn, String apiKey) async {
  final Uri url = Uri.parse(
    'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn&key=$apiKey',
  );

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      // If 'items' is null or empty, no book was found.
      if (data['items'] != null && (data['items'] as List).isNotEmpty) {
        final volumeInfo = data['items'][0]['volumeInfo'] as Map<String, dynamic>;
        return {
          'title': volumeInfo['title'] ?? 'No Title Found',
          'authors': volumeInfo['authors'] ?? ['Unknown Author'],
          'pageCount': volumeInfo['pageCount'] ?? 0,
        };
      }
    } else {
      debugPrint('Failed to load data: ${response.reasonPhrase}');
    }
  } catch (e) {
    debugPrint('Error fetching book data: $e');
  }

  return null;
}
