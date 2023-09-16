--
-- SQL Schema for Turingwatch prototype
--

DROP TABLE IF EXISTS sent_messages;
DROP TABLE IF EXISTS received_messages;
DROP TABLE IF EXISTS threads;
DROP TABLE IF EXISTS personas;
DROP TABLE IF EXISTS prompts;

CREATE TABLE `personas` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `email_address` varchar(255) NOT NULL,
  `first_name` varchar(255) NOT NULL default 'Janet',
  `last_name` varchar(255) NOT NULL default 'Smith',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Personas used to respond to scam emails`';

CREATE TABLE `threads` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `persona_id` int(10) unsigned NOT NULL,
  `scammer_address` varchar(10) NOT NULL,
  CONSTRAINT `threads_fk_1` FOREIGN KEY (`persona_id`) REFERENCES `personas` (`id`) ON DELETE CASCADE,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Message threads between personas and scammers';

CREATE TABLE `received_messages` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `thread_id` int(10) unsigned NOT NULL,
  `subject` varchar(512) NOT NULL,
  `body` text NOT NULL,
  CONSTRAINT `received_messages_fk_1` FOREIGN KEY (`thread_id`) REFERENCES `threads` (`id`),
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Messages received from scammers';

CREATE TABLE `prompts` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `prompt_text` text NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Different prompts used by Turingwatch to generate Language Model responses';

CREATE TABLE `sent_messages` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `thread_id` int(10) unsigned NOT NULL,
  `prompt_id` int(10) unsigned NOT NULL,
  `subject` varchar(512) NOT NULL,
  `body` text NOT NULL,
  CONSTRAINT `sent_messages_fk_1` FOREIGN KEY (`thread_id`) REFERENCES `threads` (`id`) ON DELETE CASCADE,
  CONSTRAINT `sent_messages_fk_2` FOREIGN KEY (`prompt_id`) REFERENCES `prompts` (`id`) ON DELETE CASCADE,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Messages sent by Personas to scammers';

CREATE TABLE `extracted_credentials` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `message_id` int(10) unsigned NOT NULL,
  `category` ENUM('email', 'bank_account', 'other_payment', 'unknown', 'phone_number', 'other') NOT NULL DEFAULT 'unknown',
  `value` text NOT NULL,
  CONSTRAINT `extracted_credentials_fk_1` FOREIGN KEY (`message_id`) REFERENCES `received_messages` (`id`) ON DELETE CASCADE,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Credentials and scammer information extracted from conversations';

