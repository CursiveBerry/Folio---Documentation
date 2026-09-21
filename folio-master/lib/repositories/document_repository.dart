import '../core/database_helper.dart';
import '../models/folder_model.dart';
import '../models/document_model.dart';
import '../models/page_model.dart';

class DocumentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Folder>> getFolders() => _dbHelper.getAllFolders();

  Future<int> createFolder(String name) {
    final folder = Folder(name: name, createdAt: DateTime.now());
    return _dbHelper.insertFolder(folder);
  }

  Future<List<Document>> getRecentDocuments() => _dbHelper.getRecentDocuments();

  Future<List<Document>> getDocumentsInFolder(int folderId) =>
      _dbHelper.getDocumentsByFolder(folderId);

  Future<int> createDocument(int folderId, String name) {
    final doc = Document(
      folderId: folderId,
      name: name,
      createdAt: DateTime.now(),
    );
    return _dbHelper.insertDocument(doc);
  }

  Future<int> addPage(PageModel page) => _dbHelper.insertPage(page);

  Future<List<PageModel>> getPages(int documentId) =>
      _dbHelper.getPagesByDocument(documentId);

  Future<int> deleteDocument(int id) => _dbHelper.deleteDocument(id);

  Future<void> deleteFolder(int folderId) async {
    final db = await _dbHelper.database;

    // Find the "Uncategorized" folder ID dynamically
    final uncategorizedResult = await db.query(
      'folders',
      where: 'name = ?',
      whereArgs: ['Uncategorized'],
      limit: 1,
    );

    if (uncategorizedResult.isNotEmpty) {
      final int uncategorizedId = uncategorizedResult.first['id'] as int;

      // Prevent deleting the Uncategorized folder entirely
      if (folderId == uncategorizedId) return;

      // Reassign all documents in the folder being deleted to "Uncategorized"
      await db.update(
        'documents',
        {'folderId': uncategorizedId},
        where: 'folderId = ?',
        whereArgs: [folderId],
      );
    }

    // Safely delete the empty folder
    await _dbHelper.deleteFolder(folderId);
  }

  Future<int> updatePage(PageModel page) => _dbHelper.updatePage(page);

  Future<int> updateDocument(Document doc) => _dbHelper.updateDocument(doc);

  Future<int> updateFolder(Folder folder) => _dbHelper.updateFolder(folder);

  Future<int> deletePage(int id) => _dbHelper.deletePage(id);
}
