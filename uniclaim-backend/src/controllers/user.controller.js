const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

const safeSelect = { id: true, fullName: true, email: true, role: true, roomNumber: true, createdAt: true };

// GET /api/users
exports.list = async (req, res) => {
  const { role } = req.query;
  try {
    const users = await prisma.user.findMany({
      where  : role ? { role } : {},
      select : safeSelect,
      orderBy: { createdAt: 'desc' },
    });
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// PATCH /api/users/me/room  (étudiant — met à jour son numéro de chambre)
exports.updateRoom = async (req, res) => {
  const { roomNumber } = req.body;
  if (!roomNumber || !roomNumber.trim())
    return res.status(400).json({ error: 'Numéro de chambre requis' });
  try {
    const user = await prisma.user.update({
      where : { id: req.session.userId },
      data  : { roomNumber: roomNumber.trim() },
      select: safeSelect,
    });
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// POST /api/users
exports.create = async (req, res) => {
  const { fullName, email, password, role } = req.body;
  if (!fullName || !email || !password || !role)
    return res.status(400).json({ error: 'Tous les champs sont requis' });
  try {
    const hash = await bcrypt.hash(password, 12);
    const user = await prisma.user.create({
      data  : { fullName, email, password: hash, role },
      select: safeSelect,
    });
    res.status(201).json(user);
  } catch (err) {
    if (err.code === 'P2002') return res.status(400).json({ error: 'Email déjà utilisé' });
    res.status(500).json({ error: err.message });
  }
};
