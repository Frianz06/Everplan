# Everplan 🌿

Everplan is a professional Flutter application designed to bridge the gap between Project Managers and field-based Employees.  
It features a robust Multi-Tenant architecture, ensuring that data is securely siloed by company, and Role-Based Access Control (RBAC)  
to define clear accountabilities.

---

## Getting Started

To run this project on your local machine or a physical device, follow these steps:

---

## 1. Prerequisites

- Install Flutter SDK  
- Install Visual Studio Code  
- A Firebase account  

---

## 2. Firebase Configuration

Since this app relies on Firebase, you must connect your own instance:

### 2.1. Create a new project in the Firebase Console.

### 2.2. Enable Authentication (Email/Password provider).

### 2.3. Create a Cloud Firestore database in test mode.

### 2.4. Add an Android/iOS app to your Firebase project and download the `google-services.json` (for Android) to `android/app/`.

### 2.5. Generate Configuration  
Users need to run `flutterfire configure` in the project root to generate their own version of the `lib/firebase_options.dart` file. This file is required to initialize Firebase but is ignored by version control for security.

---

## 3. Firestore Rules

To ensure RBAC and Multi-tenancy work correctly, apply these rules in your Firebase Console:

```js
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null;
      
      match /tasks/{taskId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

---

## 4. Installation
### Clone the repository
```
git clone https://github.com/your-username/everplan.git
```
### Navigate to the directory
```
cd everplan
```

### Install Flutter packages
```
flutter pub get
```

---

## 5. Running the App

### Connect your device or start an emulator and run:
```
flutter run
```
