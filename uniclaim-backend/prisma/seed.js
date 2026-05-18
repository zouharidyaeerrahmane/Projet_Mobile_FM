require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient({
  log: ['info', 'warn', 'error'],
});

async function main() {
  console.log('Connexion à la base de données...');
  await prisma.$connect();
  console.log('Connecté !\n');

  const hash = async (p) => bcrypt.hash(p, 12);

  const users = [
    {
      fullName : 'Admin Système',
      email    : 'admin@uniclaim.dz',
      password : await hash('Admin1234!'),
      role     : 'admin',
    },
    {
      fullName : 'Ahmed Directeur',
      email    : 'direction@uniclaim.dz',
      password : await hash('Agent1234!'),
      role     : 'agent',
    },
    {
      fullName   : 'Karim Benali',
      email      : 'elec@uniclaim.dz',
      password   : await hash('Tech1234!'),
      role       : 'technician',
      speciality : 'electricite',
    },
    {
      fullName   : 'Sofiane Meziane',
      email      : 'plomb@uniclaim.dz',
      password   : await hash('Tech1234!'),
      role       : 'technician',
      speciality : 'plomberie',
    },
    {
      fullName : 'Omar Bensafi',
      email    : 'securite@uniclaim.dz',
      password : await hash('Secu1234!'),
      role     : 'security',
    },
    {
      fullName   : 'Lina Saadi',
      email      : 'etudiant1@uniclaim.dz',
      password   : await hash('Etud1234!'),
      role       : 'student',
      roomNumber : '204',
    },
    {
      fullName   : 'Yacine Khalfi',
      email      : 'etudiant2@uniclaim.dz',
      password   : await hash('Etud1234!'),
      role       : 'student',
      roomNumber : '115',
    },
  ];

  // Créer les utilisateurs
  const createdUsers = {};
  for (const user of users) {
    const existing = await prisma.user.findUnique({ where: { email: user.email } });
    if (existing) {
      console.log(`⏭️  Déjà existant : ${user.email}`);
      createdUsers[user.email] = existing;
    } else {
      const created = await prisma.user.create({ data: user });
      console.log(`✅ Créé : ${user.email} (role: ${user.role})`);
      createdUsers[user.email] = created;
    }
  }

  // Créer quelques réclamations de test
  console.log('\nCréation des réclamations de test...');

  const etudiant1 = createdUsers['etudiant1@uniclaim.dz'];
  const etudiant2 = createdUsers['etudiant2@uniclaim.dz'];

  // Récupérer les techniciens pour l'assignation
  const techElec  = createdUsers['elec@uniclaim.dz'];
  const techPlomb = createdUsers['plomb@uniclaim.dz'];

  const complaints = [
    {
      title                : 'Prise électrique en panne',
      description          : 'La prise dans ma chambre 204 ne fonctionne plus depuis hier soir.',
      category             : 'electricite',
      status               : 'pending',
      userId               : etudiant1.id,
      assignedTechnicianId : techElec.id,
    },
    {
      title                : 'Fuite d\'eau robinet',
      description          : 'Le robinet de la salle de bain fuit en permanence.',
      category             : 'plomberie',
      status               : 'in_progress',
      userId               : etudiant1.id,
      assignedTechnicianId : techPlomb.id,
    },
    {
      title                : 'Connexion WiFi instable',
      description          : 'Le WiFi se coupe toutes les 10 minutes dans le bloc A chambre 115.',
      category             : 'internet',
      status               : 'pending',
      userId               : etudiant2.id,
      assignedTechnicianId : null,
    },
    {
      title                : 'Porte endommagée',
      description          : 'La serrure de ma chambre est cassée, impossible de fermer à clé.',
      category             : 'menuiserie',
      status               : 'resolved',
      userId               : etudiant2.id,
      assignedTechnicianId : null,
    },
  ];

  for (const complaint of complaints) {
    const existing = await prisma.complaint.findFirst({
      where: { title: complaint.title, userId: complaint.userId },
    });
    if (existing) {
      console.log(`⏭️  Réclamation déjà existante : "${complaint.title}"`);
    } else {
      await prisma.complaint.create({ data: complaint });
      console.log(`✅ Réclamation créée : "${complaint.title}"`);
    }
  }

  // Créer des signalements de bruit de test
  console.log('\nCréation des signalements de bruit de test...');

  const noiseReports = [
    {
      roomNumber  : '204',
      neighborRoom: '205',
      floor       : '2ème',
      block       : 'Bloc A',
      description : 'Musique forte tous les soirs après 23h, impossible de dormir.',
      status      : 'pending',
      userId      : etudiant1.id,
    },
    {
      roomNumber  : '204',
      neighborRoom: '304',
      floor       : '3ème',
      block       : 'Bloc A',
      description : 'Bruit de pas et coups forts répétés depuis le dessus.',
      status      : 'reviewed',
      agentNote   : 'Étudiant chambre 304 averti. Situation surveillée.',
      userId      : etudiant1.id,
    },
    {
      roomNumber  : '115',
      neighborRoom: '116',
      floor       : '1er',
      block       : 'Bloc B',
      description : 'Rassemblement bruyant dans la chambre voisine jusqu\'à 2h du matin.',
      status      : 'resolved',
      agentNote   : 'Avertissement formel émis. Problème résolu.',
      userId      : etudiant2.id,
    },
  ];

  for (const report of noiseReports) {
    const existing = await prisma.noiseReport.findFirst({
      where: { roomNumber: report.roomNumber, neighborRoom: report.neighborRoom, userId: report.userId },
    });
    if (existing) {
      console.log(`⏭️  Signalement déjà existant : chambre ${report.roomNumber}`);
    } else {
      await prisma.noiseReport.create({ data: report });
      console.log(`✅ Signalement créé : chambre ${report.roomNumber} → ${report.neighborRoom}`);
    }
  }

  console.log('\n🎉 Seed terminé avec succès !');
  console.log('\n📋 Comptes disponibles :');
  console.log('   admin@uniclaim.dz       → Admin1234!  (admin)');
  console.log('   direction@uniclaim.dz   → Agent1234!  (agent)');
  console.log('   securite@uniclaim.dz    → Secu1234!   (security)');
  console.log('   elec@uniclaim.dz        → Tech1234!   (technician)');
  console.log('   plomb@uniclaim.dz       → Tech1234!   (technician)');
  console.log('   etudiant1@uniclaim.dz   → Etud1234!   (student)');
  console.log('   etudiant2@uniclaim.dz   → Etud1234!   (student)');
}

main()
  .catch((e) => {
    console.error('❌ Erreur seed :', e.message);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });