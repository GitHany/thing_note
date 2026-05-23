import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/trip_planner/domain/trip_models.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return TripRepository(dbAsync);
});

final tripsProvider = StateNotifierProvider<TripsNotifier, AsyncValue<List<Trip>>>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return TripsNotifier(repository);
});

final tripDetailProvider = FutureProvider.family<Trip?, int>((ref, tripId) async {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.getTripById(tripId);
});

final tripItinerariesProvider = FutureProvider.family<List<TripItinerary>, int>((ref, tripId) async {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.getItineraries(tripId);
});

final tripBookingsProvider = FutureProvider.family<List<TripBooking>, int>((ref, tripId) async {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.getBookings(tripId);
});

final tripExpensesProvider = FutureProvider.family<List<TripExpense>, int>((ref, tripId) async {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.getExpenses(tripId);
});

class TripRepository {
  final AsyncValue<Database> _dbAsync;

  TripRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  // Trip CRUD
  Future<int> insertTrip(Trip trip) async {
    final db = await _db;
    return db.insert('trips', trip.toMap());
  }

  Future<int> updateTrip(Trip trip) async {
    final db = await _db;
    return db.update('trips', trip.toMap(), where: 'id = ?', whereArgs: [trip.id]);
  }

  Future<int> deleteTrip(int id) async {
    final db = await _db;
    return db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Trip>> getAllTrips() async {
    final db = await _db;
    final maps = await db.query('trips', orderBy: 'start_date DESC');
    return maps.map((m) => Trip.fromMap(m)).toList();
  }

  Future<Trip?> getTripById(int id) async {
    final db = await _db;
    final maps = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Trip.fromMap(maps.first);
  }

  // Itinerary CRUD
  Future<int> insertItinerary(TripItinerary itinerary) async {
    final db = await _db;
    return db.insert('trip_itineraries', itinerary.toMap());
  }

  Future<int> updateItinerary(TripItinerary itinerary) async {
    final db = await _db;
    return db.update('trip_itineraries', itinerary.toMap(), where: 'id = ?', whereArgs: [itinerary.id]);
  }

  Future<int> deleteItinerary(int id) async {
    final db = await _db;
    return db.delete('trip_itineraries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TripItinerary>> getItineraries(int tripId) async {
    final db = await _db;
    final maps = await db.query(
      'trip_itineraries',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'date ASC, order_index ASC',
    );
    return maps.map((m) => TripItinerary.fromMap(m)).toList();
  }

  // Booking CRUD
  Future<int> insertBooking(TripBooking booking) async {
    final db = await _db;
    return db.insert('trip_bookings', booking.toMap());
  }

  Future<int> deleteBooking(int id) async {
    final db = await _db;
    return db.delete('trip_bookings', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TripBooking>> getBookings(int tripId) async {
    final db = await _db;
    final maps = await db.query(
      'trip_bookings',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'booking_date ASC',
    );
    return maps.map((m) => TripBooking.fromMap(m)).toList();
  }

  // Expense CRUD
  Future<int> insertExpense(TripExpense expense) async {
    final db = await _db;
    return db.insert('trip_expenses', expense.toMap());
  }

  Future<int> deleteExpense(int id) async {
    final db = await _db;
    return db.delete('trip_expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TripExpense>> getExpenses(int tripId) async {
    final db = await _db;
    final maps = await db.query(
      'trip_expenses',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'date ASC',
    );
    return maps.map((m) => TripExpense.fromMap(m)).toList();
  }

  // Stats
  Future<Map<String, dynamic>> getTripStats(int tripId) async {
    final expenses = await getExpenses(tripId);
    final bookings = await getBookings(tripId);
    
    final totalExpense = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalBooking = bookings.fold<double>(0, (sum, b) => sum + (b.amount ?? 0));
    
    return {
      'total_expense': totalExpense,
      'total_booking': totalBooking,
      'expense_count': expenses.length,
      'booking_count': bookings.length,
    };
  }
}

class TripsNotifier extends StateNotifier<AsyncValue<List<Trip>>> {
  final TripRepository _repository;

  TripsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTrips();
  }

  Future<void> loadTrips() async {
    state = const AsyncValue.loading();
    try {
      final trips = await _repository.getAllTrips();
      state = AsyncValue.data(trips);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTrip(Trip trip) async {
    try {
      await _repository.insertTrip(trip);
      await loadTrips();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTrip(Trip trip) async {
    try {
      await _repository.updateTrip(trip);
      await loadTrips();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTrip(int id) async {
    try {
      await _repository.deleteTrip(id);
      await loadTrips();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}