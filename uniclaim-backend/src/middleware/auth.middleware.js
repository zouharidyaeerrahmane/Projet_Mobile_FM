const requireAuth = (req, res, next) => {
  if (!req.session?.userId)
    return res.status(401).json({ error: 'Non authentifié — veuillez vous connecter' });
  next();
};

const requireRole = (...roles) => (req, res, next) => {
  if (!req.session?.userId)
    return res.status(401).json({ error: 'Non authentifié' });
  if (!roles.includes(req.session.role))
    return res.status(403).json({ error: `Accès refusé — rôle requis : ${roles.join(' ou ')}` });
  next();
};

module.exports = { requireAuth, requireRole };
