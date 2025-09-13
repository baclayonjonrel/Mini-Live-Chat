const Thread = require("../models/Thread");

exports.getThreads = async (req, res) => {
  try {
    let threads = await Thread.find({ participants: req.user.userId })
      .populate("lastMessage")
      .populate("participants", "_id displayName email createdAt")
      .sort({ updatedAt: -1 });

    // Dynamic threadName for private chats & isMe for lastMessage
    threads = threads.map(thread => {
      const threadObj = thread.toObject();

      // Dynamic threadName
      if (thread.participants.length === 2) {
        const otherUser = thread.participants.find(u => u._id.toString() !== req.user.userId);
        threadObj.threadName = otherUser ? otherUser.displayName : "Unknown";
      }

      // Add isMe to lastMessage if exists
      if (threadObj.lastMessage) {
        threadObj.lastMessage.isMe = threadObj.lastMessage.senderId === req.user.userId;
      }

      return threadObj;
    });

    res.json(threads);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Delete a thread and all its messages
exports.deleteThread = async (req, res) => {
  try {
    const { threadId } = req.params;

    // Delete all messages in this thread
    await Message.deleteMany({ threadId });

    // Delete the thread itself
    await Thread.findByIdAndDelete(threadId);

    res.json({ success: true, message: "Thread and its messages deleted." });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
