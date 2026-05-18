const express = require('express');
const multer  = require('multer');
const fs      = require('fs');
const path    = require('path');
const router  = express.Router();
const ctrl    = require('../controllers/complaint.controller');
const { requireAuth, requireRole } = require('../middleware/auth.middleware');

const storage = multer.diskStorage({
  destination: (_, __, cb) => {
    const dir = path.join(__dirname, '../../uploads');
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (_, file, cb) => cb(null, `${Date.now()}-${file.originalname}`),
});
const upload = multer({ storage });

// Student
router.post  ('/',                 requireRole('student'),           upload.single('image'), ctrl.create);
router.get   ('/my',              requireRole('student'),           ctrl.myComplaints);
router.patch ('/:id/cancel',      requireRole('student'),           ctrl.cancel);
router.patch ('/:id/rate',        requireRole('student'),           ctrl.rate);

// Technician
router.get   ('/assigned',        requireRole('technician'),        ctrl.assigned);
router.patch ('/:id/status',      requireRole('technician'),        ctrl.updateStatus);

// Direction + Admin
router.get   ('/stats',           requireRole('agent', 'admin'),    ctrl.stats);
router.get   ('/',                requireRole('agent', 'admin'),    ctrl.all);
router.patch ('/:id/admin-status',requireRole('agent', 'admin'),    ctrl.adminStatus);

module.exports = router;
