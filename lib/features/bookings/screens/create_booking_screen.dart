import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/primary_glow_button.dart';
import '../../listings/providers/listings_provider.dart';
import '../providers/bookings_provider.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  final int listingId;

  const CreateBookingScreen({super.key, required this.listingId});

  @override
  ConsumerState<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime _focusedDay = DateTime.now();
  final _notesCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool _isUnavailable(DateTime day, List<String> unavailableDates) {
    final formatted = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return unavailableDates.contains(formatted);
  }

  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) {
      showSnackBar(context, 'Please select dates', isError: true);
      return;
    }
    setState(() => _isSubmitting = true);
    final success = await ref.read(bookingsProvider.notifier).createBooking({
      'listing_id': widget.listingId,
      'start_date': '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}',
      'end_date': '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}',
      'notes': _notesCtrl.text.trim(),
    });
    setState(() => _isSubmitting = false);
    if (success && mounted) {
      showSnackBar(context, 'Booking request sent!');
      context.go('/bookings');
    } else if (mounted) {
      showSnackBar(context, 'Failed to create booking', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(listingDetailProvider(widget.listingId));
    final listing = detailState.listing;
    final unavailableDates = detailState.unavailableDates;

    final days = _startDate != null && _endDate != null
        ? calculateDays(_startDate!, _endDate!)
        : 0;
    final total = listing != null ? listing.pricePerDay * days : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Book Listing', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (listing != null) ...[
              Text(
                listing.title,
                style: GoogleFonts.syne(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${formatPrice(listing.pricePerDay)}/day',
                style: const TextStyle(color: AppColors.neonCyan, fontSize: 14),
              ),
              const SizedBox(height: 20),
            ],

            Text(
              'Select Dates',
              style: GoogleFonts.syne(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                rangeStartDay: _startDate,
                rangeEndDay: _endDate,
                rangeSelectionMode: RangeSelectionMode.toggledOn,
                calendarStyle: CalendarStyle(
                  defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
                  weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
                  outsideTextStyle: const TextStyle(color: AppColors.textMuted),
                  todayDecoration: BoxDecoration(
                    color: AppColors.neonViolet.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  rangeHighlightColor: AppColors.neonCyan.withOpacity(0.15),
                  rangeStartDecoration: const BoxDecoration(
                    color: AppColors.neonCyan,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: const BoxDecoration(
                    color: AppColors.neonCyan,
                    shape: BoxShape.circle,
                  ),
                  disabledTextStyle: const TextStyle(color: AppColors.textMuted),
                ),
                headerStyle: HeaderStyle(
                  titleTextStyle: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  formatButtonVisible: false,
                  leftChevronIcon: const Icon(Icons.chevron_left,
                      color: AppColors.textPrimary),
                  rightChevronIcon: const Icon(Icons.chevron_right,
                      color: AppColors.textPrimary),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  weekendStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                enabledDayPredicate: (day) =>
                    !_isUnavailable(day, unavailableDates),
                onRangeSelected: (start, end, focused) {
                  setState(() {
                    _startDate = start;
                    _endDate = end;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) {
                  _focusedDay = focused;
                },
              ),
            ),

            const SizedBox(height: 20),

            if (_startDate != null && _endDate != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _summaryRow('Check-in', formatDate(_startDate!.toIso8601String())),
                    const SizedBox(height: 8),
                    _summaryRow('Check-out', formatDate(_endDate!.toIso8601String())),
                    const SizedBox(height: 8),
                    _summaryRow('Duration', '$days days'),
                    const Divider(color: AppColors.border, height: 20),
                    _summaryRow(
                      'Total',
                      formatPrice(total),
                      highlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _notesCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any special requests or notes for the host...',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            PrimaryGlowButton(
              label: 'Send Booking Request',
              onPressed: _submit,
              isLoading: _isSubmitting,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppColors.neonCyan : AppColors.textPrimary,
            fontSize: highlight ? 16 : 13,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
