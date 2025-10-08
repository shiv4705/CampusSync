# CampusSync

CampusSync is a comprehensive campus management system built with **Flutter**, **Firebase**, and **Supabase**.  
It streamlines academic and administrative workflows by integrating features like **attendance tracking**, **study material sharing**, **notices**, **assignments**, and **timetables** into a single, easy-to-use platform.

---

## Overview

CampusSync aims to bridge the communication gap between students, faculty, and administrators by providing **role-based dashboards** and **access controls**.  
Each user role has dedicated features tailored to their responsibilities within the academic ecosystem.

---

## Features

### 1. Authentication and Role Management
- Secure login using Firebase Authentication.
- Role-based access control for **Admin**, **Faculty**, and **Students**.

---

### 2. Dashboard
Each user is directed to their personalized dashboard after login:
- **Admin Dashboard:** Access to all modules, including timetable, and user management.
- **Faculty Dashboard:** Manage attendance, upload study materials and assignments, and send notices to students.
- **Student Dashboard:** View attendance summary, study materials, assignments, notices, and timetable.

---

### 3. Study Material Module
A centralized system for sharing academic resources:
- **Faculty:**  
  - Upload study materials as **PDFs** or **links**, organized by **subject**.
  - All uploaded files are securely stored in **Supabase Storage**.
- **Students:**   
  - Select a subject to view available materials directly within the app.

---

### 4. Assignment Module
A digital platform for managing coursework and submissions:
- **Faculty:**  
  - Create and upload assignments with details such as **title**, **description**, **deadline**, and **attachments**.  
  - View student submissions and manage grades if required.
- **Students:**  
  - Access and view all active assignments for their enrolled subjects.  
  - Submit assignments before deadlines (including PDFs or file links).  
  - Receive status updates and grades once reviewed.

---

### 5. Notice Board Module
A flexible communication system for announcements:
- **Faculty:**  
  - Create and send notices to students in their respective classes.  
- **Students:**  
  - View notices from **faculty**.  
  - Notices are displayed chronologically for better readability.

---

### 6. Attendance Management
An automated attendance system designed for accuracy and efficiency:
- **Faculty:**  
  - Can mark attendance from the official start date (e.g., Monday, 11 August).  
  - Automatically shows **unmarked attendance days** from the start date till the current day.  
  - Handles week transitions while retaining previous unmarked days.
- **Students:**  
  - Can view attendance reports and percentages for each subject.  
  - Offers real-time visibility into attendance trends.

---

### 7. Timetable Management
A structured schedule view for managing lectures and classroom activities:
- **Admin:**  
  - Can add, edit, or delete timetable entries for any semester, subject, or faculty.  
- **Faculty:**  
  - Can view their assigned lecture schedule with subject details and timing.  
- **Students:**  
  - Can view their daily and weekly timetable.

---

### 8. Event Calendar
An interactive calendar for institutional events and activities:
- Displays upcoming events, holidays, and academic deadlines.
- Uses **Syncfusion Flutter Calendar** for a smooth and interactive interface.

---

## Tech Stack

| Technology | Purpose |
|-------------|----------|
| **Flutter** | Frontend framework for cross-platform app development |
| **Firebase Authentication** | Handles secure user login and password management |
| **Cloud Firestore** | Stores structured data such as user roles, attendance, notices, assignments, and timetable entries |
| **Supabase Storage** | Securely stores and retrieves uploaded PDFs and assignments |
| **Syncfusion Flutter Widgets** | Provides UI components like calendars and PDF viewers |

---

## Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/CampusSync.git
   cd CampusSync

2. **Install dependencies**
    ```bash
    flutter pub get

3. **Configure Firebase**
    - Add google-services.json (Android) and GoogleService-Info.plist (iOS).
    - Enable Authentication and Firestore in the Firebase Console.

4. **Configure Supabase**
    - Create a Supabase project.
    - Obtain the API URL and public API key.
    - Set up storage buckets for PDF uploads.
    - Add credentials to your environment configuration.

5. **Run the app**
    ```bash
    flutter run