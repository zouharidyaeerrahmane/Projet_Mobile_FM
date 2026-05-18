const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/noiseReport.controller');
const { requireRole } = require('../middleware/auth.middleware');

// Étudiant
router.post  ('/',              requireRole('student'),   ctrl.create);
router.get   ('/my',            requireRole('student'),   ctrl.myReports);
router.get   ('/my-room',       requireRole('student'),   ctrl.myRoom);
router.patch ('/:id/cancel',    requireRole('student'),   ctrl.cancel);

// Agent de sécurité
router.get   ('/stats',         requireRole('security'),  ctrl.stats);
router.get   ('/',              requireRole('security'),  ctrl.all);
router.patch ('/:id/status',    requireRole('security'),  ctrl.updateStatus);

module.exports = router;
