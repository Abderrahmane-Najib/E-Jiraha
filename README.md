# e-Jiraha

A Flutter mobile application for managing pre-operative patient flow in hospitals. The app digitizes the patient journey from admission to surgery, enabling different medical staff roles to collaborate efficiently.

## Features

- **Multi-role Authentication**: Secretary, Nurse, Anesthesiologist, Surgeon, Admin
- **Patient Management**: Registration, admission, and tracking
- **Triage System**: Patient prioritization and vital signs recording
- **Checklist Management**: Pre-operative checklists for nurses and anesthesiologists
- **Surgery Planning**: Scheduling and team assignment
- **Activity Logging**: Complete audit trail of all actions

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐│
│  │Secretary │ │  Nurse   │ │Anesthesi-│ │ Surgeon  │ │ Admin  ││
│  │ Screens  │ │ Screens  │ │ologist   │ │ Screens  │ │Screens ││
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └───┬────┘│
└───────┼────────────┼────────────┼────────────┼───────────┼─────┘
        │            │            │            │           │
        ▼            ▼            ▼            ▼           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      STATE MANAGEMENT                           │
│                        (Riverpod)                               │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐            │
│  │ StateNotifier│ │FutureProvider│ │   Provider   │            │
│  │  Providers   │ │   .family    │ │  (derived)   │            │
│  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘            │
└─────────┼────────────────┼────────────────┼────────────────────┘
          │                │                │
          ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      REPOSITORY LAYER                           │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐   │
│  │  Patient   │ │  Hospital  │ │  Surgery   │ │ Checklist  │   │
│  │ Repository │ │Case Repo.  │ │ Repository │ │ Repository │   │
│  └─────┬──────┘ └─────┬──────┘ └─────┬──────┘ └─────┬──────┘   │
└────────┼──────────────┼──────────────┼──────────────┼──────────┘
         │              │              │              │
         ▼              ▼              ▼              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      FIREBASE SERVICE                           │
│                                                    │
│  ┌─────────────────┐          ┌─────────────────┐              │
│  │ Firebase Auth   │          │ Cloud Firestore │              │
│  │ (Authentication)│          │   (Database)    │              │
│  └─────────────────┘          └─────────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter |
| Language | Dart |
| State Management | Riverpod |
| Navigation | GoRouter |
| Backend | Firebase |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| Design | Figma |

## Project Structure

```
lib/
├── core/
│   ├── constants/      # App colors, strings
│   ├── theme/          # App theme configuration
│   └── widgets/        # Reusable UI components
├── features/
│   ├── admin/          # Admin dashboard & user management
│   ├── anesthesiologist/  # Anesthesia evaluations
│   ├── auth/           # Login & authentication
│   ├── nurse/          # Triage & checklists
│   ├── secretary/      # Patient & admission management
│   └── surgeon/        # Surgery planning & decisions
├── models/             # Data models
├── routing/            # GoRouter configuration
├── services/           # Firebase & repository services
└── main.dart           # App entry point
```

## Data Flow

```
User Action → Screen → Provider → Repository → Firebase → Cloud
     ↑                                              │
     └──────────── State Update ←───────────────────┘
```

## Database Collections

| Collection | Description |
|------------|-------------|
| `users` | Staff accounts and roles |
| `patients` | Patient information |
| `hospital_cases` | Admission records |
| `surgeries` | Surgery schedules |
| `checklists` | Pre-op checklists |
| `anesthesia_evaluations` | Anesthesia assessments |
| `activity_logs` | Audit trail |

## Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- Firebase project configured
- Android Studio / VS Code

### Installation

```bash
# Clone the repository
git clone https://github.com/abderrahmane-Najib/ejiraha.git

# Navigate to project
cd ejiraha

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## User Roles

| Role | Responsibilities |
|------|------------------|
| **Secretary** | Patient registration, admissions |
| **Nurse** | Triage, vital signs, pre-op checklists |
| **Anesthesiologist** | Anesthesia evaluation, risk assessment |
| **Surgeon** | Surgery requests, planning, decisions |
| **Admin** | User management, system oversight |


