import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../../../core/sync/sync_status_controller.dart';
import '../../../core/utils/app_snackbars.dart';
import '../models/import_rows.dart';
import '../services/backup_service.dart';
import '../services/import_service.dart';
import '../services/spreadsheet_format.dart';

/// Import from Excel and full backups, from Settings.
class DataTransferController extends GetxController {
  final ImportService _importService = ImportService();
  final BackupService _backupService = BackupService();
  final SyncStatusController _sync = Get.find<SyncStatusController>();
  final String userId;

  DataTransferController(this.userId);

  final RxBool isBusy = false.obs;

  /// The file picked for import and what was read from it.
  final Rxn<ImportPreview> preview = Rxn<ImportPreview>();
  final RxString fileName = ''.obs;

  Future<void> pickFile() async {
    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );
    } catch (_) {
      showErrorSnackbar('Could not open the file picker.');
      return;
    }
    if (file == null) return;

    try {
      isBusy.value = true;
      final bytes = await file.xFile.readAsBytes();
      preview.value = SpreadsheetFormat.parse(bytes);
      fileName.value = file.name;
    } on FormatException catch (e) {
      clearFile();
      showErrorSnackbar(e.message);
    } catch (_) {
      clearFile();
      showErrorSnackbar('Could not read that file. Please try again.');
    } finally {
      isBusy.value = false;
    }
  }

  void clearFile() {
    preview.value = null;
    fileName.value = '';
  }

  /// Saves the previewed rows. Returns what was saved, or null on failure.
  Future<ImportResult?> confirmImport() async {
    final rows = preview.value;
    if (rows == null || rows.isEmpty) return null;

    try {
      isBusy.value = true;
      final (:result, :write) = await _importService.import(userId, rows);
      await _sync.commit(write);
      clearFile();
      return result;
    } catch (_) {
      showErrorSnackbar('Could not import. Nothing was saved.');
      return null;
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> shareTemplate() => _run(
    () => _backupService.share(
      _backupService.buildTemplate(),
      'profitpulse_import_template.xlsx',
      'ProfitPulse import template',
    ),
    'Could not create the template. Please try again.',
  );

  Future<void> shareBackup() => _run(() async {
    final bytes = await _backupService.buildBackup(userId);
    final now = DateTime.now();
    final stamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    await _backupService.share(
      bytes,
      'profitpulse_backup_$stamp.xlsx',
      'ProfitPulse backup $stamp',
    );
  }, 'Could not create the backup. Please try again.');

  Future<void> _run(Future<void> Function() action, String error) async {
    if (isBusy.value) return;
    try {
      isBusy.value = true;
      await action();
    } catch (_) {
      showErrorSnackbar(error);
    } finally {
      isBusy.value = false;
    }
  }
}
