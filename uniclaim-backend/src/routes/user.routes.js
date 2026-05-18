const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/user.controller');
const { requireRole, requireAuth } = require('../middleware/auth.middleware');

// Étudiant — configurer sa propre chambre
router.patch('/me/room', requireAuth, ctrl.updateRoom);

// Admin
router.get ('/', requireRole('admin'), ctrl.list);
router.post('/', requireRole('admin'), ctrl.create);

module.exports = router;
