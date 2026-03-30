# 📖 AI Story Teller App

An intelligent storytelling application that generates creative stories based on user prompts using AI. The app is built with a **Flutter frontend**, **Node.js backend**, and **MongoDB database**, following a modern client-server architecture.

---

## 🚀 Features

- ✨ Generate stories from user prompts  
- 🤖 AI-powered storytelling  
- 📱 Cross-platform mobile app (Flutter)  
- 🌐 RESTful API integration  
- 💾 Store generated stories in MongoDB  
- 📜 View story history  
- ⚡ Fast and responsive UI  

---

## 🏗️ Architecture

```
Flutter App (Frontend)
        │
        ▼
Node.js Backend (API Server)
        │
        ▼
MongoDB Database
```

---

## 🛠️ Tech Stack

### Frontend
- Flutter (Dart)
- REST API Integration

### Backend
- Node.js
- Express.js

### Database
- MongoDB (Mongoose)

### AI Integration
- OpenAI API / Any NLP Model

---

## 📂 Project Structure

```
story-teller/
│
├── frontend/              # Flutter App
│   ├── lib/
│   ├── assets/
│   └── pubspec.yaml
│
├── backend/               # Node.js Server
│   ├── controllers/
│   ├── routes/
│   ├── models/
│   ├── config/
│   └── server.js
│
└── README.md
```

---

## ⚙️ Installation & Setup

### 🔹 Clone Repository

```bash
git clone https://github.com/your-username/story-teller.git
cd story-teller
```

---

### 🔹 Backend Setup (Node.js)

```bash
cd backend
npm install
```

Create a `.env` file:

```
PORT=5000
MONGO_URI=your_mongodb_connection_string
OPENAI_API_KEY=your_api_key
```

Run server:

```bash
npm start
```

---

### 🔹 Frontend Setup (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

---

## 📡 API Endpoints

### Generate Story

```
POST /api/story/generate
```

**Request Body:**

```json
{
  "prompt": "A boy who discovers a magical forest"
}
```

**Response:**

```json
{
  "story": "Once upon a time..."
}
```

---

### Get All Stories

```
GET /api/story
```

---

## 💾 Database Schema (MongoDB)

```js
{
  prompt: String,
  story: String,
  createdAt: Date
}
```

---

## 📱 App Screens

- Home Screen (Enter Prompt)
- Generated Story Screen
- History Screen

---

## 🔐 Environment Variables

| Variable        | Description              |
|----------------|------------------------|
| PORT           | Server Port            |
| MONGO_URI      | MongoDB Connection URL |
| OPENAI_API_KEY | AI API Key             |

---

## 📸 Screenshots

_Add your app screenshots here_

---

## 🤝 Contributing

Contributions are welcome!

```
fork -> clone -> create branch -> commit -> push -> PR
```

---


## 👨‍💻 Author

**Zaibten**  
GitHub: https://github.com/Zaibten  

---

## ⭐ Support

If you like this project, give it a ⭐ on GitHub!