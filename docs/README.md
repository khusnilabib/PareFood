# PareFood Platform — Documentation Suite

**Documentation suite (approved). Implementation is in progress — see
[Sprint Delivery](#sprint-delivery) below and the [sprint plans](sprints/sprint-01-plan.md).**

This folder is the single source of truth for the PareFood Platform project. Every
document below is a standalone deliverable and also part of a chain: each document
references the documents that precede it (see the *References* line in each header).

## Document Index

| # | Document | ID | Focus |
|---|----------|----|-------|
| 01 | Project Vision | PF-DOC-01 | Why the platform exists |
| 02 | Product Requirements | PF-DOC-02 | What the products are |
| 03 | Business Analysis | PF-DOC-03 | How the platform makes money |
| 04 | Competitor Analysis | PF-DOC-04 | The competitive landscape |
| 05 | Target Users | PF-DOC-05 | Who the users are |
| 06 | User Personas | PF-DOC-06 | Representative users |
| 07 | Functional Requirements | PF-DOC-07 | What the platform does |
| 08 | Non-Functional Requirements | PF-DOC-08 | Quality attributes |
| 09 | Technical Stack | PF-DOC-09 | Technologies and rationale |
| 10 | Monorepo Blueprint | PF-DOC-10 | Repository and package layout |
| 11 | Flutter Architecture | PF-DOC-11 | App architecture and state |
| 12 | Supabase Architecture | PF-DOC-12 | Backend architecture |
| 13 | Database Blueprint | PF-DOC-13 | Schema, tables, indexes |
| 14 | API Blueprint | PF-DOC-14 | Endpoint catalogue |
| 15 | UI/UX Blueprint | PF-DOC-15 | Experience and information design |
| 16 | Design System | PF-DOC-16 | Visual language and components |
| 17 | Navigation Flow | PF-DOC-17 | Routing and guards |
| 18 | Business Rules | PF-DOC-18 | Rule catalogue |
| 19 | Security Strategy | PF-DOC-19 | Protection and compliance |
| 20 | Testing Strategy | PF-DOC-20 | Quality verification |
| 21 | CI/CD Strategy | PF-DOC-21 | Automation pipelines |
| 22 | Deployment Strategy | PF-DOC-22 | Environments and rollout |
| 23 | Coding Standards | PF-DOC-23 | Code conventions |
| 24 | Git Workflow | PF-DOC-24 | Branching and commit process |
| 25 | Sprint Roadmap | PF-DOC-25 | Delivery timeline |
| 26 | Release Plan | PF-DOC-26 | Versioning and cadence |
| 27 | Monitoring | PF-DOC-27 | Observability and SLOs |
| 28 | Maintenance | PF-DOC-28 | Support and operations |
| 29 | Future Expansion | PF-DOC-29 | Roadmap beyond MVP |
| 30 | Definition of Done | PF-DOC-30 | Acceptance quality gates |

## Review (Phase 2)

The suite was independently reviewed on 2026-08-06. Result: **APPROVED WITH
CONDITIONS**. 30 findings (6 High / 13 Medium / 11 Low) were recorded and all High/Medium
findings fixed. See the [review folder](review/00-review-index.md) for the reports.

| # | Review document |
|---|-----------------|
| 00 | [Review Index](review/00-review-index.md) |
| 01 | [Architecture Review Report](review/01-architecture-review-report.md) |
| 02 | [Risk Report](review/02-risk-report.md) |
| 03 | [Improvement Report](review/03-improvement-report.md) |
| 04 | [Checklist](review/04-checklist.md) |
| 05 | [Approval Status](review/05-approval-status.md) |

## Reading Order

- **Strategic set (strategy):** 01 → 02 → 03 → 04 → 05 → 06
- **Requirements set (what):** 07 → 08
- **Architecture set (how):** 09 → 10 → 11 → 12 → 13 → 14
- **Experience set (design):** 15 → 16 → 17
- **Governance set (rules):** 18 → 19
- **Engineering set (quality):** 20 → 21 → 22 → 23 → 24
- **Delivery set (time):** 25 → 26
- **Operations set (run):** 27 → 28
- **Growth set (next):** 29 → 30

## Global Conventions Used Across All Documents

| Convention | Value |
|---|---|
| Product family | PareFood, PareBisnis, PareDriver, PareAdmin |
| App codes | `AP-PF` (PareFood), `AP-PB` (PareBisnis), `AP-PD` (PareDriver), `AP-PA` (PareAdmin) |
| Roles | `customer`, `business`, `driver`, `admin` |
| Primary market | Indonesia; currency IDR (Rp) |
| Backend | Single Supabase project, single PostgreSQL database |
| Client | Flutter (mobile + web), one monorepo |
| Requirement IDs | `FR-<Area>-<NNN>`, `NFR-<NNN>`, `BR-<NNN>`, `SEC-<NNN>` |
| Baseline version | `0.1.0` (all apps); first public release `1.0.0` |
| Document status | `Approved (review PF-REV-01)`; `Draft` only until reviewed |

## Sprint Delivery

Implementation runs full-stack per sprint (migration + RLS + data layer +
feature UI + tests), following the Phase 4 sprint order. Delivery status lives
with each sprint plan, not in this index.

| Sprint | Plan | Focus | Status |
|---|---|---|---|
| Sprint 1 | [sprint-01-plan.md](sprints/sprint-01-plan.md) | Auth, users, merchant onboarding, products (read-side discovery) | Implemented — client-side gates green; DB verification static-only (see plan §10) |

## Status

All documents in this suite are **Approved (review PF-REV-01, 2026-08-06)** — approved
with conditions per the Review Approval Status. The Phase 2 start conditions in
Review 04 §6 were met, so implementation has begun; current progress is tracked in
the [sprint plans](sprints/sprint-01-plan.md).

**Review gate:** the Phase 1 gate (PF-DOC-30 §3.6) passed on 2026-08-06. See the
[review folder](review/00-review-index.md).
