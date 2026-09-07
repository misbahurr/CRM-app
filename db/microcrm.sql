-- Micro-CRM MySQL dump
-- Database: microcrm
-- Engine: MySQL 8.0 (utf8mb4)
-- Includes schema, indexes, Alembic revision 002_scale_indexes, seed rows, and cached AI insights.
--
-- Restore into the Docker MySQL on port 3307:
--   docker exec -i microcrm-mysql mysql -uroot -ppassword < db/microcrm.sql
-- Or:
--   mysql -h 127.0.0.1 -P 3307 -uroot -ppassword < db/microcrm.sql

-- MySQL dump 10.13  Distrib 8.0.46, for Linux (x86_64)
--
-- Host: localhost    Database: microcrm
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

CREATE DATABASE IF NOT EXISTS `microcrm` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `microcrm`;

--
-- Table structure for table `customers`
--

DROP TABLE IF EXISTS `customers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customers` (
  `id` varchar(20) NOT NULL,
  `name` varchar(255) NOT NULL,
  `status` enum('prospect','customer') NOT NULL,
  `created_at` date NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_customers_status` (`status`),
  KEY `ix_customers_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customers`
--

LOCK TABLES `customers` WRITE;
/*!40000 ALTER TABLE `customers` DISABLE KEYS */;
INSERT INTO `customers` (`id`, `name`, `status`, `created_at`) VALUES ('CUS-001','BrightSmile Dental','prospect','2026-04-02'),('CUS-002','Harbor Pediatric Dentistry','customer','2023-11-14'),('CUS-003','Oak & Pine Family Dental','prospect','2026-07-21'),('CUS-004','Lakeside Orthodontics','customer','2024-02-08'),('CUS-005','Summit Implant Studio','prospect','2026-05-18'),('CUS-006','Cedar Ridge Dental','customer','2022-09-30'),('CUS-007','Northstar Endodontics','prospect','2026-06-11'),('CUS-008','Willow Creek Oral Surgery','customer','2023-05-03'),('CUS-009','Metro Dental Group','prospect','2026-08-04'),('CUS-010','Sunshine Smiles','customer','2021-06-22'),('CUS-011','Pinecrest Periodontics','prospect','2026-03-27'),('CUS-012','Riverbend Family Dentistry','customer','2024-10-19');
/*!40000 ALTER TABLE `customers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `contacts`
--

DROP TABLE IF EXISTS `contacts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `contacts` (
  `id` varchar(20) NOT NULL,
  `customer_id` varchar(20) NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `role` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_contacts_customer_id` (`customer_id`),
  KEY `ix_contacts_email` (`email`),
  CONSTRAINT `contacts_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contacts`
--

LOCK TABLES `contacts` WRITE;
/*!40000 ALTER TABLE `contacts` DISABLE KEYS */;
INSERT INTO `contacts` (`id`, `customer_id`, `name`, `email`, `role`) VALUES ('CON-001','CUS-001','Dr. Maya Patel','maya.patel@brightsmile.example','Owner'),('CON-002','CUS-001','Luis Ortega','luis.ortega@brightsmile.example','Office Manager'),('CON-003','CUS-002','Dr. Hannah Cho','hannah.cho@harborpedo.example','Owner'),('CON-004','CUS-002','Priya Shah','priya.shah@harborpedo.example','Practice Administrator'),('CON-005','CUS-003','Dr. Eli Navarro','eli.navarro@oakpine.example','Owner'),('CON-006','CUS-003','Jordan Blake','jordan.blake@oakpine.example','Procurement'),('CON-007','CUS-004','Dr. Sofia Rahman','sofia.rahman@lakesideortho.example','Owner'),('CON-008','CUS-004','Chris Nguyen','chris.nguyen@lakesideortho.example','Billing Lead'),('CON-009','CUS-005','Dr. Owen Brooks','owen.brooks@summitimplant.example','Clinical Director'),('CON-010','CUS-006','Dr. Lena Hart','lena.hart@cedarridge.example','Owner'),('CON-011','CUS-006','Marcus Lee','marcus.lee@cedarridge.example','Office Manager'),('CON-012','CUS-007','Dr. Nina Volkov','nina.volkov@northstarendo.example','Owner'),('CON-013','CUS-008','Dr. Andre Silva','andre.silva@willowcreek.example','Owner'),('CON-014','CUS-008','Kim Park','kim.park@willowcreek.example','Surgical Coordinator'),('CON-015','CUS-009','Dr. Rachel Kim','rachel.kim@metrodental.example','Managing Partner'),('CON-016','CUS-009','Tom Alvarez','tom.alvarez@metrodental.example','Ops Manager'),('CON-017','CUS-010','Dr. Amira Hassan','amira.hassan@sunshinesmiles.example','Owner'),('CON-018','CUS-011','Dr. Peter Lang','peter.lang@pinecrestperio.example','Owner'),('CON-019','CUS-012','Dr. Claire Bennett','claire.bennett@riverbend.example','Owner'),('CON-020','CUS-012','Sam Ortiz','sam.ortiz@riverbend.example','Front Desk Lead');
/*!40000 ALTER TABLE `contacts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `interactions`
--

DROP TABLE IF EXISTS `interactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `interactions` (
  `id` varchar(20) NOT NULL,
  `customer_id` varchar(20) NOT NULL,
  `contact_id` varchar(20) NOT NULL,
  `type` enum('email','call','meeting','note') NOT NULL,
  `occurred_at` date NOT NULL,
  `notes` text,
  PRIMARY KEY (`id`),
  KEY `ix_interactions_customer_occurred` (`customer_id`,`occurred_at`),
  KEY `ix_interactions_contact_id` (`contact_id`),
  CONSTRAINT `interactions_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`),
  CONSTRAINT `interactions_ibfk_2` FOREIGN KEY (`contact_id`) REFERENCES `contacts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `interactions`
--

LOCK TABLES `interactions` WRITE;
/*!40000 ALTER TABLE `interactions` DISABLE KEYS */;
INSERT INTO `interactions` (`id`, `customer_id`, `contact_id`, `type`, `occurred_at`, `notes`) VALUES ('INT-001','CUS-001','CON-001','call','2026-04-08','Intro call. Maya is opening a second operatory in Q3 and wants a full supplies + small-equipment package. Budget is real; she asked for a written proposal.'),('INT-002','CUS-001','CON-002','email','2026-05-19','Sent catalog and ballpark pricing. Luis confirmed they are comparing us against their current Patterson-style distributor.'),('INT-003','CUS-001','CON-001','meeting','2026-07-12','On-site walkthrough. Presented a $48k annual proposal covering chairside kits; Maya said it looked \'very close\' and she would review with her CPA that week.'),('INT-004','CUS-001','CON-002','email','2026-07-18','Follow-up: Luis said Maya is still interested but went quiet. No reply to two later check-ins. This deal is stalled right after proposal.'),('INT-005','CUS-002','CON-003','meeting','2025-09-16','Quarterly business review. Hannah is happy with pediatric kit quality. No open issues. Asked us not to over-contact.'),('INT-006','CUS-002','CON-004','email','2025-12-04','Priya confirmed auto-replenish is working. \'Please keep the cadence; we do not need a sales visit.\''),('INT-007','CUS-002','CON-003','note','2026-03-02','Internal note: Harbor is a stable happy account. Silence here is healthy; last NPS-style comment was \'everything running smoothly.\''),('INT-008','CUS-003','CON-005','call','2026-07-22','Eli just bought the practice from a retiring dentist. Needs to replace aging sterilizer workflow and standardise supplies.'),('INT-009','CUS-003','CON-006','email','2026-08-14','Jordan requested a 90-day starter bundle quote and asked about financing. Very engaged.'),('INT-010','CUS-003','CON-005','meeting','2026-09-03','Working session on chair-side setup. Eli wants a revised quote by next week and a pilot order of impression materials. Active deal.'),('INT-011','CUS-004','CON-008','email','2026-07-09','Chris flagged a duplicate invoice from June. He sounded frustrated; said billing errors are \'getting old.\''),('INT-012','CUS-004','CON-007','call','2026-08-02','Sofia still likes the product mix but asked us to fix billing before they expand the aligner accessory order.'),('INT-013','CUS-004','CON-008','email','2026-08-22','Chris sent another reminder: credit memo still not applied. Relationship is strained over admin not clinical fit.'),('INT-014','CUS-005','CON-009','call','2026-05-20','Owen took a 12-minute intro call. Curious about implant restorative kits. Asked us to send a one-pager and said he would \'circle back after AAID.\''),('INT-015','CUS-005','CON-009','email','2026-06-01','Sent one-pager. No reply. No second touch scheduled. Early-stage and already going cold.'),('INT-016','CUS-006','CON-010','meeting','2026-04-11','Annual review. Lena renewed for another year. Interested in a slow rollout of digital impression accessories.'),('INT-017','CUS-006','CON-011','call','2026-09-01','Marcus called to confirm next auto-ship. No issues. Mentioned they referred a colleague at Pinecrest (not yet converted).'),('INT-018','CUS-007','CON-012','email','2026-06-18','Nina requested a demo of surgical irrigation and obturation supplies after a conference chat.'),('INT-019','CUS-007','CON-012','meeting','2026-08-15','Demo was on the calendar; Nina cancelled same morning (\'emergency retreatment day\') and asked to reschedule. We never locked a new date.'),('INT-020','CUS-008','CON-013','call','2026-06-20','Andre wants to outfit a third OR. Asked about volume pricing and loaner handpieces during the build-out.'),('INT-021','CUS-008','CON-014','meeting','2026-08-28','Kim walked through construction timeline (rooms ready late October). They need a written expansion quote and a staging plan. Warm and time-bound.'),('INT-022','CUS-009','CON-015','meeting','2026-08-08','Multi-location group. Rachel wants one vendor across three offices. Competitive RFP.'),('INT-023','CUS-009','CON-016','email','2026-08-30','Sent the consolidated proposal ($112k). Tom said partners review it in the first September ops meeting. Waiting; not ghosted yet.'),('INT-024','CUS-010','CON-017','note','2025-08-12','Amira sent a handwritten thank-you after we rushed a backorder. Called us \'the only vendor I trust.\''),('INT-025','CUS-010','CON-017','email','2026-01-20','Referred two nearby GPs. Explicitly said she does not need outreach; \'just keep doing what you are doing.\''),('INT-026','CUS-011','CON-018','meeting','2026-04-09','On-site demo of perio surgical kits. Peter was enthusiastic and asked for a sample pack.'),('INT-027','CUS-011','CON-018','email','2026-05-10','Samples delivered. Two follow-up emails unanswered. Phone goes to voicemail. Ghosted after a strong demo.'),('INT-028','CUS-012','CON-020','call','2026-07-18','Sam said deliveries keep missing the Wednesday restock window and hygienists are running short on prophy paste.'),('INT-029','CUS-012','CON-019','email','2026-08-25','Claire is otherwise happy with quality but asked us to \'fix logistics or we will have to look around.\' Scheduling/delivery friction; saveable.');
/*!40000 ALTER TABLE `interactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ai_insights`
--

DROP TABLE IF EXISTS `ai_insights`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ai_insights` (
  `customer_id` varchar(20) NOT NULL,
  `summary` text,
  `next_action` text,
  `priority_score` int DEFAULT NULL,
  `priority_reason` text,
  `generated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`customer_id`),
  KEY `ix_ai_insights_priority_score` (`priority_score`),
  CONSTRAINT `ai_insights_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ai_insights`
--

LOCK TABLES `ai_insights` WRITE;
/*!40000 ALTER TABLE `ai_insights` DISABLE KEYS */;
INSERT INTO `ai_insights` (`customer_id`, `summary`, `next_action`, `priority_score`, `priority_reason`, `generated_at`) VALUES ('CUS-001','The deal with Dr. Maya Patel is currently stalled after a proposal was presented, with no recent communication following her initial interest. Despite a promising on-site walkthrough and a positive response to the proposal, subsequent follow-ups have gone unanswered.','{\"action\": \"send a follow-up email to Dr. Maya Patel\", \"drafted_message\": \"Subject: Following Up on Our Proposal\\n\\nHi Dr. Patel,\\n\\nI hope this message finds you well! I wanted to follow up regarding the proposal I sent over for the chairside kits. I understand you were planning to review it with your CPA, and I\\u2019m here to answer any questions or provide further information you might need.\\n\\nPlease let me know if you\\u2019d like to discuss this further or if there\\u2019s a good time for us to connect.\\n\\nLooking forward to hearing from you!\\n\\nBest regards,\\nLuis Ortega\"}',74,'Prospect went cold after proposal; urgent follow-up needed.','2026-09-07 15:30:20'),('CUS-002','The account with Dr. Hannah Cho is currently stable and positive, with no open issues reported. Recent interactions indicate satisfaction with product quality and a preference for minimal contact.','{\"action\": \"send a quarterly check-in email to maintain relationship\", \"drafted_message\": \"Subject: Quick Check-In\\n\\nHi Dr. Cho,\\n\\nI hope this message finds you well! I just wanted to take a moment to check in and ensure everything is still running smoothly with your current supplies. If there\'s anything you need or any feedback you\'d like to share, please feel free to reach out. \\n\\nThank you for your continued partnership!\\n\\nBest regards,\\nPriya Shah\"}',52,'Customer is stable and satisfied with no current issues.','2026-09-07 15:35:57'),('CUS-003',NULL,NULL,4,'Last contact 4 days ago.','2026-09-07 15:24:43'),('CUS-004',NULL,NULL,18,'Last contact 16 days ago.','2026-09-07 15:24:42'),('CUS-005','Dr. Owen Brooks initially showed interest during a 12-minute call regarding implant restorative kits, but has not responded to the one-pager sent on June 1, 2026. The interaction is currently in an early stage and appears to be going cold, with no follow-up scheduled.','{\"action\": \"schedule a follow-up call\", \"drafted_message\": \"Subject: Quick Follow-Up on Implant Restorative Kits\\n\\nHi Dr. Brooks,\\n\\nI hope this message finds you well! I wanted to follow up regarding the one-pager I sent on June 1 about our implant restorative kits. I understand you were busy with AAID, but I would love to hear your thoughts and see if you have any questions.\\n\\nWould you be available for a quick call this week to discuss?\\n\\nBest regards,\\n[Your Name]\"}',91,'Prospect went cold after initial interest; needs immediate follow-up.','2026-09-07 15:32:25'),('CUS-006','As of September 2026, Marcus Lee confirmed the next auto-ship with no issues and referred a colleague at Pinecrest, which presents a potential new opportunity. Dr. Lena Hart has renewed her contract and expressed interest in gradually introducing digital impression accessories.','{\"action\": \"follow up with the referral\", \"drafted_message\": \"Hi Marcus,\\n\\nThank you for confirming the next auto-ship! I appreciate your referral to your colleague at Pinecrest. Would you be able to provide their contact information so I can reach out?\\n\\nBest regards,\\n[Your Name]\"}',27,'Customer is healthy/quiet with no immediate issues.','2026-09-07 15:43:29'),('CUS-007',NULL,NULL,26,'Last contact 23 days ago.','2026-09-07 15:24:43'),('CUS-008',NULL,NULL,11,'Last contact 10 days ago.','2026-09-07 15:24:46'),('CUS-009',NULL,NULL,9,'Last contact 8 days ago.','2026-09-07 15:24:43'),('CUS-010','Dr. Amira Hassan has expressed strong satisfaction with our services, referring two nearby general practitioners and indicating no need for further outreach. Her handwritten thank-you note highlights her trust in our company, reinforcing a positive relationship.','{\"action\": \"send a thank-you note\", \"drafted_message\": \"Subject: Thank You, Dr. Hassan!\\n\\nDear Dr. Hassan,\\n\\nI just wanted to take a moment to express our gratitude for your continued trust in our services and for referring your colleagues. Your support means a lot to us, and we are committed to maintaining the high standards that earned your confidence.\\n\\nThank you once again for being such a valued partner!\\n\\nBest regards,\\n[Your Name]\"}',58,'Customer is satisfied and has explicitly requested no outreach.','2026-09-07 15:48:08'),('CUS-011','Dr. Peter Lang initially showed strong interest during an on-site demo of perio surgical kits and requested a sample pack. However, subsequent follow-up emails have gone unanswered, and attempts to reach him by phone have also been unsuccessful, indicating a lack of engagement after the initial interaction.','{\"action\": \"send a follow-up email with a new offer\", \"drafted_message\": \"Subject: Following Up on Your Interest in Perio Surgical Kits\\n\\nHi Dr. Lang,\\n\\nI hope this message finds you well! I wanted to follow up regarding the sample pack of perio surgical kits we sent. I understand that things can get busy, but I\\u2019d love to hear your thoughts on the samples and see if there\\u2019s anything else I can assist you with.\\n\\nAs a token of appreciation for your interest, I\\u2019d like to offer you a 10% discount on your first order if you decide to move forward. Please let me know if you have any questions or if there\\u2019s a convenient time for us to chat.\\n\\nLooking forward to hearing from you!\\n\\nBest regards,\\n\\n[Your Name]  \\n[Your Position]  \\n[Your Company]  \\n[Your Contact Information]\"}',91,'Prospect went cold after a strong demo and multiple unanswered follow-ups.','2026-09-07 15:31:10'),('CUS-012',NULL,NULL,14,'Last contact 13 days ago.','2026-09-07 15:24:44');
/*!40000 ALTER TABLE `ai_insights` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `alembic_version`
--

DROP TABLE IF EXISTS `alembic_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alembic_version` (
  `version_num` varchar(32) NOT NULL,
  PRIMARY KEY (`version_num`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alembic_version`
--

LOCK TABLES `alembic_version` WRITE;
/*!40000 ALTER TABLE `alembic_version` DISABLE KEYS */;
INSERT INTO `alembic_version` (`version_num`) VALUES ('002_scale_indexes');
/*!40000 ALTER TABLE `alembic_version` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-07 16:02:31
