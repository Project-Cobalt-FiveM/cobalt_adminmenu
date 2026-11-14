CREATE TABLE IF NOT EXISTS `warns` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `sender_identifier` VARCHAR(255) DEFAULT NULL,
  `sender_name` VARCHAR(255) DEFAULT NULL,
  `target_identifier` VARCHAR(255) NOT NULL,
  `reason` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `target_identifier` (`target_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `admin_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `admin_license` VARCHAR(255) DEFAULT NULL,
  `admin_name` VARCHAR(255) DEFAULT NULL,
  `action` VARCHAR(64) NOT NULL,
  `target_license` VARCHAR(255) DEFAULT NULL,
  `details` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `admin_license` (`admin_license`),
  KEY `target_license` (`target_license`),
  KEY `action` (`action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
