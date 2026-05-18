const express = require('express');
const router  = express.Router();
const bcrypt  = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');
const { requireRole } = require('../middleware/auth.middleware');

const prisma = new PrismaClient();

// Créer un compte (admin uniquement)
router.post('/comptes', requireRole('ADMIN'), async (req, res) => {
  const { nom, prenom, email, motDePasse, role, numChambre, bloc, specialite } = req.body;
  try {
    const hash = await bcrypt.hash(motDePasse, 12);
    const user = await prisma.utilisateur.create({
      data: { nom, prenom, email, motDePasse: hash, role, numChambre, bloc, specialite },
    });
    const { motDePasse: _, ...safe } = user;
    res.status(201).json(safe);
  } catch (err) {
    if (err.code === 'P2002') return res.status(400).json({ error: 'Email déjà utilisé' });
    res.status(500).json({ error: err.message });
  }
});

// Lister tous les utilisateurs
router.get('/comptes', requireRole('ADMIN'), async (req, res) => {
  const { role } = req.query;
  const users = await prisma.utilisateur.findMany({
    where : role ? { role } : {},
    select: { id: true, nom: true, prenom: true, email: true, role: true,
               numChambre: true, bloc: true, specialite: true, actif: true },
    orderBy: { dateCreation: 'desc' },
  });
  res.json(users);
});

// Activer / désactiver un compte
router.patch('/comptes/:id/statut', requireRole('ADMIN'), async (req, res) => {
  const { actif } = req.body;
  const user = await prisma.utilisateur.update({
    where: { id: req.params.id },
    data : { actif },
  });
  res.json({ id: user.id, actif: user.actif });
});

module.exports = router;