// models/Message.js
const mongoose = require("mongoose");

const messageSchema = new mongoose.Schema({
  senderId: { type: String, required: true, ref: "User" },
  threadId: { type: mongoose.Schema.Types.ObjectId, ref: "Thread", required: true },
  text: { type: String, required: true },
  status: { 
    type: String, 
    enum: ["Sending", "Sent", "Seen"], 
    default: "Sent" 
  },
  reactions: { type: [String], default: [] },
  timestamp: { type: Date, default: Date.now }
});

module.exports = mongoose.model("Message", messageSchema);
