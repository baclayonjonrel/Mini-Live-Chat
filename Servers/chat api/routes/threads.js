const router = require("express").Router();
const authMiddleware = require("../middleware/authMiddleware");
const { getThreads } = require("../controllers/threadController");

router.get("/", authMiddleware, getThreads);

module.exports = router;
