import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:ADDvEEG/utils/reportGenerator/save_file_mobile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../models/chart_data.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:image/image.dart' as img;
import '../../models/quiz/new_quiz_models.dart';
import '../../models/profile_model.dart';
import '../../screens/doctorScreens/patientDetailedView(DocEnd).dart';

final chartData = <ChartData>[];
Future<void> generateQuizReport(RxList<Map<String, dynamic>> quizHistory, Profile profile) async {
  chartData.clear(); // Clear previous data
  chartData.addAll(quizHistory.map((e) => ChartData(
      DateTime.tryParse(e['completedAt'] ?? e['createdAt'] ?? '') ?? DateTime.now(),
      e['score'] ?? 0,
      e['questionnaireType'] ?? 'Unknown')));
  print('Quiz scores: ${quizHistory.map((e) => e['score'])}');
  //Create a PDF document.
  final PdfDocument document = PdfDocument();
  //Add page to the PDF
  final PdfPage page = document.pages.add();
  //Get page client size
  final Size pageSize = page.getClientSize();
  //Draw rectangle
  page.graphics.drawRectangle(
      bounds: Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
      pen: PdfPen(PdfColor(142, 170, 219)));
  //Generate PDF grid.
  final PdfGrid grid = getGrid(quizHistory);
  //Draw the header section by creating text element
  final PdfLayoutResult result = drawHeader(page, pageSize, grid, profile);
  //Draw grid
  drawGrid(page, grid, result);
  //Add invoice footer
  drawFooter(page, pageSize);
  //Save the PDF document

  final List<int> bytes = document.saveSync();
  //Dispose the document.
  // await createGraph(quiz, page, document);
  document.dispose();
  //Save and launch the file.
  await saveAndLaunchFile(bytes, '${profile.name}_${DateTime.now()}.pdf');
}

//Draws the invoice header
PdfLayoutResult drawHeader(
    PdfPage page, Size pageSize, PdfGrid grid, Profile profile) {
  //Draw rectangle
  page.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(91, 126, 215)),
      bounds: Rect.fromLTWH(0, 0, pageSize.width - 0, 90));
  //Draw string
  page.graphics.drawString('Quiz Report for ${profile.name ?? profile.firstName ?? 'Patient'}',
      PdfStandardFont(PdfFontFamily.helvetica, 30),
      brush: PdfBrushes.white,
      bounds: Rect.fromLTWH(25, 0, pageSize.width - 115, 90),
      format: PdfStringFormat(lineAlignment: PdfVerticalAlignment.middle));

  final PdfFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 9);
  final Size contentSize = contentFont.measureString('');
  String address =
      'Name: ${profile.name ?? profile.firstName ?? 'Not provided'}\r\n'
      'Email: ${profile.email ?? 'Not provided'}\r\n\r\n'
      'Report Generated: ${DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now())}';
  return PdfTextElement(text: address, font: contentFont).draw(
      page: page,
      bounds: Rect.fromLTWH(30, 120, pageSize.width - (contentSize.width + 30),
          pageSize.height))!;
}

//Draws the grid
void drawGrid(PdfPage page, PdfGrid grid, PdfLayoutResult result) {
  Rect? totalPriceCellBounds;
  Rect? quantityCellBounds;
  grid.beginCellLayout = (Object sender, PdfGridBeginCellLayoutArgs args) {
    final PdfGrid grid = sender as PdfGrid;
    if (args.cellIndex == grid.columns.count - 1) {
      totalPriceCellBounds = args.bounds;
    } else if (args.cellIndex == grid.columns.count - 2) {
      quantityCellBounds = args.bounds;
    }
  };
  result = grid.draw(
      page: page, bounds: Rect.fromLTWH(0, result.bounds.bottom + 40, 0, 0))!;
}

void drawFooter(PdfPage page, Size pageSize) {
  final PdfPen linePen =
      PdfPen(PdfColor(142, 170, 219), dashStyle: PdfDashStyle.custom);
  linePen.dashPattern = <double>[3, 3];
  
  // Add summary statistics
  final totalQuizzes = chartData.length;
  final averageScore = totalQuizzes > 0 
      ? (chartData.map((e) => (e.y ?? 0).toDouble()).reduce((a, b) => a + b) / totalQuizzes).toStringAsFixed(1)
      : '0';
  final highestScore = totalQuizzes > 0 
      ? chartData.map((e) => e.y ?? 0).reduce((a, b) => a > b ? a : b).toString()
      : '0';
  
  // Summary box
  page.graphics.drawRectangle(
    bounds: Rect.fromLTWH(30, pageSize.height - 120, pageSize.width - 60, 80),
    brush: PdfSolidBrush(PdfColor(245, 245, 245)),
    pen: PdfPen(PdfColor(200, 200, 200))
  );
  
  page.graphics.drawString(
    'SUMMARY STATISTICS',
    PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
    bounds: Rect.fromLTWH(40, pageSize.height - 110, pageSize.width - 80, 20)
  );
  
  page.graphics.drawString(
    'Total Assessments: $totalQuizzes  |  Average Score: $averageScore  |  Highest Score: $highestScore',
    PdfStandardFont(PdfFontFamily.helvetica, 10),
    bounds: Rect.fromLTWH(40, pageSize.height - 90, pageSize.width - 80, 20)
  );
  
  // Footer text
  page.graphics.drawString(
    'This report is generated by ADDvEEG Medical System - Confidential Medical Document',
    PdfStandardFont(PdfFontFamily.helvetica, 8),
    brush: PdfBrushes.gray,
    bounds: Rect.fromLTWH(30, pageSize.height - 30, pageSize.width - 60, 20),
    format: PdfStringFormat(alignment: PdfTextAlignment.center)
  );
}

