const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/auth.controller');
const { requireAuth } = require('../middleware/auth.middleware');

router.post('/login',   ctrl.login);
router.post('/logout',  requireAuth, ctrl.logout);
router.get ('/profil',  requireAuth, ctrl.profil);
router.get ('/me',      ctrl.me);          // vérification légère sans 401 bloquant

module.exports = router;