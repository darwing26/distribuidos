-- MySQL schema generated from server/db.py (SQLModel models)
-- Database and charset
CREATE DATABASE IF NOT EXISTS `distribuidos_db` CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
USE `distribuidos_db`;

-- Drop existing tables in order to avoid FK conflicts
DROP TABLE IF EXISTS `image_task`;
DROP TABLE IF EXISTS `job_batch`;
DROP TABLE IF EXISTS `node`;
DROP TABLE IF EXISTS `user`;

-- Users table (corresponds to User model)
CREATE TABLE `user` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `email` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_user_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Nodes table (corresponds to Node model)
CREATE TABLE `node` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `host` VARCHAR(255) NOT NULL,
  `port` INT NOT NULL,
  `status` VARCHAR(20) NOT NULL DEFAULT 'inactive',
  `last_heartbeat` DATETIME NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_node_host_port` (`host`, `port`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Job batches (corresponds to JobBatch model)
CREATE TABLE `job_batch` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `user_id` INT NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` VARCHAR(20) NOT NULL DEFAULT 'queued',
  `note` TEXT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_jobbatch_user` (`user_id`),
  CONSTRAINT `fk_jobbatch_user` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Image tasks (corresponds to ImageTask model)
CREATE TABLE `image_task` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `batch_id` INT NOT NULL,
  `image_id` VARCHAR(255) NOT NULL,
  `transformations` TEXT NOT NULL,
  `received_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `processed_at` DATETIME NULL,
  `node_id` INT NULL,
  `result_path` VARCHAR(512) NULL,
  `status` VARCHAR(20) NOT NULL DEFAULT 'queued',
  `log` TEXT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_imagetask_batch` (`batch_id`),
  INDEX `idx_imagetask_node` (`node_id`),
  CONSTRAINT `fk_imagetask_batch` FOREIGN KEY (`batch_id`) REFERENCES `job_batch`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_imagetask_node` FOREIGN KEY (`node_id`) REFERENCES `node`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Notes / mapping decisions:
-- 1) SQLite `datetime` fields mapped to MySQL DATETIME with DEFAULT CURRENT_TIMESTAMP for created/received fields.
-- 2) IDs use INT AUTO_INCREMENT primary keys.
-- 3) `transformations` and `log` are TEXT because SQLModel uses str for potentially long text.
-- 4) Foreign keys: job_batch.user_id -> user.id (ON DELETE CASCADE), image_task.batch_id -> job_batch.id (ON DELETE CASCADE), image_task.node_id -> node.id (ON DELETE SET NULL) because node_id is optional.
-- 5) Adjust VARCHAR lengths if you expect larger values.

-- End of schema