//Create PDF grid and return
PdfGrid getGrid(RxList<Map<String, dynamic>> quizHistory) {
  print('GetGrid Called');
  final PdfGrid grid = PdfGrid();
  grid.columns.add(count: 4);

  final PdfGridRow headerRow = grid.headers.add(1)[0];

  headerRow.style.backgroundBrush = PdfSolidBrush(PdfColor(68, 114, 196));
  headerRow.style.textBrush = PdfBrushes.white;
  headerRow.cells[0].value = 'Quiz Type';
  headerRow.cells[0].stringFormat.alignment = PdfTextAlignment.center;
  headerRow.cells[1].value = 'Date & Time';
  headerRow.cells[2].value = 'Status';
  headerRow.cells[3].value = 'Score';
  
  for (int i = 0; i < quizHistory.length; i++) {
    final quiz = quizHistory[i];
    addQuizItem(
      quiz['questionnaireType']?.toString() ?? 'Unknown',
      DateTime.tryParse(quiz['completedAt'] ?? quiz['createdAt'] ?? '') ?? DateTime.now(),
      quiz['status']?.toString() ?? 'completed',
      quiz['score'] ?? 0,
      grid
    );
  }
  grid.applyBuiltInStyle(PdfGridBuiltInStyle.listTable4Accent5);

  grid.columns[1].width = 200;
  for (int i = 0; i < headerRow.cells.count; i++) {
    headerRow.cells[i].style.cellPadding =
        PdfPaddings(bottom: 5, left: 5, right: 5, top: 5);
  }
  for (int i = 0; i < grid.rows.count; i++) {
    final PdfGridRow row = grid.rows[i];
    for (int j = 0; j < row.cells.count; j++) {
      final PdfGridCell cell = row.cells[j];
      if (j == 0) {
        cell.stringFormat.alignment = PdfTextAlignment.center;
      }
      cell.style.cellPadding =
          PdfPaddings(bottom: 5, left: 5, right: 5, top: 5);
    }
  }
  return grid;
}

GlobalKey chartContainerKey = GlobalKey();
createGraph(Rx<QuizHistoryResponse> quiz, PdfPage page, PdfDocument pdf) async {
  // Add a separate page with the graph
  final graphPage = pdf.pages.add();
  final graphBounds = Rect.fromLTWH(
      0, 0, graphPage.getClientSize().width, graphPage.getClientSize().height);
  final chart = RepaintBoundary(
    key: chartContainerKey,
    child: SfCartesianChart(
      key: chartContainerKey,
      primaryXAxis: DateTimeAxis(
          // intervalType: DateTimeIntervalType.hours,
          ),
      series: <CartesianSeries<dynamic, dynamic>>[
        LineSeries<ChartData, DateTime>(
          dataSource: chartData,
          pointColorMapper: (ChartData data, _) =>
              data.y! > 15 ? Colors.red : Colors.green,
          name: 'Score',
          onPointTap: (pointInteractionDetails) =>
              print('${pointInteractionDetails.pointIndex}'),
          xValueMapper: (ChartData data, _) =>
              DateTime(data.x.year, data.x.month, data.x.day, data.x.hour),
          yValueMapper: (ChartData data, _) => data.y,
          dataLabelSettings: DataLabelSettings(isVisible: true),
          markerSettings: MarkerSettings(isVisible: true),
          dataLabelMapper: (datum, index) =>
              '${datum.type.toString()} , Score: ${datum.y.toString()}',
        )
      ],
    ),
  );
  // Capture a screenshot of the chart widget
  RenderRepaintBoundary boundary = await chartContainerKey.currentContext!
      .findRenderObject() as RenderRepaintBoundary;
  ui.Image chartImage = await boundary.toImage(pixelRatio: 3.0);
  ByteData? byteData =
      await chartImage.toByteData(format: ui.ImageByteFormat.png);
  Uint8List screenshotBytes = byteData!.buffer.asUint8List();

  // Create an Image object from the screenshot
  final chartImageWidget = Image.memory(screenshotBytes);

  // Add the chart image to the PDF document
  final pdfImage = PdfBitmap(chartImageWidget as List<int>);
  page.graphics.drawImage(
    pdfImage,
    Rect.fromLTWH(
        0, 0, page.getClientSize().width, page.getClientSize().height),
  );
}

//Create and row for the grid.
void addQuizItem(String QuizType, DateTime dateTime, String status, int score, PdfGrid grid) {
  print('addQuizItem Called');
  final PdfGridRow row = grid.rows.add();
  row.cells[0].value = QuizType;
  final DateFormat format = DateFormat.yMMMMd('en_US').add_Hm();
  row.cells[1].value = format.format(dateTime);
  row.cells[2].value = status.toUpperCase();
  row.cells[3].value = score.toString();
}
