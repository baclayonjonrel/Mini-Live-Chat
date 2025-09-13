const router = require("express").Router();
const authMiddleware = require("../middleware/authMiddleware");
const { getMe, searchUsers } = require("../controllers/userController");

router.get("/me", authMiddleware, getMe);
router.get("/search", authMiddleware, searchUsers);

module.exports = router;
