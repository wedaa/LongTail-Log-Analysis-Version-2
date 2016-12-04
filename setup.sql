#
# Run this script to setup the LongTail databases in MySQL
# 
# Written by:   Eric Wedaa
# Created:      2016-12-04
# Last updated: 2016-12-04
#
# Database definition from the "What Lies Beneath" database
# from http://www.netsec.ethz.ch/publications/papers/passwords15-abdou.pdf
#
# Copyright 2016 by Eric Wedaa and by Marist College
#
create database longtail;
use longtail;

CREATE TABLE `attacks` (
  `idx` int(50) NOT NULL AUTO_INCREMENT,
  `honeypot` varchar(20) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `time` time DEFAULT NULL,
  `id` varchar(10) DEFAULT NULL,
  `username` varchar(100) DEFAULT NULL,
  `password` varchar(100) DEFAULT NULL,
  `src_ip` varchar(15) DEFAULT NULL,
  `src_port` varchar(6) DEFAULT NULL,
  `src_as` varchar(20) DEFAULT NULL,
  `src_country` varchar(40) DEFAULT NULL,
  `src_city` varchar(40) DEFAULT NULL,
  `uniquehour` varchar(25) DEFAULT NULL,
  PRIMARY KEY (`idx`)
) ENGINE=MyISAM AUTO_INCREMENT=17217677 DEFAULT CHARSET=latin1;

create database whois;
use whois;
create table ip_to_country ( ip varchar(15) DEFAULT NULL, src_country_code varchar(2) DEFAULT NULL, PRIMARY KEY (ip));


create user 'longtail'@'localhost' IDENTIFIED BY 'PASSWORD';
GRANT ALL PRIVILEGES ON longtail.* TO 'longtail'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON whois.* TO 'longtail'@'localhost' WITH GRANT OPTION;

