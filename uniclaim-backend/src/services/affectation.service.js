const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const SPECIALITES = {
  ELECTRIQUE      : 'electricien',
  PLOMBERIE       : 'plombier',
  MENUISERIE      : 'menuisier',
  CLIMATISATION   : 'technicien_cvc',
  VITRAGE         : 'vitrier',
  INFORMATIQUE    : 'technicien_reseau',
  ESPACES_COMMUNS : 'agent_polyvalent',
  AUTRE           : null,
};

exports.affecterTechnicien = async (reclamationId, categorie) => {
  const specialite = SPECIALITES[categorie];
  if (!specialite) return null;

  const techniciens = await prisma.utilisateur.findMany({
    where: { role: 'TECHNICIEN', specialite, actif: true },
  });
  if (techniciens.length === 0) return null;

  // Round-robin pondéré : choisir le moins chargé
  const charges = await Promise.all(
    techniciens.map(async (t) => {
      const charge = await prisma.reclamation.count({
        where: {
          technicienId: t.id,
          etat: { in: ['SOUMISE', 'EN_COURS', 'EN_ATTENTE_PIECE'] },
        },
      });
      return { technicien: t, charge };
    })
  );

  charges.sort((a, b) => a.charge - b.charge);
  const choisi = charges[0].technicien;

  await prisma.reclamation.update({
    where: { id: reclamationId },
    data : { technicienId: choisi.id },
  });

  return choisi;
};