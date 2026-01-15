import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/health_data.dart';
import '../models/user_model.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  Future<void> generateAndShareReport(
      UserModel user, List<HealthData> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(user),
          pw.SizedBox(height: 20),
          _buildSummary(data),
          pw.SizedBox(height: 20),
          _buildDataTable(data),
          pw.SizedBox(height: 40),
          _buildFooter(),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'rapport_dalys_${user.nom}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  pw.Widget _buildHeader(UserModel user) {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('DALYS - Rapport de Santé Respiratoire',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Généré le : ${DateTime.now().toString().split('.')[0]}'),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('${user.prenom} ${user.nom}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(user.email),
              if (user.telephone != null) pw.Text(user.telephone!),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummary(List<HealthData> data) {
    if (data.isEmpty)
      return pw.Text('Aucune donnée disponible pour la période.');

    final avgSpo2 =
        data.map((e) => e.spo2).reduce((a, b) => a + b) / data.length;
    final minSpo2 = data.map((e) => e.spo2).reduce((a, b) => a < b ? a : b);

    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Résumé de la période',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text('Nombre de mesures : ${data.length}'),
          pw.Text('SpO2 moyenne : ${avgSpo2.toStringAsFixed(1)}%'),
          pw.Text('SpO2 minimale : $minSpo2%',
              style: pw.TextStyle(
                  color: minSpo2 < 92 ? PdfColors.red : PdfColors.black)),
        ],
      ),
    );
  }

  pw.Widget _buildDataTable(List<HealthData> data) {
    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'SpO2 (%)', 'Fréq. Resp.', 'Temp.', 'Risque'],
      data: data.map((e) {
        return [
          e.date.toString().split(' ')[0],
          e.spo2.toString(),
          e.breathingRate.toString(),
          e.temperature?.toStringAsFixed(1) ?? '-',
          e.riskLevel.toString().split('.').last,
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 25,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
      },
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          'Note : Ce document est généré automatiquement par l\'application DALYS. '
          'Il est destiné à faciliter la consultation médicale et ne remplace pas l\'avis d\'un professionnel.',
          style:
              const pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}
