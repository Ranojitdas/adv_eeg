# Backend API Documentation for Frontend Developer

## Overview

This document contains the API routes, request types, payload formats, and logic needed to integrate the backend with the Frontend application.

### Guidelines

1. Use correct request type (GET, POST, PATCH) for each route
2. All protected routes require JWT token in Authorization header: `Bearer <token>`
3. Use appropriate payloads as described per route
4. If any confusion, contact backend developer for payload examples or clarification

---

## User Routes

**BASE URL:** `api/v1/users`

### User Registration
- **Route:** `POST api/v1/users/register`
- **Description:** Register patient, relative, or doctor based on role
- **Payload:**

**PATIENT:**
```json
{
  "firstName": "",
  "lastName": "",
  "email": "",
  "password": "",
  "role": "PATIENT",
  "doctorId": ""
}
```

**RELATIVE:**
```json
{
  "firstName": "",
  "lastName": "",
  "email": "",
  "password": "",
  "role": "RELATIVE",
  "invitationCode": "",
  "relationshipToPatient": ""
}
```

**DOCTOR:**
```json
{
  "firstName": "",
  "lastName": "",
  "email": "",
  "password": "",
  "role": "DOCTOR",
  "specialization": ""
}
```

### Verify User
- **Route:** `POST api/v1/users/verify-otp`
- **Description:** Verify user's OTP
- **Payload:**
```json
{
  "email": "",
  "otp": ""
}
```

### Login User
- **Route:** `POST api/v1/users/login`
- **Description:** Login user with email and password
- **Payload:**
```json
{
  "email": "",
  "password": ""
}
```

### Get Logged-in User Details
- **Route:** `GET api/v1/users/me`
- **Description:** Returns logged-in user's details using token
- **Payload:** No payload, token required in headers
- **Authentication:** Required

### Get User By ID
- **Route:** `GET api/v1/users/:id`
- **Description:** Get any user's details by ID
- **Payload:** No payload, just user ID in URL
- **Authentication:** Required

### Logout User
- **Route:** `POST api/v1/users/logout`
- **Description:** Logout currently logged-in user
- **Payload:** No payload, just token required
- **Authentication:** Required

### Request Password Reset
- **Route:** `POST api/v1/users/forgot-password`
- **Description:** Request password reset token via email
- **Payload:**
```json
{
  "email": "user@gmail.com"
}
```
- **Authentication:** Not required

### Reset Password with Token
- **Route:** `POST api/v1/users/reset-password/<token>`
- **Description:** Reset password using token sent via email
- **Payload:**
```json
{
  "password": "newPassword123",
  "confirmPassword": "newPassword123"
}
```
- **Authentication:** Not required
- **Note:** Replace `<token>` in URL with the actual token received via email

### Update User Location
- **Route:** `PATCH api/v1/users/update-user-location`
- **Description:** Update user's current coordinates
- **Payload:**
```json
{
  "coordinates": [LAT, LNG]
}
```
- **Authentication:** Required

---

## Doctor Routes

**BASE URL:** `api/v1/doctor`

### Get All Doctors
- **Route:** `GET api/v1/doctor/get-all-doctors`
- **Description:** Get all verified doctors
- **Payload:** No payload

### Get All Patients
- **Route:** `GET api/v1/doctor/get-all-patients`
- **Description:** Get patients assigned to logged-in doctor
- **Payload:** No payload, just token
- **Authentication:** Required

---

## Relative Routes

**BASE URL:** `api/v1/relative`

### Get Monitored Patient
- **Route:** `GET api/v1/relative/get-monitored-patient`
- **Description:** Relative gets the patient being monitored
- **Payload:** No payload, token required
- **Authentication:** Required

---

## Question Routes

**BASE URL:** `api/v1/question`

### Create New Question
- **Route:** `POST api/v1/question/create`
- **Description:** Doctor creates a new question
- **Payload:**
```json
{
  "type": ["HAM_D", "BDI"],
  "question": "",
  "options": []
}
```
- **Authentication:** Required

### Get All Questions
- **Route:** `GET api/v1/question/all`
- **Description:** Get all questions in DB
- **Payload:** No payload

### Get Questions by Type
- **Route:** `GET api/v1/question/type/:type`
- **Description:** Get questions of specific type
- **Payload:** No payload

### Get Question by ID
- **Route:** `GET api/v1/question/:questionId`
- **Description:** Get specific question by ID
- **Payload:** No payload

---

## Quiz Routes

**BASE URL:** `api/v1/quiz`

### Assign Quiz
- **Route:** `POST api/v1/quiz/assign`
- **Description:** Doctor assigns quiz to patient
- **Payload:**
```json
{
  "patientId": "",
  "questionnaireType": "HAM_D"
}
```
- **Authentication:** Required

### Get Assigned Quiz for Patient
- **Route:** `GET api/v1/quiz/my-assigned-quiz`
- **Description:** Patient retrieves assigned quizzes
- **Payload:** No payload
- **Authentication:** Required

### Self-Initiate Quiz
- **Route:** `POST api/v1/quiz/self-initiate`
- **Description:** Patient initiates quiz
- **Payload:**
```json
{
  "questionnaireType": "HAM_D"
}
```
- **Authentication:** Required

### Submit Quiz
- **Route:** `POST api/v1/quiz/submit/:quizAttemptId`
- **Description:** Patient submits quiz
- **Payload:**
```json
{
  "responses": []
}
```
- **Authentication:** Required

