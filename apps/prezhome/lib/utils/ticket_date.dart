/// Fecha de un ticket para el gasto: la de la compra que pone el ticket y,
/// si no se leyó, el día en que se guardó. Así un ticket de septiembre
/// escaneado en octubre cuenta en septiembre.
library;

DateTime? ticketDate(Map<dynamic, dynamic> t) =>
    DateTime.tryParse('${t['purchased_at'] ?? ''}') ??
    DateTime.tryParse('${t['created_at'] ?? ''}')?.toLocal();

String _day(DateTime d) => d.toIso8601String().split('T').first;

/// Filtro `or` de PostgREST para los tickets comprados en [start, end).
String ticketRangeFilter(DateTime start, DateTime end) {
  final s = _day(start), e = _day(end);
  return 'and(purchased_at.gte.$s,purchased_at.lt.$e),'
      'and(purchased_at.is.null,created_at.gte.$s,created_at.lt.$e)';
}
