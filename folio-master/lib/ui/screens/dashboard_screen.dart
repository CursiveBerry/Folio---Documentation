import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../blocs/scanner/scanner_bloc.dart';
import '../../blocs/scanner/scanner_event.dart';
import '../../repositories/document_repository.dart';
import '../../models/document_model.dart';
import '../../models/folder_model.dart';
import '../widgets/document_list_tile.dart';
import '../widgets/folder_list_tile.dart';
import 'scanner_screen.dart';
import 'document_detail_screen.dart';
import 'documents_by_folder_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neonGreen = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0D),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: neonGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.fingerprint, color: neonGreen, size: 24),
            ),
            const SizedBox(width: 10),
            const Text(
              'FOLIO',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0F0D),
        elevation: 0,
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardInitial || state is DashboardLoading) {
            return Center(child: CircularProgressIndicator(color: neonGreen));
          }
          if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<DashboardBloc>().add(LoadDashboard()),
                    child: Text('Retry', style: TextStyle(color: neonGreen)),
                  ),
                ],
              ),
            );
          }
          if (state is DashboardLoaded) {
            // Filter folders and documents based on search query
            final filteredFolders = state.folders
                .where(
                  (f) =>
                      f.name.toLowerCase().contains(_searchQuery.toLowerCase()),
                )
                .toList();

            final filteredDocs = state.recentDocuments
                .where(
                  (d) =>
                      d.name.toLowerCase().contains(_searchQuery.toLowerCase()),
                )
                .toList();

            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Search Bar Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search files by name...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        prefixIcon: Icon(Icons.search, color: neonGreen),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.white54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF121814),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: neonGreen, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),

                _buildHeader(
                  'Folders (${filteredFolders.length})',
                  onAdd: () => _showAddFolderDialog(context),
                ),
                _buildFolderList(filteredFolders),
                _buildHeader('Recent Documents (${filteredDocs.length})'),
                _buildRecentList(filteredDocs),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          }
          return const Center(
            child: Text(
              'Initializing...',
              style: TextStyle(color: Colors.white54),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<ScannerBloc>().add(ResetScanner());
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
          );
        },
        backgroundColor: neonGreen,
        label: const Text(
          'New Scan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF),
          ),
        ),
        icon: const Icon(
          Icons.document_scanner_rounded,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, {VoidCallback? onAdd}) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
            if (onAdd != null)
              IconButton(
                onPressed: onAdd,
                icon: Icon(
                  Icons.create_new_folder_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderList(List<Folder> folders) {
    if (folders.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'No folders found.',
            style: TextStyle(
              color: Colors.white38,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final folder = folders[index];
          return FolderListTile(
            folder: folder,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DocumentsByFolderScreen(folder: folder),
              ),
            ),
            onDelete: () =>
                context.read<DashboardBloc>().add(DeleteFolder(folder.id!)),
          );
        }, childCount: folders.length),
      ),
    );
  }

  Widget _buildRecentList(List<Document> documents) {
    if (documents.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'No matching files found. Tap "New Scan" to start.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white38,
              ),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final doc = documents[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Hero(
              tag: 'doc_${doc.id}',
              child: DocumentListTile(
                doc: doc,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DocumentDetailScreen(
                      document: doc,
                      repository: context.read<DocumentRepository>(),
                    ),
                  ),
                ),
                onDelete: () =>
                    context.read<DashboardBloc>().add(DeleteDocument(doc.id!)),
              ),
            ),
          );
        }, childCount: documents.length),
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    final neonGreen = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121814),
        title: const Text('New Folder', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Folder Name',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: neonGreen),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<DashboardBloc>().add(AddFolder(controller.text));
                Navigator.pop(ctx);
              }
            },
            child: Text(
              'Create',
              style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
