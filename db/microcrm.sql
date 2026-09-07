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
INSERT INTO `customers` (`id`, `name`, `status`, `created_at`) VALUES ('cust_001','Northstar Dental Group','prospect','2026-05-12'),('cust_002','Greenfield Pediatrics','customer','2025-11-03'),('cust_003','Riverbend Orthodontics','prospect','2026-07-18'),('cust_004','Oak & Pine Family Dental','customer','2025-08-21'),('cust_005','BrightSmile Dental','prospect','2026-08-05'),('cust_006','Sunrise Pediatric Dentistry','customer','2026-01-14'),('cust_007','Lakeside Dental Care','prospect','2026-06-22'),('cust_008','Maple Grove Orthodontics','customer','2025-12-09'),('cust_009','Parkview Dental Studio','prospect','2026-08-17'),('cust_010','Willow Creek Dental','customer','2025-09-30'),('cust_011','Evergreen Dental Partners','prospect','2026-07-02'),('cust_012','Central Avenue Dentistry','prospect','2026-08-24');
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
INSERT INTO `contacts` (`id`, `customer_id`, `name`, `email`, `role`) VALUES ('contact_001','cust_001','Sarah Mitchell','sarah@northstardental.example','Owner'),('contact_002','cust_001','Daniel Kim','daniel@northstardental.example','Office Manager'),('contact_003','cust_002','Emily Carter','emily@greenfieldpediatrics.example','Practice Manager'),('contact_004','cust_003','Jason Lee','jason@riverbendortho.example','Owner'),('contact_005','cust_004','Megan Brooks','megan@oakpinedental.example','Office Manager'),('contact_006','cust_005','Rachel Adams','rachel@brightsmile.example','Owner'),('contact_007','cust_006','Olivia Turner','olivia@sunrisepediatric.example','Practice Administrator'),('contact_008','cust_007','Michael Grant','michael@lakesidedental.example','Owner'),('contact_009','cust_008','Natalie Young','natalie@maplegroveortho.example','Office Manager'),('contact_010','cust_009','Chris Evans','chris@parkviewdental.example','Dentist'),('contact_011','cust_010','Amanda Foster','amanda@willowcreekdental.example','Practice Manager'),('contact_012','cust_011','Brian Chen','brian@evergreendental.example','Owner'),('contact_013','cust_011','Laura Stone','laura@evergreendental.example','Operations Manager'),('contact_014','cust_012','Kevin Patel','kevin@centralavenuedentistry.example','Owner'),('contact_015','cust_012','Julia Morris','julia@centralavenuedentistry.example','Front Desk Manager');
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
INSERT INTO `interactions` (`id`, `customer_id`, `contact_id`, `type`, `occurred_at`, `notes`) VALUES ('int_001','cust_001','contact_001','email','2026-08-18','Sarah asked for pricing and wanted to understand whether the product can handle after-hours calls.'),('int_002','cust_001','contact_002','call','2026-08-20','Daniel explained they receive around 60 missed calls per week and currently use voicemail after 5 PM.'),('int_003','cust_001','contact_001','meeting','2026-08-22','Demo went well. Sarah liked appointment booking and call summaries. She asked for a proposal for 3 locations.'),('int_004','cust_001','contact_001','email','2026-08-23','Sent proposal. Sarah said she would review it with her partners early next week.'),('int_005','cust_001','contact_001','note','2026-08-29','No response yet after proposal. Follow-up may be appropriate.'),('int_006','cust_002','contact_003','call','2026-06-10','Emily said the team is generally happy but occasionally sees incorrect appointment reasons in summaries.'),('int_007','cust_002','contact_003','email','2026-06-11','Sent instructions for reporting summary issues.'),('int_008','cust_002','contact_003','email','2026-07-03','Emily confirmed the summary quality has improved.'),('int_009','cust_002','contact_003','meeting','2026-08-26','Quarterly check-in. Emily asked whether SMS support is planned because patients increasingly text the office.'),('int_010','cust_003','contact_004','email','2026-07-18','Jason responded to an outbound email and asked for more information.'),('int_011','cust_003','contact_004','call','2026-07-21','Jason is opening a second location in October. Interested in reducing front desk workload.'),('int_012','cust_003','contact_004','email','2026-07-22','Sent demo scheduling link.'),('int_013','cust_003','contact_004','note','2026-08-05','Jason never scheduled the demo. No follow-up has been sent since July.'),('int_014','cust_004','contact_005','email','2026-05-14','Megan reported that patients sometimes hang up when there is a longer response delay.'),('int_015','cust_004','contact_005','call','2026-05-15','Explained upcoming latency improvements. Megan said the issue was not urgent.'),('int_016','cust_004','contact_005','email','2026-06-02','Checked in after latency update. Megan said things seem better.'),('int_017','cust_004','contact_005','note','2026-06-02','No additional follow-up required unless issue returns.'),('int_018','cust_005','contact_006','email','2026-08-05','Rachel asked whether the system integrates with Dentrix.'),('int_019','cust_005','contact_006','call','2026-08-07','Rachel currently has two receptionists but struggles during lunch and peak hours.'),('int_020','cust_005','contact_006','meeting','2026-08-11','Demo completed. Rachel was interested but concerned about changing workflows.'),('int_021','cust_005','contact_006','email','2026-08-12','Rachel asked for a customer reference who also uses Dentrix.'),('int_022','cust_005','contact_006','email','2026-08-13','Sent customer reference and case study.'),('int_023','cust_005','contact_006','email','2026-08-25','Rachel thanked us for the information and said she expects to make a decision in September.'),('int_024','cust_006','contact_007','meeting','2026-04-09','Olivia said call volume has increased significantly since adding another provider.'),('int_025','cust_006','contact_007','email','2026-04-10','Shared instructions for adding another scheduling provider.'),('int_026','cust_006','contact_007','call','2026-08-28','Olivia mentioned they are considering opening another office next year and may need a second account.'),('int_027','cust_007','contact_008','call','2026-06-23','Michael was interested in AI answering but worried patients would dislike talking to an AI.'),('int_028','cust_007','contact_008','email','2026-06-24','Sent sample call recordings.'),('int_029','cust_007','contact_008','email','2026-06-27','Michael said the calls sounded better than expected and asked about pricing.'),('int_030','cust_007','contact_008','email','2026-06-28','Sent pricing details.'),('int_031','cust_007','contact_008','note','2026-08-01','No response after pricing. Prospect has been inactive for over a month.'),('int_032','cust_008','contact_009','email','2026-07-07','Natalie asked whether the system can recognize Spanish-speaking patients.'),('int_033','cust_008','contact_009','call','2026-07-08','Discussed multilingual support. Roughly 20% of their patients prefer Spanish.'),('int_034','cust_008','contact_009','email','2026-07-10','Sent configuration options for Spanish.'),('int_035','cust_008','contact_009','email','2026-07-20','Natalie confirmed they enabled Spanish and early feedback is positive.'),('int_036','cust_009','contact_010','email','2026-08-17','Chris requested a demo after seeing the product recommended in a dental owner group.'),('int_037','cust_009','contact_010','meeting','2026-08-19','Demo completed. Chris was especially interested in handling new-patient calls.'),('int_038','cust_009','contact_010','email','2026-08-19','Sent pricing after demo.'),('int_039','cust_009','contact_010','email','2026-08-20','Chris replied that pricing looks reasonable and asked whether onboarding can be completed before September 15.'),('int_040','cust_009','contact_010','note','2026-08-20','Need to confirm onboarding timeline. High-intent prospect.'),('int_041','cust_010','contact_011','call','2026-03-16','Amanda said the system has reduced missed calls noticeably.'),('int_042','cust_010','contact_011','email','2026-03-18','Amanda asked if call analytics could be included in a monthly report.'),('int_043','cust_010','contact_011','email','2026-04-01','Shared current reporting options.'),('int_044','cust_010','contact_011','note','2026-04-01','Customer appears satisfied. No recent engagement.'),('int_045','cust_011','contact_012','email','2026-07-02','Brian asked about support for a five-location dental group.'),('int_046','cust_011','contact_013','call','2026-07-05','Laura handles operations. She said centralized reporting and location-level configuration are important.'),('int_047','cust_011','contact_013','meeting','2026-07-09','Demo with Laura. She liked reporting but needs approval from Brian.'),('int_048','cust_011','contact_012','email','2026-07-10','Sent enterprise pricing to Brian.'),('int_049','cust_011','contact_013','call','2026-08-14','Laura said Brian is still interested but budgeting has been delayed until their September planning meeting.'),('int_050','cust_011','contact_013','note','2026-08-14','Do not push aggressively before September planning meeting.'),('int_051','cust_012','contact_014','email','2026-08-24','Kevin filled out the contact form asking for pricing.'),('int_052','cust_012','contact_015','call','2026-08-25','Julia said they miss calls during lunch and when both front desk staff are helping patients.'),('int_053','cust_012','contact_015','email','2026-08-25','Julia requested a demo for Kevin.'),('int_054','cust_012','contact_014','meeting','2026-08-27','Demo completed with Kevin and Julia. Kevin asked about contract length and cancellation terms.'),('int_055','cust_012','contact_014','email','2026-08-27','Sent contract details.'),('int_056','cust_012','contact_015','email','2026-08-31','Julia asked if we can schedule a short follow-up this week to discuss implementation.');
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
INSERT INTO `ai_insights` (`customer_id`, `summary`, `next_action`, `priority_score`, `priority_reason`, `generated_at`) VALUES ('cust_001','As of now, Sarah Mitchell has not responded to the proposal sent on August 23, and a follow-up may be necessary. The demo was well-received, particularly the appointment booking and call summaries features, and Sarah expressed interest in a proposal for three locations.','{\"action\": \"send a follow-up email to Sarah Mitchell\", \"drafted_message\": \"Subject: Follow-Up on Proposal\\n\\nHi Sarah,\\n\\nI hope this message finds you well. I wanted to follow up regarding the proposal I sent on August 23 for the three locations. If you have had a chance to discuss it with your partners, I would love to hear your thoughts or answer any questions you might have.\\n\\nLooking forward to your response!\\n\\nBest regards,\\nDaniel Kim\"}',66,'Prospect went cold after proposal; follow-up is appropriate.','2026-09-07 16:19:28'),('cust_002','The latest interaction with Emily Carter indicates a quarterly check-in where she inquired about the potential for SMS support, reflecting a growing trend in patient communication. Previous communications confirm improvements in summary quality, although there are still occasional issues with incorrect appointment reasons.','{\"action\": \"research SMS support options\", \"drafted_message\": null}',26,'Customer is satisfied but has been quiet for months, indicating a healthy/quiet status.','2026-09-07 16:19:13'),('cust_003','Jason Lee has shown interest in our product, particularly for his new dental practice location opening in October. However, he has not scheduled a demo yet, and there has been no follow-up since July.','{\"action\": \"send a gentle reminder email to schedule a demo\", \"drafted_message\": \"Subject: Quick Reminder: Schedule Your Demo\\n\\nHi Jason,\\n\\nI hope this message finds you well! I wanted to follow up regarding the demo for our AI answering and scheduling solution. I know you\'re busy preparing for your new dental practice location opening in October, and I believe our solution could really help reduce your front desk workload.\\n\\nIf you\'re still interested, here\\u2019s the link to schedule a demo at your convenience: [insert demo scheduling link].\\n\\nLooking forward to hearing from you!\\n\\nBest,\\n[Your Name]\"}',66,'Prospect went cold after demo proposal; needs follow-up to re-engage.','2026-09-07 16:19:44'),('cust_004','Megan Brooks has reported improvements in latency issues after a recent update, indicating that the situation seems to be better. No further follow-up is required unless the issue resurfaces.','{\"action\": \"no action needed\", \"drafted_message\": null}',48,'Customer is satisfied and no follow-up is required unless issues return.','2026-09-07 16:19:33'),('cust_005','Rachel Adams is currently evaluating our AI phone and scheduling product for her dental practice, having completed a demo and requested customer references. She has expressed interest but is concerned about potential workflow changes and expects to make a decision in September.','{\"action\": \"wait for Rachel\'s decision in September\", \"drafted_message\": null}',67,'High-intent prospect with an upcoming decision deadline.','2026-09-07 16:18:58'),('cust_006','Olivia Turner has indicated that their dental practice is experiencing increased call volume due to the addition of another scheduling provider. They are also contemplating the opening of a second office next year, which may lead to the need for an additional account.','{\"action\": \"schedule a follow-up call to discuss their needs for the second office and account\", \"drafted_message\": \"Hi Olivia, I hope you\'re doing well! I wanted to follow up on our previous discussions regarding your increased call volume and the potential for a second office. Would you be available for a quick call next week to explore how we can support your needs? Let me know what works for you!\"}',25,'Customer is satisfied and considering expansion, but no urgent follow-up needed.','2026-09-07 16:19:49'),('cust_007','Michael Grant has shown initial interest in the AI phone product, expressing concerns about patient reception to AI interactions. However, after receiving pricing details over a month ago, he has not responded, indicating a potential stall in the sales process.','{\"action\": \"one concrete next step\", \"drafted_message\": null}',66,'Prospect went cold after pricing and has been inactive for over a month.','2026-09-07 16:19:18'),('cust_008','Natalie Young has confirmed that the Spanish language feature has been enabled and early feedback from users is positive. Prior discussions indicated that approximately 20% of their patients prefer Spanish, leading to the configuration options being sent for this multilingual support.','{\"action\": \"monitor feedback and performance of the Spanish feature\", \"drafted_message\": null}',36,'Customer is satisfied and has been quiet for months.','2026-09-07 16:19:22'),('cust_009','Chris Evans is a high-intent prospect who has shown strong interest in the product after a demo, particularly in managing new-patient calls. He has requested confirmation on the onboarding timeline, aiming for completion before September 15, and has found the pricing reasonable.','{\"action\": \"confirm onboarding timeline\", \"drafted_message\": \"Hi Chris,\\n\\nThank you for your interest in our AI answering and scheduling solution! I wanted to confirm that we can complete the onboarding process before September 15. Please let me know if you have any other questions or if there\'s anything else I can assist you with.\\n\\nBest regards,\\n[Your Name]\"}',69,'High-intent prospect with an onboarding deadline approaching.','2026-09-07 16:19:38'),('cust_010','Amanda Foster, the customer, seems satisfied with the product, noting a reduction in missed calls. However, there has been little recent engagement, with the last interaction being a note on April 1, 2026.','{\"action\": \"send a check-in email to maintain engagement\", \"drafted_message\": \"Subject: Checking In\\n\\nHi Amanda,\\n\\nI hope this message finds you well! I wanted to check in and see how everything is going with the AI answering and scheduling system. If you have any questions or need assistance, feel free to reach out.\\n\\nBest regards,\\n[Your Name]\"}',48,'Customer is satisfied but has had no recent engagement.','2026-09-07 16:19:54'),('cust_011','Currently, Brian Chen is interested in the AI phone and scheduling product, but budgeting decisions are pending until their September planning meeting. Laura Stone has expressed the need for centralized reporting and location-level configuration, and she is awaiting approval from Brian after a positive demo.','{\"action\": \"wait until after September planning meeting\", \"drafted_message\": null}',29,'Healthy/quiet; no follow-up required until after September planning meeting.','2026-09-07 16:19:07'),('cust_012','The sales process is progressing well with Julia and Kevin from the dental practice. A demo has been completed, and they are now discussing contract details and implementation, with a follow-up meeting scheduled for this week.','{\"action\": \"prepare for the follow-up meeting\", \"drafted_message\": \"Hi Julia,\\n\\nLooking forward to our follow-up meeting this week to discuss the implementation details. Please let me know if there\'s anything specific you would like to cover.\\n\\nBest,\\n[Your Name]\"}',66,'High-intent prospect with an onboarding deadline after recent contact.','2026-09-07 16:19:03');
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

-- Dump completed on 2026-09-07 16:20:12
