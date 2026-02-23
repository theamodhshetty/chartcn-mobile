# Governance

## Roles

1. Project Lead
Owns roadmap direction, release policy, and final tie-break decisions.

2. Maintainers
Review/merge PRs, triage issues, enforce quality/security standards.

3. Spec Maintainers
Own `ChartSpec` evolution and compatibility guarantees.

4. Platform Maintainers (iOS, Android)
Own platform renderers/adapters and platform-specific docs.

5. Security Maintainers
Own vulnerability triage, fixes, and advisories.

6. Release Maintainers
Own release cut process, changelog quality, and post-release verification.

## Decision Model

- Standard change: 1 maintainer approval.
- Spec-breaking change: 2 approvals including 1 spec maintainer.
- Security-sensitive change: 1 security maintainer approval.

## Release Ownership

- Monthly patch release window.
- Minor release when new stable spec fields land.
- Major release only for breaking spec or runtime APIs.
- Release PR must include migration notes when `ChartSpec` behavior changes.

## Operational SLAs

- New issue triage: within 72 hours.
- Security issue acknowledgement: within 24 hours.
- PR first review target: within 3 business days.
