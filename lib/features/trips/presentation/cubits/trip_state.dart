import 'package:equatable/equatable.dart';
import '../../domain/models/trip.dart';

abstract class TripState extends Equatable {
  const TripState();

  @override
  List<Object?> get props => [];
}

class TripInitial extends TripState {
  const TripInitial();
}

class TripLoading extends TripState {
  const TripLoading();
}

class TripLoaded extends TripState {
  final List<Trip> trips;
  final List<Trip> archivedTrips;
  final Trip? selectedTrip;

  const TripLoaded({
    required this.trips,
    this.archivedTrips = const [],
    this.selectedTrip,
  });

  @override
  List<Object?> get props => [trips, archivedTrips, selectedTrip];

  TripLoaded copyWith({
    List<Trip>? trips,
    List<Trip>? archivedTrips,
    Trip? selectedTrip,
  }) {
    return TripLoaded(
      trips: trips ?? this.trips,
      archivedTrips: archivedTrips ?? this.archivedTrips,
      selectedTrip: selectedTrip ?? this.selectedTrip,
    );
  }
}

class TripError extends TripState {
  final String message;

  const TripError(this.message);

  @override
  List<Object?> get props => [message];
}

class TripCreating extends TripState {
  const TripCreating();
}

class TripCreated extends TripState {
  final Trip trip;

  const TripCreated(this.trip);

  @override
  List<Object?> get props => [trip];
}

class TripJoining extends TripState {
  const TripJoining();
}

class TripJoined extends TripState {
  final Trip trip;

  const TripJoined(this.trip);

  @override
  List<Object?> get props => [trip];
}