### Get Quiz History
- **Route:** `GET api/v1/quiz/history/:patientId`
- **Description:** Get all quiz attempts of patient
- **Payload:** No payload
- **Authentication:** Required

### Get All Quizzes for Logged-in User
- **Route:** `GET api/v1/quiz/my-all-quizzes`
- **Description:** Patient fetches all their quizzes
- **Payload:** No payload
- **Authentication:** Required

### Get Quiz by ID
- **Route:** `GET api/v1/quiz/get-quiz-by-id/:quizAttemptId`
- **Description:** Get a quiz by its ID
- **Payload:** No payload
- **Authentication:** Required

### Get Quizzes Assigned by Doctor
- **Route:** `GET api/v1/quiz/get-quiz-assigned-by-me`
- **Description:** Doctor fetches quizzes they've assigned
- **Payload:** No payload
- **Authentication:** Required

---

## Patient History Routes

**BASE URL:** `api/v1/patient-history`

### Update Patient History
- **Route:** `POST api/v1/patient-history/`
- **Description:** Patient updates their medical/psych history
- **Payload:**
```json
{
  "age": 24,
  "sex": "M",
  "maritalStatus": "Unmarried",
  "income": 6000,
  "religion": "Hindu",
  "education": "Graduate",
  "occupation": "Unemployed",
  "habitat": "Rural",
  "location": "Jamalpur, Bihar",
  "durationOfIllness": "01 month",
  "ageOfOnset": 24,
  "firstMDEAge": 24,
  "pastMedicalIllness": false,
  "pastPsychiatricIllness": false,
  "familyMedicalIllness": false,
  "familyPsychiatricIllness": false,
  "handedness": "Right",
  "pulse": 80,
  "bloodPressureSystolic": 120,
  "bloodPressureDiastolic": 80,
  "cvs": "WNL",
  "rs": "WNL",
  "git": "WNL",
  "cns": "WNL"
}
```
- **Authentication:** Required

### Get Patient History
- **Route:** `GET api/v1/patient-history/`
- **Description:** Get patient's submitted medical history
- **Payload:** Optional patientId in query/body/params
- **Authentication:** Required

---

## Authentication Notes

- All routes marked with "Authentication: Required" need the JWT token in the Authorization header
- Format: `Authorization: Bearer <your-jwt-token>`
- Tokens are obtained from the login endpoint
- Use the logout endpoint to invalidate tokens

## Error Handling

Make sure to handle common HTTP status codes:
- `200`: Success
- `201`: Created
- `400`: Bad Request
- `401`: Unauthorized
- `403`: Forbidden
- `404`: Not Found
- `500`: Internal Server Error

---

## Notification Routes

**BASE URL:** `api/v1/notification`

### Get All Notifications
- **Route:** `GET api/v1/notification/`
- **Route:** `GET api/v1/notification/get-notifications`
- **Description:** Get all notifications with pagination and filters
- **Payload:** No payload, supports query parameters for pagination
- **Authentication:** Required

### Mark Notification as Read
- **Route:** `PATCH api/v1/notification/:notificationId/read`
- **Description:** Mark a specific notification as read
- **Payload:** No payload, notificationId in URL
- **Authentication:** Required

### Mark All Notifications as Read
- **Route:** `PATCH api/v1/notification/mark-all-read`
- **Description:** Mark all notifications as read for logged-in user
- **Payload:** No payload
- **Authentication:** Required

### Delete Notification
- **Route:** `DELETE api/v1/notification/:notificationId`
- **Description:** Delete a specific notification
- **Payload:** No payload, notificationId in URL
- **Authentication:** Required

### Delete All Notifications
- **Route:** `DELETE api/v1/notification/delete-all`
- **Description:** Delete all notifications for logged-in user
- **Payload:** No payload
- **Authentication:** Required

### Get Notification Statistics
- **Route:** `GET api/v1/notification/stats`
- **Description:** Get notification statistics for logged-in user
- **Payload:** No payload
- **Authentication:** Required

### Get Unread Count
- **Route:** `GET api/v1/notification/unread-count`
- **Description:** Get count of unread notifications
- **Payload:** No payload
- **Authentication:** Required

### Get Notifications by Type
- **Route:** `GET api/v1/notification/type/:type`
- **Description:** Get notifications filtered by type
- **Payload:** No payload, type in URL
- **Authentication:** Required

### Update Notification Preferences
- **Route:** `PATCH api/v1/notification/preferences`
- **Description:** Update user's notification preferences
- **Payload:**
```json
{
  "emailNotifications": true,
  "pushNotifications": true,
  "smsNotifications": false
}
```
- **Authentication:** Required

---

## Brain Signal Routes

**BASE URL:** `api/v1/brain-signal-score`

### Store Brain Signal Score
- **Route:** `POST api/v1/brain-signal-score/store`
- **Description:** Store brain signal/EEG data from IoT device
- **Payload:**
```json
{
  "userId": "",
  "deviceId": "",
  "score": "",
  "timestamp": ""
}
```
- **Authentication:** Not required (IoT device endpoint)

### Get Brain Signal Scores
- **Route:** `GET api/v1/brain-signal-score/:userId`
- **Description:** Get all brain signal scores for a user
- **Payload:** No payload, userId in URL
- **Authentication:** Required

### Get Latest Brain Signal Score
- **Route:** `GET api/v1/brain-signal-score/latest/:userId`
- **Description:** Get latest brain signal score for a user
- **Payload:** No payload, userId in URL
- **Authentication:** Required

---

## Contact

If you need clarification on any payload examples or have questions about the API implementation, please contact the backend developer.
