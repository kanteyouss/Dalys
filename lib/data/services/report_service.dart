import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/health_data.dart';
import '../models/user_model.dart';
import 'package:intl/intl.dart';

class ReportService {
  Future<void> generateAndShareReport({
    required UserModel user,
    required List<HealthData> data,
  }) async {
    final pdf = await _generatePdf(user, data);
    final bytes = await pdf.save();

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/rapport_sante_dalys.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Rapport de santé DALYS - ${user.prenom} ${user.nom}',
    );
  }

  Future<void> generateAndPrintReport({
    required UserModel user,
    required List<HealthData> data,
  }) async {
    final pdf = await _generatePdf(user, data);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Rapport_Sante_DALYS',
    );
  }

  Future<pw.Document> _generatePdf(
      UserModel user, List<HealthData> data) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('RAPPORT DE SANTE DALYS',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Patient: ${user.prenom} ${user.nom}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Email: ${user.email}'),
                if (user.telephone != null) pw.Text('Tel: ${user.telephone}'),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Historique des mesures récentes',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: [
                'Date',
                'SpO2 (%)',
                'Respiration (bpm)',
                'PEF (L/min)',
                'Risque'
              ],
              data: data.map((d) {
                return [
                  dateFormat.format(d.date),
                  '${d.spo2}%',
                  '${d.breathingRate}',
                  '${d.pef.toInt()}',
                  d.riskLevel.toString().split('.').last.toUpperCase(),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 30),
            pw.Text('Contacts Médicaux',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            if (user.doctorEmail != null)
              pw.Text('Médecin Traitant: ${user.doctorEmail}'),
            if (user.hospitalEmail != null)
              pw.Text('Hôpital: ${user.hospitalEmail}'),
            pw.SizedBox(height: 40),
            pw.Footer(
              trailing: pw.Text('Généré par DALYS - E-Santé 4.0'),
            ),
          ];
        },
      ),
    );

    return pdf;
  }
}
