# Mini-Live-Chat

Mini-Live-Chat is a real-time communication platform that enables seamless text chat and high-quality video calls on iOS.  
It’s powered by:

- **WebSocket (Socket.IO)** for instant messaging  
- **REST API (Node.js + MongoDB)** for backend operations  
- **WebRTC (SkyWay)** for low-latency, high-quality video calls  
- **Gemini AI** for generating smart meeting notes  
- **Live Speech-to-Text** transcription during video calls  

## ✨ Features

- 📩 Real-time text messaging powered by WebSocket  
- 🎥 High-quality video calls using WebRTC (SkyWay)  
- 🗄️ Scalable REST API with MongoDB backend  
- 📝 AI-powered note generation (Gemini integration)  
- 🗣️ Live speech-to-text transcription during video calls  
- 🧩 Modular architecture with separate servers and client app  

## 📁 Project Structure

```
Mini-Live-Chat/
│
├── servers/
│   ├── chat-api/       # REST API server (Node.js + MongoDB)
│   └── socket-io/      # WebSocket server (Socket.IO)
│
└── ios-app/            # iOS client app (Swift + WebRTC + Gemini + Speech-to-Text)
```

## 🚀 Server Setup

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/yourusername/Mini-Live-Chat.git
cd Mini-Live-Chat/servers
```

### 2️⃣ chat-api (REST API + MongoDB)

```bash
cd chat-api
npm install
# configure your .env with MongoDB connection string and Gemini API key
node server-api.js
```

#### 📄 Create `.env` file inside `chat-api`:

```
JWT_SECRET=SecretKeyHere
MONGO_URI=mongodb+srv://your mongo db credentials/chatdb
PORT=4000
```

> ⚠️ **Security Tip:** In a real production repository, never commit `.env` files with secrets or credentials. Add them to `.gitignore` instead.

### 3️⃣ socket-io (WebSocket Server)

```bash
cd ../socket-io
npm install
# configure your .env if needed
node server.js
```

### 4️⃣ iOS App

Open `ios-app/MiniLiveChat.xcodeproj` in Xcode and run on a simulator or device.  

Run:

```bash
pod install
```

Make sure the API and WebSocket servers are running before launching the app.

> **Tip:** For AI notes and live transcription you’ll need to provide your Gemini API key (or other speech-to-text API credentials) in the iOS app’s configuration.

---

💡 **Contributing**  
Feel free to contribute by submitting issues or pull requests!
