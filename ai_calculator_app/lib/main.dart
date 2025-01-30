import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

String apiKey = 'AIzaSyDPfprY35lzwWWLKaZC8Aoc__vwwvqTjYA';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Gemini.reInitialize(apiKey: apiKey);
  runApp(const PaintCalculatorApp());
}

class PaintCalculatorApp extends StatelessWidget {
  const PaintCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
            title: Text('Paint Calculator',
                style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 30,
                    fontFamily: 'ArchitectsDaughter'))),
        body: const PaintCanvas(),
      ),
    );
  }
}

class PaintCanvas extends StatefulWidget {
  const PaintCanvas({super.key});

  @override
  PaintCanvasState createState() => PaintCanvasState();
}

class PaintCanvasState extends State<PaintCanvas> {
  final List<Offset?> _points = [];
  final List<ResultData> _results = [];
  final GlobalKey _canvasKey = GlobalKey();
  Uint8List? _imageBytes;

  late Gemini gemini;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    gemini = Gemini.instance;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _points.add(details.localPosition);
        });
        // Reset timer on drawing
        _timer?.cancel();
        _timer = Timer(const Duration(seconds: 4), () {
          captureAndSend();
        });
      },
      onPanEnd: (details) {
        _points.add(null);
      },
      child: RepaintBoundary(
        key: _canvasKey,
        child: CustomPaint(
          painter: CanvasPainter(_points, _results),
          size: Size(
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height,
          ),
        ),
      ),
    );
  }

  Future<void> captureAndSend() async {
    try {
      RenderRepaintBoundary boundary = _canvasKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      _imageBytes = byteData?.buffer.asUint8List();

      if (_imageBytes == null) return;

      // Get the size of the image for later calculations
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      // Call Gemini API for image and text processing
      setState(() {
        _results.clear();
        _results.add(ResultData("Processing...", const Offset(10, 10)));
      });

      // Use the modified prompt with image dimensions
      final response = await gemini.textAndImage(
        text: '''
"You have been given an image containing mathematical expressions, equations, or graphical problems. 
Please analyze the content of the image and return the answers with their precise positions in an ARRAY format. 
The format should be: [{'result': answer, 'position': [x, y]}] — an array of dictionaries, each with the calculated answer and the position (x, y) where the answer should appear.

Do not include 'json' or other keywords, just the array.

**Positioning:**
- The x and y coordinates should be based on the canvas dimensions: width: ${imageSize.width}, height: ${imageSize.height}.
- Ensure that the x and y coordinates are relative to the top-left corner of the canvas (0, 0), not the image.
- For each equation, the answer should be placed to the right of the '=' symbol.
- If there's no space to the right, place the result directly below the equation.
- Ensure that the x and y coordinates for the results are positioned within the image boundaries and not outside.

**PEMDAS Rule:**
- Use the PEMDAS rule (Parentheses, Exponents, Multiplication and Division (from left to right), Addition and Subtraction (from left to right)) to solve any mathematical expressions.

**Examples:**
1. Simple Mathematical Expressions: Examples like 2 + 2, 3 * 4, 5 / 6, 7 - 8, etc. Solve and return the answer as [{'result': 'calculated answer', 'position': [x, y]}].
2. Set of Equations: Examples like x^2 + 2x + 1 = 0, 3y + 4x = 0, 5x^2 + 6y + 7 = 12, etc. Solve for the given variables and return in the format [{'result': 'x value', 'position': [x, y]}, {'result': 'y value', 'position': [x, y]}].
3. Assigning Values to Variables: Examples like x = 4, y = 5, z = 6. Assign values and return as [{'result': '4', 'position': [x, y]}].
4. Graphical Math Problems: For problems involving visual representations, return the answer as [{'result': 'calculated answer', 'position': [x, y]}].
5. Abstract Concepts: For drawings that represent abstract concepts like love, patriotism, historical events, etc., return an explanation in the format: [{'result': 'abstract concept', 'position': [x, y]}].

Use pre-assigned variable values from this dictionary if present: {dict_of_vars_str}.
Ensure that the results and their positions are clearly placed relative to the equations and within the image boundaries."
''',
        images: [_imageBytes!],
      );

      // Handle response
      setState(() {
        _results.clear();
        if (response != null && response.content != null) {
          final resultText = response.content!.parts?.last.text;

          // Log raw response for debugging
          log("Raw Response: $resultText");

          // Directly use the result text without modification
          List<ResultData> parsedResults = parseResponse(resultText);
          if (parsedResults.isNotEmpty) {
            _results.addAll(parsedResults);
          } else {
            _results.add(ResultData("No results found", const Offset(50, 50)));
          }
        } else {
          _results
              .add(ResultData("Error processing image", const Offset(50, 50)));
        }
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  List<ResultData> parseResponse(String? responseText) {
    List<ResultData> results = [];
    if (responseText == null || responseText.isEmpty) return results;

    try {
      // Log the raw response for debugging
      log("Raw Response: $responseText");

      // Ensure the response is treated as a JSON string
      String jsonString = responseText.trim();

      // Replace single quotes with double quotes to make it valid JSON
      jsonString = jsonString.replaceAll("'", '"');

      // Log the modified JSON string for debugging purposes
      log("Modified JSON: $jsonString");

      // Parse the corrected JSON string
      List<dynamic> parsedJson = jsonDecode(jsonString);

      for (var item in parsedJson) {
        // Get the result and position from the JSON item
        String result = item['result'].toString();
        List<dynamic> position = item['position'];

        // Check if the position is valid
        if (position.length == 2) {
          Offset offset = Offset(
            double.parse(position[0].toString()), // Parse x coordinate
            double.parse(position[1].toString()), // Parse y coordinate
          );
          results.add(ResultData(result, offset));
        } else {
          log("Invalid position array length: ${position.length}");
        }
      }
    } catch (e) {
      // Log the error for debugging purposes
      print("Error parsing response: $e");
    }

    return results;
  }
}

// Class to store result text and its position
class ResultData {
  final String text;
  final Offset position;

  ResultData(this.text, this.position);
}

// class CanvasPainter extends CustomPainter {
//   final List<Offset?> points;
//   final List<ResultData> results;

//   CanvasPainter(this.points, this.results);

//   @override
//   void paint(Canvas canvas, Size size) {
//     // Set a background color (black)
//     canvas.drawRect(
//       Rect.fromLTWH(0, 0, size.width, size.height),
//       Paint()..color = Colors.black,
//     );
//     Paint paint = Paint()
//       ..color = Colors.orange
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = 5.0;

//     for (int i = 0; i < points.length - 1; i++) {
//       if (points[i] != null && points[i + 1] != null) {
//         canvas.drawLine(points[i]!, points[i + 1]!, paint);
//       }
//     }

//     // Draw API results
//     TextStyle textStyle = TextStyle(
//         color: Colors.orange[800],
//         fontSize: 30,
//         fontFamily: 'ArchitectsDaughter');
//     for (var result in results) {
//       final textSpan = TextSpan(
//         text: result.text,
//         style: textStyle,
//       );
//       final textPainter = TextPainter(
//         text: textSpan,
//         textDirection: TextDirection.ltr,
//       );
//       textPainter.layout();
//       textPainter.paint(canvas, result.position);
//     }
//   }

//   @override
//   bool shouldRepaint(CanvasPainter oldDelegate) => true;
// }
class CanvasPainter extends CustomPainter {
  final List<Offset?> points;
  final List<ResultData> results;

  CanvasPainter(this.points, this.results);

  @override
  void paint(Canvas canvas, Size size) {
    // Set a background color (black)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );

    Paint paint = Paint()
      ..color = Colors.orange
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    // Draw lines (user's input)
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }

    // Draw results
    TextStyle textStyle = TextStyle(
      color: Colors.orange[800],
      fontSize: 30,
      fontFamily: 'ArchitectsDaughter',
    );

    for (var result in results) {
      final textSpan = TextSpan(
        text: result.text,
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Adjust the position to ensure the text doesn't get cut off.
      // For example, moving the result slightly to the right if it's too close to the left edge
      Offset adjustedPosition = result.position;

      // Ensure text doesn't go out of bounds horizontally
      if (result.position.dx + textPainter.width > size.width) {
        adjustedPosition =
            Offset(size.width - textPainter.width - 10, result.position.dy);
      }
      // Ensure text doesn't go out of bounds vertically
      if (result.position.dy + textPainter.height > size.height) {
        adjustedPosition =
            Offset(result.position.dx, size.height - textPainter.height - 10);
      }

      // Finally, paint the text on the canvas at the adjusted position
      textPainter.paint(canvas, adjustedPosition);
    }
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) => true;
}
