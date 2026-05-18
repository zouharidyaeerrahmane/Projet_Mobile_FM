const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const userSelect = { id: true, fullName: true, email: true, role: true, roomNumber: true, createdAt: true };

// POST /api/noise-reports  (étudiant)
exports.create = async (req, res) => {
  const { neighborRoom, floor, block, description } = req.body;
  if (!neighborRoom || !description)
    return res.status(400).json({ error: 'Chambre voisin et description requis' });

  try {
    // Récupérer le roomNumber depuis le profil
    const user = await prisma.user.findUnique({
      where : { id: req.session.userId },
      select: { roomNumber: true },
    });
    if (!user?.roomNumber)
      return res.status(400).json({ error: 'Veuillez d\'abord configurer votre numéro de chambre dans votre profil.' });

    const report = await prisma.noiseReport.create({
      data   : {
        roomNumber: user.roomNumber,
        neighborRoom, floor, block, description,
        userId: req.session.userId,
      },
      include: { user: { select: userSelect } },
    });
    res.status(201).json(report);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /api/noise-reports/my  (étudiant)
exports.myReports = async (req, res) => {
  try {
    const reports = await prisma.noiseReport.findMany({
      where  : { userId: req.session.userId },
      include: { user: { select: userSelect } },
      orderBy: { createdAt: 'desc' },
    });
    res.json(reports);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /api/noise-reports/my-room  (étudiant — retourne son roomNumber)
exports.myRoom = async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where : { id: req.session.userId },
      select: { roomNumber: true },
    });
    res.json({ roomNumber: user?.roomNumber ?? null });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// PATCH /api/noise-reports/:id/cancel  (étudiant)
exports.cancel = async (req, res) => {
  try {
    const r = await prisma.noiseReport.findFirst({
      where: { id: Number(req.params.id), userId: req.session.userId },
    });
    if (!r) return res.status(404).json({ error: 'Signalement introuvable' });
    if (r.status !== 'pending')
      return res.status(400).json({ error: 'Annulation impossible : déjà traité' });
    const updated = await prisma.noiseReport.update({
      where: { id: r.id }, data: { status: 'cancelled' },
    });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /api/noise-reports  (agent de sécurité, paginé)
exports.all = async (req, res) => {
  const { page = 1, limit = 15, status, search } = req.query;
  const where = {};
  if (status && status !== 'all') where.status = status;
  if (search) {
    where.OR = [
      { roomNumber  : { contains: search } },
      { neighborRoom: { contains: search } },
      { description : { contains: search } },
      { block       : { contains: search } },
    ];
  }
  try {
    const [total, data] = await Promise.all([
      prisma.noiseReport.count({ where }),
      prisma.noiseReport.findMany({
        where,
        include: { user: { select: userSelect } },
        orderBy: { createdAt: 'desc' },
        skip   : (Number(page) - 1) * Number(limit),
        take   : Number(limit),
      }),
    ]);
    res.json({ data, total });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// PATCH /api/noise-reports/:id/status  (agent de sécurité)
exports.updateStatus = async (req, res) => {
  const { status, agentNote } = req.body;
  const allowed = ['reviewed', 'resolved', 'rejected'];
  if (!allowed.includes(status))
    return res.status(400).json({ error: `Statut invalide. Valeurs: ${allowed.join(', ')}` });
  try {
    const updated = await prisma.noiseReport.update({
      where: { id: Number(req.params.id) },
      data : { status, ...(agentNote !== undefined && { agentNote }) },
      include: { user: { select: userSelect } },
    });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /api/noise-reports/stats  (agent de sécurité)
exports.stats = async (req, res) => {
  try {
    const [total, pending, reviewed, resolved, rejected] = await Promise.all([
      prisma.noiseReport.count(),
      prisma.noiseReport.count({ where: { status: 'pending' } }),
      prisma.noiseReport.count({ where: { status: 'reviewed' } }),
      prisma.noiseReport.count({ where: { status: 'resolved' } }),
      prisma.noiseReport.count({ where: { status: 'rejected' } }),
    ]);
    res.json({ total, pending, reviewed, resolved, rejected });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
