import '../../auth/models/user_model.dart';
import '../../listings/models/listing_model.dart';

class BookingModel {
  final int id;
  final int listingId;
  final int renterId;
  final int hostId;        // explicit host ID — reliable for matching
  final String startDate;
  final String endDate;
  final int totalDays;
  final double totalPrice;
  final String status;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? notes;
  final ListingModel? listing;
  final UserModel? renter;
  final String? createdAt;

  BookingModel({
    required this.id,
    required this.listingId,
    required this.renterId,
    required this.hostId,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.totalPrice,
    required this.status,
    this.paymentMethod,
    this.paymentStatus,
    this.notes,
    this.listing,
    this.renter,
    this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? 0,
      listingId: json['listing_id'] ?? 0,
      renterId: json['renter_id'] ?? 0,
      hostId: json['host_id'] ?? 0,
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      totalDays: json['total_days'] ?? 0,
      totalPrice:
          double.tryParse(json['total_price']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      notes: json['notes'],
      listing: json['listing'] != null
          ? ListingModel.fromJson(json['listing'])
          : null,
      renter: json['renter'] != null
          ? UserModel.fromJson(json['renter'])
          : null,
      createdAt: json['created_at'],
    );
  }
}
