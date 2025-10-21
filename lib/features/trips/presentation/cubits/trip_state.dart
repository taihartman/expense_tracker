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
  final Trip? selectedTrip;

  const TripLoaded({
    required this.trips,
    this.selectedTrip,
  });

  @override
  List<Object?> get props => [trips, selectedTrip];

  TripLoaded copyWith({
    List<Trip>? trips,
    Trip? selectedTrip,
  }) {
    return TripLoaded(
      trips: trips ?? this.trips,
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
