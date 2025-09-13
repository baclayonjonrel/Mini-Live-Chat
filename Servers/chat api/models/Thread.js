// models/Thread.js
const mongoose = require("mongoose");

const threadSchema = new mongoose.Schema({
  participants: [
    { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true }
  ],
  threadName: { type: String },
  lastMessage: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Message"
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Keep updatedAt fresh when lastMessage changes
threadSchema.pre("save", function (next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model("Thread", threadSchema);

