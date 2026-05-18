const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/reclamation.controller');
const { requireAuth, requireRole } = require('../middleware/auth.middleware');

// Étudiant
router.post('/',               requireRole('ETUDIANT'),           ctrl.soumettre);
router.get ('/mes',            requireRole('ETUDIANT'),           ctrl.mesReclamations);
router.get ('/mes/:id',        requireRole('ETUDIANT'),           ctrl.detail);
router.patch('/:id/annuler',   requireRole('ETUDIANT'),           ctrl.annuler);
router.patch('/:id/evaluer',   requireRole('ETUDIANT'),           ctrl.evaluer);

// Technicien
router.get ('/taches',         requireRole('TECHNICIEN'),         ctrl.mesTaches);
router.patch('/:id/etat',      requireRole('TECHNICIEN'),         ctrl.mettreAJourEtat);
router.patch('/:id/escalader', requireRole('TECHNICIEN'),         ctrl.escalader);

// Direction & Admin
router.get ('/',               requireRole('AGENT', 'ADMIN'),     ctrl.toutes);
router.get ('/statistiques',   requireRole('AGENT', 'ADMIN'),     ctrl.statistiques);
router.patch('/:id/reaffecter',requireRole('AGENT', 'ADMIN'),     ctrl.reaffecter);

module.exports = router;