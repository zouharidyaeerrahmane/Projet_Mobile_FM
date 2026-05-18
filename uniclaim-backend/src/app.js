const express = require('express');
const session = require('express-session');
const cors    = require('cors');
const helmet  = require('helmet');
const morgan  = require('morgan');
const path    = require('path');

const app = express();

app.use(cors({ origin: true, credentials: true }));
app.use(helmet({ crossOriginResourcePolicy: false }));
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use(session({
  secret           : process.env.SESSION_SECRET || 'uniclaim-secret-dev',
  resave           : false,
  saveUninitialized: false,
  cookie           : { httpOnly: true, secure: false, maxAge: 86_400_000 },
}));

// Serve uploaded images
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.use('/api/auth',         require('./routes/auth.routes'));
app.use('/api/complaints',   require('./routes/complaint.routes'));
app.use('/api/noise-reports',require('./routes/noiseReport.routes'));
app.use('/api/users',        require('./routes/user.routes'));

app.get('/', (_, res) => res.json({ message: 'UniClaim API running' }));

module.exports = app;
