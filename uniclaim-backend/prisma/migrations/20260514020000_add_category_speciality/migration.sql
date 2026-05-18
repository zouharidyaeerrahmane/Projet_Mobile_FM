-- AlterTable User: ajouter speciality
ALTER TABLE `User` ADD COLUMN `speciality` VARCHAR(191) NULL;

-- AlterTable Complaint: ajouter category et assignedTechnicianId
ALTER TABLE `Complaint` ADD COLUMN `category` VARCHAR(191) NOT NULL DEFAULT 'autre';
ALTER TABLE `Complaint` ADD COLUMN `assignedTechnicianId` INTEGER NULL;

-- AddForeignKey
ALTER TABLE `Complaint` ADD CONSTRAINT `Complaint_assignedTechnicianId_fkey`
  FOREIGN KEY (`assignedTechnicianId`) REFERENCES `User`(`id`)
  ON DELETE SET NULL ON UPDATE CASCADE;
