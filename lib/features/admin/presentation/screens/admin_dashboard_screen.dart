import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../widgets/admin_stats_card.dart';
import '../widgets/quick_action_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Datos simulados
  final List<Map<String, dynamic>> _stats = [
    {
      'title': 'Total Preguntas',
      'value': '156',
      'icon': Icons.quiz_outlined,
      'color': AppTheme.info,
      'change': '+12',
    },
    {
      'title': 'Estudiantes Activos',
      'value': '89',
      'icon': Icons.school_outlined,
      'color': AppTheme.success,
      'change': '+5',
    },
    {
      'title': 'Categorías',
      'value': '8',
      'icon': Icons.category_outlined,
      'color': AppTheme.warning,
      'change': '+1',
    },
    {
      'title': 'Respuestas Hoy',
      'value': '234',
      'icon': Icons.trending_up_outlined,
      'color': AppTheme.primaryRed,
      'change': '+45',
    },
  ];

  String? _displayName;
  bool _loadingDisplayName = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDisplayNameFromProfiles();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bienvenida
                    AnimationConfiguration.staggeredList(
                      position: 0,
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        verticalOffset: -30.0,
                        child: FadeInAnimation(
                          child: _buildWelcomeSection(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // // Estadísticas
                    // AnimationConfiguration.staggeredList(
                    //   position: 1,
                    //   duration: const Duration(milliseconds: 700),
                    //   child: SlideAnimation(
                    //     verticalOffset: 30.0,
                    //     child: FadeInAnimation(
                    //       child: _buildStatsSection(),
                    //     ),
                    //   ),
                    // ),

                    // const SizedBox(height: 32),

                    // Acciones
                    AnimationConfiguration.staggeredList(
                      position: 2,
                      duration: const Duration(milliseconds: 800),
                      child: SlideAnimation(
                        horizontalOffset: -30.0,
                        child: FadeInAnimation(
                          child: _buildQuickActionsSection(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // // Resumen Reciente
                    // AnimationConfiguration.staggeredList(
                    //   position: 3,
                    //   duration: const Duration(milliseconds: 900),
                    //   child: SlideAnimation(
                    //     verticalOffset: 30.0,
                    //     child: FadeInAnimation(
                    //       child: _buildRecentActivitySection(),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryBlack,
      elevation: 0,
      title: Text(
        AppConstants.adminDashboardTitle,
        style: const TextStyle(
          color: AppTheme.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Mostrar notificaciones
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notificaciones próximamente'),
                backgroundColor: AppTheme.info,
              ),
            );
          },
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, color: AppTheme.white),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.white),
          color: AppTheme.lightBlack,
          onSelected: (value) {
            switch (value) {
              case 'profile':
                // TODO: Ir a perfil
                break;
              case 'settings':
                // TODO: Ir a configuración
                break;
              case 'logout':
                _showLogoutDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: AppTheme.white),
                  SizedBox(width: 12),
                  Text('Mi Perfil', style: TextStyle(color: AppTheme.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, color: AppTheme.white),
                  SizedBox(width: 12),
                  Text('Configuración',
                      style: TextStyle(color: AppTheme.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: AppTheme.primaryRed),
                  SizedBox(width: 12),
                  Text('Cerrar Sesión',
                      style: TextStyle(color: AppTheme.primaryRed)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _loadDisplayNameFromProfiles() async {
    setState(() => _loadingDisplayName = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      final String? userId = user?.id;

      // Si no hay usuario autenticado -> fallback a email o 'Admin'
      if (userId == null) {
        setState(() {
          _displayName = user?.email ?? 'Admin';
          _loadingDisplayName = false;
        });
        return;
      }

      // Consulta directa a user_profiles
      final dynamic res = await client
          .from('user_profiles')
          .select('first_name, last_name')
          .eq('id', userId)
          .maybeSingle();

      Map<String, dynamic>? row;

      if (res == null) {
        row = null;
      } else if (res is Map && res.containsKey('data')) {
        // A veces la respuesta viene envuelta en { data: [...] }
        final d = res['data'];
        if (d is List && d.isNotEmpty) row = Map<String, dynamic>.from(d[0]);
      } else if (res is List && res.isNotEmpty) {
        row = Map<String, dynamic>.from(res[0] as Map);
      } else if (res is Map) {
        row = Map<String, dynamic>.from(res);
      } else {
        row = null;
      }

      String? name;

      if (row != null) {
        final first = (row['first_name'] ?? '').toString().trim();
        final last = (row['last_name'] ?? '').toString().trim();
        final combined = ('$first $last').trim();
        if (combined.isNotEmpty) {
          name = combined;
        }
      }

      // fallback final: email o 'Admin'
      name ??= user?.email ?? 'Admin';

      setState(() {
        _displayName = name;
        _loadingDisplayName = false;
      });
    } catch (e, st) {
      debugPrint('Error _loadDisplayNameFromProfiles: $e\n$st');
      final user = Supabase.instance.client.auth.currentUser;
      setState(() {
        _displayName = user?.email ?? 'Admin';
        _loadingDisplayName = false;
      });
    }
  }

  Widget _buildWelcomeSection() {
    // Si prefieres no mostrar "Cargando..." y usar email inmediatamente,
    // cambia esta línea por: final display = _displayName ?? Supabase.instance.client.auth.currentUser?.email ?? 'Admin';
    final display =
        _loadingDisplayName ? 'Cargando...' : (_displayName ?? 'Admin');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppTheme.primaryShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: AppTheme.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Bienvenido, $display!',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gestiona el sistema desde aquí',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.white.withOpacity(0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Última actividad: Hace 2 minutos',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.white.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _avatarInitials(String? name) {
    final initials = (name ?? '')
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();
    final displayInitials = initials.isEmpty ? '?' : initials;
    return Center(
      child: Text(
        displayInitials,
        style:
            const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas Generales',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: _stats.length,
          itemBuilder: (context, index) {
            return AdminStatsCard(
              title: _stats[index]['title'],
              value: _stats[index]['value'],
              icon: _stats[index]['icon'],
              color: _stats[index]['color'],
              change: _stats[index]['change'],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            QuickActionCard(
              title: 'Crear Pregunta',
              subtitle: 'Nueva pregunta',
              icon: Icons.add_circle_outline,
              color: AppTheme.success,
              onTap: () => Navigator.of(context).pushNamed(
                AppConstants.createQuestionRoute,
              ),
            ),
            QuickActionCard(
              title: 'Ver Preguntas',
              subtitle: 'Gestionar todas',
              icon: Icons.quiz_outlined,
              color: AppTheme.info,
              onTap: () => Navigator.of(context).pushNamed(
                AppConstants.questionsListRoute,
              ),
            ),
            QuickActionCard(
              title: 'Categorías',
              subtitle: 'Organizar temas',
              icon: Icons.category_outlined,
              color: AppTheme.warning,
              onTap: () => Navigator.of(context).pushNamed(
                AppConstants.categoriesRoute,
              ),
            ),
            QuickActionCard(
              title: 'Estadísticas',
              subtitle: 'Ver reportes',
              icon: Icons.analytics_outlined,
              color: AppTheme.primaryRed,
              onTap: () => Navigator.of(context).pushNamed(
                AppConstants.statisticsRoute,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actividad Reciente',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightBlack,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.greyDark.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            separatorBuilder: (context, index) => const Divider(
              color: AppTheme.greyDark,
              height: 24,
            ),
            itemBuilder: (context, index) {
              return _buildActivityItem(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(int index) {
    final activities = [
      {
        'title': 'Nueva pregunta creada',
        'subtitle': 'Matemáticas - Álgebra',
        'time': 'Hace 5 min',
        'icon': Icons.add_circle,
        'color': AppTheme.success,
      },
      {
        'title': 'Estudiante registrado',
        'subtitle': 'Juan Pérez se unió',
        'time': 'Hace 15 min',
        'icon': Icons.person_add,
        'color': AppTheme.info,
      },
      {
        'title': 'Quiz completado',
        'subtitle': '23 respuestas nuevas',
        'time': 'Hace 32 min',
        'icon': Icons.check_circle,
        'color': AppTheme.warning,
      },
      {
        'title': 'Categoría actualizada',
        'subtitle': 'Ciencias modificada',
        'time': 'Hace 1 hora',
        'icon': Icons.edit,
        'color': AppTheme.primaryRed,
      },
      {
        'title': 'Backup completado',
        'subtitle': 'Datos respaldados',
        'time': 'Hace 2 horas',
        'icon': Icons.backup,
        'color': AppTheme.greyLight,
      },
    ];

    final activity = activities[index];

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (activity['color'] as Color).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            activity['icon'] as IconData,
            color: activity['color'] as Color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity['title'] as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                activity['subtitle'] as String,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.greyLight,
                    ),
              ),
            ],
          ),
        ),
        Text(
          activity['time'] as String,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.greyMedium,
              ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightBlack,
        title: const Text(
          '¿Cerrar Sesión?',
          style: TextStyle(color: AppTheme.white),
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar tu sesión de administrador?',
          style: TextStyle(color: AppTheme.greyLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.greyLight),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppRouter.logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
