/// Order lifecycle status (PF-DOC-11 §3.5, mapped to `PfStatusBadge`).
library;

/// Statuses surfaced to the UI. Transitions are enforced server-side
/// (PF-DOC-18, FL-R03).
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  delivering,
  delivered,
  cancelled,
}
