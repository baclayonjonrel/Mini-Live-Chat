const Message = require("../models/Message");
const Thread = require("../models/Thread");
const User = require("../models/User");

// GET messages for a thread
exports.getMessages = async (req, res) => {
  try {
    const { threadId } = req.params;
    const currentUserId = req.user.userId;

    if (!threadId) return res.status(400).json({ error: "threadId is required" });

    const messages = await Message.find({ threadId })
      .sort({ timestamp: 1 })
      .limit(100);

    // Attach dynamic isMe
    const response = messages.map(msg => {
      const obj = msg.toObject();
      obj.isMe = obj.senderId === currentUserId;
      return obj;
    });

    res.json({ messages: response });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};


exports.sendMessage = async (req, res) => {
  try {
    const { text, threadId, participantIds } = req.body;
    const currentUserId = req.user.userId;

    if (!text) return res.status(400).json({ error: "Message text is required" });

    let thread;

    // Existing thread
    if (threadId) {
      thread = await Thread.findById(threadId);
      if (!thread) return res.status(404).json({ error: "Thread not found" });

    // Create or find thread by participants
    } else if (participantIds?.length > 0) {
      const allParticipants = [...new Set([currentUserId, ...participantIds])];
      thread = await Thread.findOne({ participants: { $all: allParticipants, $size: allParticipants.length } });

      if (!thread) {
        let threadName = "New Group";

        if (allParticipants.length === 2) {
          const otherUser = await User.findById(participantIds[0]);
          if (otherUser) threadName = otherUser.displayName;
        } else {
          const users = await User.find({ _id: { $in: allParticipants } });
          const names = users.map(u => u.displayName);
          threadName = names.slice(0, 2).join(", ") + (names.length > 2 ? "..." : "");
        }

        thread = new Thread({ participants: allParticipants, threadName });
        await thread.save();
        thread = await Thread.findById(thread._id).populate("participants", "_id displayName email createdAt");
      }

    } else {
      return res.status(400).json({ error: "Either threadId or participantIds must be provided" });
    }

    // Create message using new model
    const message = new Message({
      senderId: currentUserId,
      threadId: thread._id,
      text,
      status: "Sent",
      reactions: []
    });

    await message.save();

    // Update thread
    thread.lastMessage = message._id;
    thread.updatedAt = Date.now();
    await thread.save();

    // Return message with dynamic isMe
    res.json({
      message: {
        ...message.toObject(),
        isMe: message.senderId === currentUserId
      },
      thread
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Update a message (text or reactions)
exports.updateMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    const { text, reactions, status } = req.body;
    const message = await Message.findById(messageId);

    if (!message) return res.status(404).json({ error: "Message not found" });

    // Only the sender can edit the message
    if (message.senderId !== req.user.userId) {
      return res.status(403).json({ error: "Not authorized to edit this message" });
    }

    if (text !== undefined) message.text = text;
    if (reactions !== undefined) message.reactions = reactions;
    if (status !== undefined) message.status = status;

    await message.save();

    res.json({ message });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};