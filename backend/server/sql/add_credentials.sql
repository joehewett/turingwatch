--
-- SQL Schema for Turingwatch prototype
--

CREATE TABLE `credentials` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `message_id` int(10) unsigned NOT NULL,
  `category` ENUM('email', 'bank_account', 'other_payment', 'unknown', 'phone_number', 'other') NOT NULL DEFAULT 'unknown',
  `value` text NOT NULL,
  CONSTRAINT `extracted_credentials_fk_1` FOREIGN KEY (`message_id`) REFERENCES `received_messages` (`id`) ON DELETE CASCADE,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Credentials and scammer information extracted from conversations';

