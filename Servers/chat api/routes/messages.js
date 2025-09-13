const router = require("express").Router();
const authMiddleware = require("../middleware/authMiddleware");
const { getMessages, sendMessage } = require("../controllers/messageController");

router.get("/:threadId", authMiddleware, getMessages);
router.post("/", authMiddleware, sendMessage);

module.exports = router;
