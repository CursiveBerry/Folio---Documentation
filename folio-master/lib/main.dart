import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'blocs/dashboard/dashboard_bloc.dart';
import 'blocs/dashboard/dashboard_event.dart';
import 'blocs/scanner/scanner_bloc.dart';
import 'repositories/document_repository.dart';
import 'services/scanner_service.dart';
import 'ui/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FolioApp());
}

class FolioApp extends StatelessWidget {
  const FolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => DocumentRepository()),
        RepositoryProvider(create: (context) => ScannerService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => DashboardBloc(
              repository: context.read<DocumentRepository>(),
            )..add(LoadDashboard()),
          ),
          BlocProvider(
            create: (context) => ScannerBloc(
              repository: context.read<DocumentRepository>(),
              scannerService: context.read<ScannerService>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Folio - Document Archive',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF512DA8),
              primary: const Color(0xFF512DA8),
              secondary: const Color(0xFFFF6F00), 
              surface: const Color(0xFFFcfbfc),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF7F4F9),
            textTheme: GoogleFonts.plusJakartaSansTextTheme(),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF7E57C2),
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
          ),
          home: const DashboardScreen(),
        ),
      ),
    );
  }
}