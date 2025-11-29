import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

/// Report Export Service
/// 
/// Handles Excel and PDF export for all report types

class ReportExportService {
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'R ');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  // ============================================================================
  // EXCEL EXPORT
  // ============================================================================

  /// Export data to Excel file
  Future<String> exportToExcel({
    required String reportTitle,
    required List<String> headers,
    required List<List<dynamic>> rows,
    String? summaryTitle,
    List<String>? summaryLabels,
    List<dynamic>? summaryValues,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Report'];

    // Remove default sheet
    excel.delete('Sheet1');

    int currentRow = 0;

    // Add title
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
      ..value = TextCellValue(reportTitle)
      ..cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
      );
    currentRow += 2;

    // Add generation date
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
      ..value = TextCellValue('Generated: ${_dateFormat.format(DateTime.now())}')
      ..cellStyle = CellStyle(fontSize: 10);
    currentRow += 2;

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow))
        ..value = TextCellValue(headers[i])
        ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
        );
    }
    currentRow++;

    // Add data rows
    for (var row in rows) {
      for (int i = 0; i < row.length; i++) {
        final value = row[i];
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
        
        if (value is num) {
          cell.value = DoubleCellValue(value.toDouble());
        } else if (value is DateTime) {
          cell.value = TextCellValue(_dateFormat.format(value));
        } else {
          cell.value = TextCellValue(value?.toString() ?? '');
        }
      }
      currentRow++;
    }

    // Add summary if provided
    if (summaryTitle != null && summaryLabels != null && summaryValues != null) {
      currentRow += 2;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        ..value = TextCellValue(summaryTitle)
        ..cellStyle = CellStyle(bold: true, fontSize: 14);
      currentRow += 1;

      for (int i = 0; i < summaryLabels.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          ..value = TextCellValue(summaryLabels[i])
          ..cellStyle = CellStyle(bold: true);
        
        final value = summaryValues[i];
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
        
        if (value is num) {
          cell.value = DoubleCellValue(value.toDouble());
        } else {
          cell.value = TextCellValue(value?.toString() ?? '');
        }
        currentRow++;
      }
    }

    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${reportTitle.replaceAll(' ', '_').replaceAll('/', '_')}_$timestamp.xlsx';
    final filePath = '${directory.path}/$fileName';
    
    final fileBytes = excel.encode();
    final file = File(filePath);
    await file.writeAsBytes(fileBytes!);

    return filePath;
  }

  // ============================================================================
  // PDF EXPORT
  // ============================================================================

  /// Export data to PDF file
  Future<void> exportToPdf({
    required String reportTitle,
    required List<String> headers,
    required List<List<dynamic>> rows,
    String? summaryTitle,
    List<String>? summaryLabels,
    List<dynamic>? summaryValues,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Title
          pw.Header(
            level: 0,
            child: pw.Text(
              reportTitle,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          
          // Generation date
          pw.Text(
            'Generated: ${_dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
          pw.SizedBox(height: 20),

          // Data table
          pw.Table.fromTextArray(
            headers: headers,
            data: rows.map((row) {
              return row.map((cell) {
                if (cell is DateTime) {
                  return _dateFormat.format(cell);
                } else if (cell is num) {
                  return cell.toString();
                }
                return cell?.toString() ?? '';
              }).toList();
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey800,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(5),
          ),

          // Summary section
          if (summaryTitle != null && summaryLabels != null && summaryValues != null) ...[
            pw.SizedBox(height: 30),
            pw.Text(
              summaryTitle,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: List.generate(summaryLabels.length, (i) {
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        summaryLabels[i],
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(summaryValues[i]?.toString() ?? ''),
                    ),
                  ],
                );
              }),
            ),
          ],
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),
      ),
    );

    // Print or share PDF
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  /// Share Excel file
  Future<void> shareExcelFile(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Report generated by A-One Bakeries App',
    );
  }
}
