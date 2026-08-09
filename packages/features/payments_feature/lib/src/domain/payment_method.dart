/// Payment methods surfaced at checkout (PF-DOC-18 §3.4).
library;

/// Supported payment methods. Availability is backend-driven.
enum PaymentMethod { qris, virtualAccount, ewallet, cashOnDelivery }
