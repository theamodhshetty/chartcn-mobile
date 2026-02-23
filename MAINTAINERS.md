# Maintainers and Role Matrix

| Role | Person | GitHub | Responsibilities |
|---|---|---|---|
| Project Lead | Amodh Shetty | @theamodhshetty | Direction, tie-breaks, release gates |
| Spec Maintainer | Amodh Shetty | @theamodhshetty | `ChartSpec` schema/versioning |
| iOS Maintainer | Amodh Shetty | @theamodhshetty | SwiftUI/SwiftData adapter quality |
| Android Maintainer | Amodh Shetty | @theamodhshetty | Compose/Room adapter quality |
| Security Maintainer | Amodh Shetty | @theamodhshetty | Vulnerability intake and fixes |
| Release Maintainer | Amodh Shetty | @theamodhshetty | Release tags, artifacts, and release notes |

## On-call Rotation (Suggested)

- Week 1: Spec + iOS
- Week 2: Android + Security
- Week 3: Spec + Android
- Week 4: iOS + Security

## Triage Queue Ownership

- Bugs: platform maintainer (iOS/Android) by component label.
- Spec requests: spec maintainer.
- Security: security maintainer (highest priority).
- Release blockers: release maintainer + project lead.
