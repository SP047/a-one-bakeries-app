import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// ============================================================================
/// REPORT EXPORT SERVICE - A-One Bakeries
/// ============================================================================
/// 
/// Exports reports to Excel (.xlsx) and PDF formats.
/// Files are saved to the user's Documents/A-One Bakeries/Reports directory.
/// 
/// Features:
/// - ✅ Excel export with formatting
/// - ✅ PDF export with tables
/// - ✅ Summary sections
/// - ✅ Automatic file naming with timestamps
/// - ✅ User-accessible save location
/// 
/// Example:
/// ```dart
/// final service = ReportExportService();
/// final path = await service.exportToExcel(
///   reportTitle: 'Income Report',
///   headers: ['Date', 'Amount'],
///   rows: [['2024-01-01', 1000]],
/// );
/// ```
/// ============================================================================

class ReportExportService {
  ReportExportService();
  
  /// Export data to Excel (.xlsx) format
  /// 
  /// Creates a formatted Excel spreadsheet with:
  /// - Title row with bold formatting
  /// - Header row with background color
  /// - Data rows
  /// - Optional summary section
  /// 
  /// Returns the file path where the Excel file was saved.
  Future<String> exportToExcel({
    required String reportTitle,
    required List<String> headers,
    required List<List<dynamic>> rows,
    String? summaryTitle,
    List<String>? summaryLabels,
    List<dynamic>? summaryValues,
  }) async {
    try {
      // Create Excel document
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
      currentRow += 2; // Skip a row
      
      // Add headers with styling
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.blue,
            fontColorHex: ExcelColor.white,
          );
      }
      currentRow++;
      
      // Add data rows
      for (var row in rows) {
        for (int i = 0; i < row.length; i++) {
          final cellValue = row[i];
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
          
          // Format based on type
          if (cellValue is DateTime) {
            cell.value = TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(cellValue));
          } else if (cellValue is num) {
            cell.value = DoubleCellValue(cellValue.toDouble());
          } else {
            cell.value = TextCellValue(cellValue.toString());
          }
        }
        currentRow++;
      }
      
      // Add summary section if provided
      if (summaryTitle != null && summaryLabels != null && summaryValues != null) {
        currentRow += 2; // Skip rows
        
        // Summary title
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          ..value = TextCellValue(summaryTitle)
          ..cellStyle = CellStyle(bold: true, fontSize: 14);
        currentRow++;
        
        // Summary data
        for (int i = 0; i < summaryLabels.length; i++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            ..value = TextCellValue(summaryLabels[i])
            ..cellStyle = CellStyle(bold: true);
          
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
            .value = TextCellValue(summaryValues[i].toString());
          currentRow++;
        }
      }
      
      // Auto-fit columns (approximate)
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }
      
      // Save file
      final directory = await _getReportsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '${reportTitle.replaceAll(' ', '_')}_$timestamp.xlsx';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);
      
      return filePath;
    } catch (e) {
      throw Exception('Failed to export to Excel: $e');
    }
  }
  
  /// Export data to PDF format
  /// 
  /// Creates a PDF document with:
  /// - Title header
  /// - Formatted table
  /// - Optional summary section
  /// 
  /// Saves the PDF to the Reports directory.
  Future<String> exportToPdf({
    required String reportTitle,
    required List<String> headers,
    required List<List<dynamic>> rows,
    String? summaryTitle,
    List<String>? summaryLabels,
    List<String>? summaryValues,
  }) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return [
              // Title
              pw.Header(
                level: 0,
                child: pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Table
              pw.Table.fromTextArray(
                headers: headers,
                data: rows.map((row) {
                  return row.map((cell) {
                    if (cell is DateTime) {
                      return DateFormat('yyyy-MM-dd HH:mm').format(cell);
                    }
                    return cell.toString();
                  }).toList();
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(8),
                border: pw.TableBorder.all(),
              ),
              
              // Summary section
              if (summaryTitle != null && summaryLabels != null && summaryValues != null) ...[
                pw.SizedBox(height: 30),
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    summaryTitle,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                ...List.generate(summaryLabels.length, (i) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      children: [
                        pw.Text(
                          '${summaryLabels[i]}: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(summaryValues[i].toString()),
                      ],
                    ),
                  );
                }),
              ],
              
              // Footer with timestamp
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Text(
                'Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey,
                ),
              ),
            ];
          },
        ),
      );
      
      // Save file
      final directory = await _getReportsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '${reportTitle.replaceAll(' ', '_')}_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      return filePath;
    } catch (e) {
      throw Exception('Failed to export to PDF: $e');
    }
  }
  
  /// Get or create the Reports directory
  /// 
  /// Creates: Documents/A-One Bakeries/Reports/
  /// This location is user-accessible and backed up.
  Future<Directory> _getReportsDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${documentsDir.path}/A-One Bakeries/Reports');
    
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    
    return reportsDir;
  }
}
