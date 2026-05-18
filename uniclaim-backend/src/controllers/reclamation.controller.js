const { PrismaClient } = require('@prisma/client');
const affectation = require('../services/affectation.service');
const prisma = new PrismaClient();

// ── Étudiant : soumettre ──────────────────────────────────────────
exports.soumettre = async (req, res) => {
  const { categorie, description, urgence } = req.body;
  const etudiantId = req.session.userId;   // ← session, pas JWT

  if (!categorie || !description) {
    return res.status(400).json({ error: 'Catégorie et description obligatoires' });
  }

  try {
    // Anti-doublon
    const doublon = await prisma.reclamation.findFirst({
      where: { etudiantId, categorie, etat: { in: ['SOUMISE', 'EN_COURS'] } },
    });
    if (doublon) {
      return res.status(400).json({
        error: 'Une réclamation similaire est déjà ouverte',
        reclamationId: doublon.id,
      });
    }

    const reclamation = await prisma.reclamation.create({
      data: { etudiantId, categorie, description, urgence: urgence || 'NORMALE' },
    });

    // Historique
    await prisma.historiqueReclamation.create({
      data: {
        reclamationId: reclamation.id,
        auteurId     : etudiantId,
        nouvelEtat   : 'SOUMISE',
        commentaire  : 'Réclamation soumise par l\'étudiant',
      },
    });

    // Affectation automatique
    const technicien = await affectation.affecterTechnicien(reclamation.id, categorie);
    if (!technicien) {
      await prisma.reclamation.update({
        where: { id: reclamation.id },
        data : { etat: 'EN_ATTENTE_AFFECTATION' },
      });
    }

    const result = await prisma.reclamation.findUnique({
      where  : { id: reclamation.id },
      include: { technicien: { select: { nom: true, prenom: true, specialite: true } } },
    });
    res.status(201).json(result);

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

// ── Étudiant : liste de ses réclamations ─────────────────────────
exports.mesReclamations = async (req, res) => {
  const { etat, page = 1, limit = 10 } = req.query;
  const where = { etudiantId: req.session.userId };
  if (etat) where.etat = etat;

  try {
    const [total, reclamations] = await Promise.all([
      prisma.reclamation.count({ where }),
      prisma.reclamation.findMany({
        where,
        include: {
          technicien   : { select: { nom: true, prenom: true } },
          historiques  : { orderBy: { date: 'desc' } },
          piecesJointes: true,
        },
        orderBy: { dateCreation: 'desc' },
        skip   : (Number(page) - 1) * Number(limit),
        take   : Number(limit),
      }),
    ]);
    res.json({ total, page: Number(page), reclamations });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

// ── Étudiant : détail d'une réclamation ──────────────────────────
exports.detail = async (req, res) => {
  try {
    const reclamation = await prisma.reclamation.findFirst({
      where  : { id: req.params.id, etudiantId: req.session.userId },
      include: {
        technicien   : { select: { nom: true, prenom: true, specialite: true } },
        historiques  : { orderBy: { date: 'asc' }, include: { auteur: { select: { nom: true, prenom: true, role: true } } } },
        piecesJointes: true,
      },
    });
    if (!reclamation) return res.status(404).json({ error: 'Réclamation introuvable' });
    res.json(reclamation);
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

// ── Étudiant : annuler ────────────────────────────────────────────
exports.annuler = async (req, res) => {
  try {
    const r = await prisma.reclamation.findFirst({
      where: { id: req.params.id, etudiantId: req.session.userId },
    });
    if (!r) return res.status(404).json({ error: 'Réclamation introuvable' });
    if (r.etat !== 'SOUMISE') {
      return res.status(400).json({ error: 'Annulation impossible : déjà prise en charge' });
    }

    await prisma.reclamation.update({
      where: { id: req.params.id },
      data : { etat: 'ANNULEE' },
    });
    await prisma.historiqueReclamation.create({
      data: {
        reclamationId: req.params.id,
        auteurId     : req.session.userId,
        ancienEtat   : 'SOUMISE',
        nouvelEtat   : 'ANNULEE',
        commentaire  : 'Annulée par l\'étudiant',
      },
    });
    res.json({ message: 'Réclamation annulée' });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

// ── Étudiant : évaluer ────────────────────────────────────────────
exports.evaluer = async (req, res) => {
  const { note, commentaire } = req.body;
  if (!note || note < 1 || note > 5) {
    return res.status(400).json({ error: 'Note entre 1 et 5 requise' });
  }
  try {
    const r = await prisma.reclamation.findFirst({
      where: { id: req.params.id, etudiantId: req.session.userId, etat: 'RESOLU' },
    });
    if (!r) return res.status(404).json({ error: 'Réclamation introuvable ou non résolue' });

    const updated = await prisma.reclamation.update({
      where: { id: req.params.id },
      data : { noteEtudiant: Number(note), commentaireEval: commentaire, etat: 'CLOTUREE' },
    });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

// ── Technicien : ses tâches ───────────────────────────────────────
exports.mesTaches = async (req, res) => {
  const { etat } = req.query;
  const where = { technicienId: req.session.userId };
  if (etat) where.etat = etat;

  try {
    const taches = await prisma.reclamation.findMany({
      where,
      include: {
        etudiant     : { select: { nom: true, prenom: true, numChambre: true, bloc: true } },
        historiques  : { orderBy: { date: 'desc' }, take: 3 },
        piecesJointes: true,
      },
      orderBy: [{ urgence: 'desc' }, { dateCreation: 'asc' }],
    });
    res.json(taches);
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

// ── Technicien : mettre à jour l'état ────────────────────────────
exports.mettreAJourEtat = async (req, res) => {
  const { nouvelEtat, commentaire } = req.body;
  const technicienId = req.session.userId;

  const etatsValides = ['EN_COURS', 'EN_ATTENTE_PIECE', 'RESOLU', 'NON_RESOLU', 'CLOTUREE'];
  if (!etatsValides.includes(nouvelEtat)) {
    return res.status(400).json({ error: `État invalide. Valeurs : ${etatsValides.join(', ')}` });
  }
  if (!commentaire?.trim()) {
    return res.status(400).json({ error: 'Un commentaire est obligatoire' });
  }

  try {
    const r = await prisma.reclamation.findFirst({
      where: { id: req.params.id, technicienId },
    });
    if (!r) return res.status(404).json({ error: 'Tâche introuvable' });

    const updated = await prisma.reclamation.update({
      where: { id: req.params.id },
      data : { etat: nouvelEtat },
    });
    await prisma.historiqueReclamation.create({
      data: {
        reclamationId: req.params.id,
        auteurId     : technicienId,
        ancienEtat   : r.etat,
        nouvelEtat,
        commentaire  : commentaire.trim(),
      },
    });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

// ── Technicien : escalader ────────────────────────────────────────
exports.escalader = async (req, res) => {
  const { commentaire } = req.body;
  const technicienId = req.session.userId;

  try {
    const r = await prisma.reclamation.findFirst({
      where: { id: req.params.id, technicienId },
    });
    if (!r) return res.status(404).json({ error: 'Tâche introuvable' });

    await prisma.reclamation.update({
      where: { id: req.params.id },
      data : { etat: 'NON_RESOLU', technicienId: null },
    });
    await prisma.historiqueReclamation.create({
      data: {
        reclamationId: req.params.id,
        auteurId     : technicienId,
        ancienEtat   : r.etat,
        nouvelEtat   : 'NON_RESOLU',
        commentaire  : `Escaladé : ${commentaire}`,
      },
    });
    res.json({ message: 'Réclamation escaladée à la direction' });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

// ── Direction : toutes les réclamations ──────────────────────────
exports.toutes = async (req, res) => {
  const {
    etat, categorie, urgence, bloc, technicienId,
    dateDebut, dateFin, page = 1, limit = 20,
  } = req.query;

  const where = {};
  if (etat)         where.etat      = etat;
  if (categorie)    where.categorie = categorie;
  if (urgence)      where.urgence   = urgence;
  if (technicienId) where.technicienId = technicienId;
  if (bloc)         where.etudiant  = { bloc };
  if (dateDebut || dateFin) {
    where.dateCreation = {};
    if (dateDebut) where.dateCreation.gte = new Date(dateDebut);
    if (dateFin)   where.dateCreation.lte = new Date(dateFin);
  }

  try {
    const [total, reclamations] = await Promise.all([
      prisma.reclamation.count({ where }),
      prisma.reclamation.findMany({
        where,
        include: {
          etudiant     : { select: { nom: true, prenom: true, numChambre: true, bloc: true } },
          technicien   : { select: { nom: true, prenom: true, specialite: true } },
          historiques  : { orderBy: { date: 'desc' } },
          piecesJointes: true,
        },
        orderBy: [{ urgence: 'desc' }, { dateCreation: 'desc' }],
        skip   : (Number(page) - 1) * Number(limit),
        take   : Number(limit),
      }),
    ]);
    res.json({ total, page: Number(page), reclamations });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

// ── Direction : statistiques dashboard ───────────────────────────
exports.statistiques = async (req, res) => {
  try {
    const [parEtat, parCategorie, resolues, techniciens] = await Promise.all([
      prisma.reclamation.groupBy({ by: ['etat'],      _count: { _all: true } }),
      prisma.reclamation.groupBy({ by: ['categorie'], _count: { _all: true } }),
      prisma.reclamation.findMany({
        where : { etat: { in: ['RESOLU', 'CLOTUREE'] } },
        select: { dateCreation: true, dateMiseAJour: true },
      }),
      prisma.utilisateur.findMany({
        where : { role: 'TECHNICIEN' },
        select: {
          id: true, nom: true, prenom: true, specialite: true,
          reclamationsTechnicien: { select: { etat: true, noteEtudiant: true } },
        },
      }),
    ]);

    // Temps moyen de résolution (en heures)
    const tempsMoyen = resolues.length > 0
      ? resolues.reduce((acc, r) => {
          return acc + (r.dateMiseAJour - r.dateCreation) / 3_600_000;
        }, 0) / resolues.length
      : 0;

    const statsEtat      = Object.fromEntries(parEtat.map(e => [e.etat, e._count._all]));
    const statsCategorie = Object.fromEntries(parCategorie.map(c => [c.categorie, c._count._all]));

    const statsTechniciens = techniciens.map(t => {
      const taches   = t.reclamationsTechnicien;
      const resolues = taches.filter(r => ['RESOLU', 'CLOTUREE'].includes(r.etat)).length;
      const notes    = taches.filter(r => r.noteEtudiant).map(r => r.noteEtudiant);
      return {
        id          : t.id,
        nom         : t.nom,
        prenom      : t.prenom,
        specialite  : t.specialite,
        totalTaches : taches.length,
        resolues,
        noteMoyenne : notes.length
          ? (notes.reduce((a, b) => a + b, 0) / notes.length).toFixed(1)
          : null,
      };
    });

    res.json({
      parEtat,
      parCategorie      : statsCategorie,
      tempsMoyenHeures  : Math.round(tempsMoyen),
      techniciens       : statsTechniciens,
    });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

// ── Direction : réaffecter une réclamation ────────────────────────
exports.reaffecter = async (req, res) => {
  const { technicienId } = req.body;
  try {
    const technicien = await prisma.utilisateur.findFirst({
      where: { id: technicienId, role: 'TECHNICIEN', actif: true },
    });
    if (!technicien) return res.status(404).json({ error: 'Technicien introuvable' });

    const updated = await prisma.reclamation.update({
      where: { id: req.params.id },
      data : { technicienId, etat: 'SOUMISE' },
    });
    await prisma.historiqueReclamation.create({
      data: {
        reclamationId: req.params.id,
        auteurId     : req.session.userId,
        nouvelEtat   : 'SOUMISE',
        commentaire  : `Réaffecté à ${technicien.prenom} ${technicien.nom}`,
      },
    });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};