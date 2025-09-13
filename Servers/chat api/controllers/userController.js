const User = require("../models/User");

exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select("-password");
    if (!user) return res.status(404).json({ error: "User not found" });

    const authHeader = req.headers["authorization"];
    const token = authHeader?.split(" ")[1] || null;

    res.json({ result: "success", token, user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.searchUsers = async (req, res) => {
  try {
    const query = req.query.q;
    if (!query) return res.status(400).json({ error: "Query 'q' required" });

    const users = await User.find({
      _id: { $ne: req.user.userId },
      $or: [{ email: { $regex: query, $options: "i" } }, { displayName: { $regex: query, $options: "i" } }]
    }).select("_id email displayName");

    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
