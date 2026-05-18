const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const userSelect = { id: true, fullName: true, email: true, role: true, roomNumber: true, speciality: true, createdAt: true };

const VALID_CATEGORIES = ['electricite', 'plomberie', 'menuiserie', 'climatisation', 'internet', 'autre'];

// POST /api/complaints
exports.create = async (req, res) => {
  const { title, description, category = 'autre' } = req.body;
  const image = req.file ? req.file.filename : null;

  if (!title || !description)
    return res.status(400).json({ error: 'Titre et description requis' });

  const cat = VALID_CATEGORIES.includes(category) ? category : 'autre';

  try {
    // Trouver le technicien dédié à cette catégorie
    const technician = await prisma.user.findFirst({
      where: { role: 'technician', speciality: cat },
      select: { id: true },
    });

    const complaint = await prisma.complaint.create({
      data   : {
        title, description, image, category: cat,
        userId: req.session.userId,
        assignedTechnicianId: technician?.id ?? null,
      },
      include: {
        user              : { select: userSelect },
        assignedTechnician: { select: userSelect },
      },
    });
    res.status(201).json(complaint);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /api/complaints/my
exports.myComplaints = async (req, res) => {
  try {
    const complaints = await prisma.complaint.findMany({
      where  : { userId: req.session.userId },
      include: {
        user              : { select: userSelect },
        assignedTechnician: { select: userSelect },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(complaints);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// PATCH /api/complaints/:id/cancel
exports.cancel = async (req, res) => {
  try {
    const c = await prisma.complaint.findFirst({
      where: { id: Number(req.params.id), userId: req.session.userId },
    });
    if (!c) return res.status(404).json({ error: 'Réclamation introuvable' });
    if (c.status !== 'pending')
      return res.status(400).json({ error: 'Annulation impossible : déjà prise en charge' });
    const updated = await prisma.complaint.update({
      where: { id: c.id }, data: { status: 'cancelled' },
    });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// PATCH /api/complaints/:id/rate
exports.rate = async (req, res) => {
  try {
    const updated = await prisma.complaint.update({
      where: { id: Number(req.params.id) },
      data : { status: 'closed' },
    });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /api/complaints/assigned  (technicien — seulement ses tâches par spécialité)
exports.assigned = async (req, res) => {
  try {
    // Récupérer la spécialité du technicien connecté
    const tech = await prisma.user.findUnique({
      where : { id: req.session.userId },
      select: { speciality: true },
    });

    // Filtrer par technicien assigné OU par catégorie si pas encore assigné
    const where = tech?.speciality
      ? {
          OR: [
            { assignedTechnicianId: req.session.userId },
            { assignedTechnicianId: null, category: tech.speciality },
          ],
        }
      : {};  // pas de spécialité → voir tout

    const complaints = await prisma.complaint.findMany({
      where,
      include: {
        user              : { select: userSelect },
        assignedTechnician: { select: userSelect },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(complaints);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// PATCH /api/complaints/:id/status  (technician)
exports.updateStatus = async (req, res) => {
  const { status } = req.body;
  try {
    const updated = await prisma.complaint.update({
      where: { id: Number(req.params.id) }, data: { status },
    });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /api/complaints/stats
exports.stats = async (req, res) => {
  try {
    const [total, pending, in_progress, waiting, resolved, closed, cancelled] = await Promise.all([
      prisma.complaint.count(),
      prisma.complaint.count({ where: { status: 'pending' } }),
      prisma.complaint.count({ where: { status: 'in_progress' } }),
      prisma.complaint.count({ where: { status: 'waiting' } }),
      prisma.complaint.count({ where: { status: 'resolved' } }),
      prisma.complaint.count({ where: { status: 'closed' } }),
      prisma.complaint.count({ where: { status: 'cancelled' } }),
    ]);
    res.json({ total, pending, in_progress, waiting, resolved, closed, cancelled });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /api/complaints  (direction/admin, paginated)
exports.all = async (req, res) => {
  const { page = 1, limit = 15, status, search } = req.query;
  const where = {};
  if (status && status !== 'all') where.status = status;
  if (search) {
    where.OR = [
      { title:       { contains: search } },
      { description: { contains: search } },
    ];
  }
  try {
    const [total, data] = await Promise.all([
      prisma.complaint.count({ where }),
      prisma.complaint.findMany({
        where,
        include: {
          user              : { select: userSelect },
          assignedTechnician: { select: userSelect },
        },
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

// PATCH /api/complaints/:id/admin-status
exports.adminStatus = async (req, res) => {
  const { status } = req.body;
  try {
    const updated = await prisma.complaint.update({
      where: { id: Number(req.params.id) }, data: { status },
    });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
