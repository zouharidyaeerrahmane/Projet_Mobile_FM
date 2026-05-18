-- CreateTable
CREATE TABLE `NoiseReport` (
    `id`           INTEGER NOT NULL AUTO_INCREMENT,
    `roomNumber`   VARCHAR(191) NOT NULL,
    `neighborRoom` VARCHAR(191) NOT NULL,
    `floor`        VARCHAR(191) NULL,
    `block`        VARCHAR(191) NULL,
    `description`  VARCHAR(191) NOT NULL,
    `status`       VARCHAR(191) NOT NULL DEFAULT 'pending',
    `agentNote`    VARCHAR(191) NULL,
    `createdAt`    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `userId`       INTEGER NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `NoiseReport` ADD CONSTRAINT `NoiseReport_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
