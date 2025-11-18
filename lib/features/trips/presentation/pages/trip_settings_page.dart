import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubits/trip_cubit.dart';
import '../cubits/trip_state.dart';
import '../widgets/participant_form_bottom_sheet.dart';
import '../widgets/trip_verification_prompt.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../widgets/trip_details_card.dart';
import '../widgets/allowed_currencies_card.dart';
import '../widgets/recovery_code_card.dart';
import '../widgets/trip_settings_participant_card.dart';
import '../widgets/danger_zone_section.dart';

/// Trip Settings Page
///
/// Restructured with tabbed interface for better organization:
/// - General Tab: Trip details, currencies, quick actions
/// - Members Tab: Participant management
/// - Advanced Tab: Recovery code, archive, danger zone
class TripSettingsPage extends StatelessWidget {
  final String tripId;

  const TripSettingsPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    // Check if user has verified their identity for this trip
    final tripCubit = context.read<TripCubit>();

    return FutureBuilder<bool>(
      future: tripCubit.isUserMemberOf(tripId),
      builder: (context, snapshot) {
        // Show loading while checking membership
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.tripSettingsTitle),
              elevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Show verification prompt if not a member
        if (snapshot.data == false) {
          return Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.tripSettingsTitle),
              elevation: 0,
            ),
            body: TripVerificationPrompt(tripId: tripId),
          );
        }

        // User is verified, show settings
        return _buildSettings(context);
      },
    );
  }

  Widget _buildSettings(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.tripSettingsTitle),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: context.l10n.tripBackToExpenses,
            onPressed: () {
              context.pop();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: context.l10n.commonEdit,
              onPressed: () {
                context.push(AppRoutes.tripEdit(tripId));
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.settings),
                text: context.l10n.tripSettingsTabGeneral,
              ),
              Tab(
                icon: const Icon(Icons.people),
                text: context.l10n.tripSettingsTabMembers,
              ),
              Tab(
                icon: const Icon(Icons.admin_panel_settings),
                text: context.l10n.tripSettingsTabAdvanced,
              ),
            ],
          ),
        ),
        body: BlocBuilder<TripCubit, TripState>(
          builder: (context, state) {
            if (state is TripLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TripError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: AppTheme.spacing2),
                    Text(
                      context.l10n.tripSettingsLoadError,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.spacing1),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing3),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<TripCubit>().loadTrips();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(context.l10n.commonRetry),
                    ),
                  ],
                ),
              );
            }

            if (state is TripLoaded) {
              final trip = state.trips.firstWhere(
                (t) => t.id == tripId,
                orElse: () => throw Exception('Trip not found'),
              );

              return TabBarView(
                children: [
                  // General Tab
                  _buildGeneralTab(context, trip),

                  // Members Tab
                  _buildMembersTab(context, trip),

                  // Advanced Tab
                  _buildAdvancedTab(context, trip),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  /// Build General Tab (Trip details, currencies, quick actions)
  Widget _buildGeneralTab(BuildContext context, dynamic trip) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          _buildSectionHeader(
            context,
            context.l10n.tripSettingsSectionTripDetails,
            icon: Icons.info_outline,
          ),
          const SizedBox(height: AppTheme.spacing2),

          // Trip Details Card
          TripDetailsCard(
            tripName: trip.name,
            baseCurrencyCode: trip.defaultCurrency.code,
            createdAt: trip.createdAt,
          ),
          const SizedBox(height: AppTheme.spacing4),

          // Section Header
          _buildSectionHeader(
            context,
            context.l10n.tripSettingsSectionAllowedCurrencies,
            icon: Icons.currency_exchange,
          ),
          const SizedBox(height: AppTheme.spacing2),

          // Allowed Currencies Card
          AllowedCurrenciesCard(
            tripId: trip.id,
            allowedCurrencies: trip.allowedCurrencies,
          ),
          const SizedBox(height: AppTheme.spacing4),

          // Section Header
          _buildSectionHeader(
            context,
            context.l10n.tripSettingsSectionQuickActions,
            icon: Icons.flash_on,
          ),
          const SizedBox(height: AppTheme.spacing2),

          // Quick Actions Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.tripInvite(tripId)),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(context.l10n.tripSettingsInviteButton),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(AppTheme.spacing2),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing2),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.tripActivity(tripId)),
                  icon: const Icon(Icons.history),
                  label: Text(context.l10n.tripSettingsActivityButton),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(AppTheme.spacing2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing2),

          // Customize Categories Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                AppRoutes.tripCategoryCustomization(tripId),
              ),
              icon: const Icon(Icons.palette),
              label: Text(context.l10n.tripSettingsCustomizeCategoriesButton),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(AppTheme.spacing2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Members Tab (Participant management)
  Widget _buildMembersTab(BuildContext context, dynamic trip) {
    // Check screen width for responsive layout
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        // Section Header with Add Button
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.people,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacing2),
              Expanded(
                child: Text(
                  '${context.l10n.participantSectionTitle} (${trip.participants.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddParticipantSheet(context),
                icon: const Icon(Icons.person_add, size: 18),
                label: Text(context.l10n.participantAddButton),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing2,
                    vertical: AppTheme.spacing1,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Participants List
        Expanded(
          child: trip.participants.isEmpty
              ? _buildEmptyState(context)
              : _buildParticipantsList(context, trip, isMobile),
        ),
      ],
    );
  }

  /// Build Advanced Tab (Recovery code, danger zone)
  Widget _buildAdvancedTab(BuildContext context, dynamic trip) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          _buildSectionHeader(
            context,
            context.l10n.tripSettingsSectionRecoveryCode,
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: AppTheme.spacing2),

          // Recovery Code Card
          RecoveryCodeCard(
            tripId: trip.id,
            tripName: trip.name,
          ),
          const SizedBox(height: AppTheme.spacing4),

          // Section Header
          _buildSectionHeader(
            context,
            context.l10n.tripSettingsSectionDangerZone,
            icon: Icons.warning,
          ),
          const SizedBox(height: AppTheme.spacing2),

          // Danger Zone Section
          DangerZoneSection(
            tripId: trip.id,
            tripName: trip.name,
            isArchived: trip.isArchived,
          ),
        ],
      ),
    );
  }

  /// Build section header with icon
  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppTheme.spacing1),
        ],
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build empty state for participants
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppTheme.spacing2),
            Text(
              context.l10n.participantEmptyStateTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing1),
            Text(
              context.l10n.participantEmptyStateDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build participants list (responsive: ListView or GridView)
  Widget _buildParticipantsList(
    BuildContext context,
    dynamic trip,
    bool isMobile,
  ) {
    if (isMobile) {
      // Mobile: Single column ListView
      return ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        itemCount: trip.participants.length,
        itemBuilder: (context, index) {
          return TripSettingsParticipantCard(
            tripId: trip.id,
            participant: trip.participants[index],
          );
        },
      );
    } else {
      // Tablet+: 2-column GridView
      return GridView.builder(
        padding: const EdgeInsets.all(AppTheme.spacing2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppTheme.spacing2,
          mainAxisSpacing: AppTheme.spacing2,
          childAspectRatio: 4,
        ),
        itemCount: trip.participants.length,
        itemBuilder: (context, index) {
          return TripSettingsParticipantCard(
            tripId: trip.id,
            participant: trip.participants[index],
          );
        },
      );
    }
  }

  /// Show add participant bottom sheet
  void _showAddParticipantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<TripCubit>(),
        child: ParticipantFormBottomSheet(
          tripId: tripId,
          onParticipantAdded: (participant) {
            Navigator.of(sheetContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.participantAddedSuccess(participant.name),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }
}
