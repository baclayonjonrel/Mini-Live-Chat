// server.js
const express = require("express");
const http = require("http");
const { Server } = require("socket.io");

// Initialize Express
const app = express();
const server = http.createServer(app);

// Initialize Socket.IO
const io = new Server(server, {
  cors: {
    origin: "*", 
    methods: ["GET", "POST"]
  }
});

// Serve a test route
app.get("/", (req, res) => {
  res.send("Socket.IO server running!");
});

// Listen for client connections
io.on("connection", (socket) => {
  // Listen for custom events from client
  socket.on("global command", (msg) => {
    // Broadcast to all clients including sender
    if (msg && typeof msg === "object" && msg.type && msg.content) {
        io.emit("global command", msg);
    } else {
        console.log("Invalid command format");
    }
  });

  // Handle client disconnect
  socket.on("disconnect", () => {
    console.log(`Client disconnected: ${socket.id}`);
  });
});

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
