BEGIN TRANSACTION;
CREATE TABLE account (
	sf_id VARCHAR(255) NOT NULL, 
	name VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "account" VALUES('0011k00000QIzaAAAT','Harrison Household');
INSERT INTO "account" VALUES('0011k00000QIza5AAD','van Hoop Household');
INSERT INTO "account" VALUES('0011k00000QJ0iNAAT','Regenstein Household');
INSERT INTO "account" VALUES('0011k00000QIzZvAAL','Mendoza Household');
INSERT INTO "account" VALUES('0011k00000QIzaFAAT','Fernandez Household');
CREATE TABLE campaign (
	sf_id VARCHAR(255) NOT NULL, 
	isactive VARCHAR(255), 
	name VARCHAR(255), 
	status VARCHAR(255), 
	startdate VARCHAR(255), 
	enddate VARCHAR(255), 
	volunteer_website_time_zone VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "campaign" VALUES('7011k000000gzcYAAQ','true','Dog Care at The Place for Pets','Planned','','','');
INSERT INTO "campaign" VALUES('7011k000000gz5hAAA','true','GC Product Webinar - Jan 7, 2002','Completed','2018-12-25','2018-12-25','');
INSERT INTO "campaign" VALUES('7011k000000gz5iAAA','true','User Conference - Jun 17-19, 2002','Planned','2019-06-04','2019-06-06','');
INSERT INTO "campaign" VALUES('7011k000000gz5jAAA','true','DM Campaign to Top Customers - Nov 12-23, 2001','Completed','2018-10-30','2018-11-10','');
INSERT INTO "campaign" VALUES('7011k000000gz5kAAA','true','International Electrical Engineers Association Trade Show - Mar 4-5, 2002','Planned','2019-02-19','2019-02-20','');
INSERT INTO "campaign" VALUES('7011k000000gzcnAAA','true','2nd Annual Aziz''s Chili Cookoff','Planned','2019-08-24','2019-08-24','');
CREATE TABLE contact (
	sf_id VARCHAR(255) NOT NULL, 
	firstname VARCHAR(255), 
	lastname VARCHAR(255), 
	email VARCHAR(255), 
	volunteer_auto_reminder_email_opt_out VARCHAR(255), 
	volunteer_availability VARCHAR(255), 
	volunteer_last_web_signup_date VARCHAR(255), 
	volunteer_manager_notes VARCHAR(255), 
	volunteer_notes VARCHAR(255), 
	volunteer_organization VARCHAR(255), 
	volunteer_skills VARCHAR(255), 
	volunteer_status VARCHAR(255), 
	account_id VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "contact" VALUES('0031k00000MPhYGAA1','Catherine','Harrison','catherine@example.com','false','','','','','','','Active','0011k00000QIzaAAAT');
INSERT INTO "contact" VALUES('0031k00000MPhY1AAL','Elizabeth','Mendoza','elizabeth@example.com','false','','','','','','','Active','0011k00000QIzZvAAL');
INSERT INTO "contact" VALUES('0031k00000MPhY6AAL','Jacob','van Hoop','jacob@example.com','false','','','','','','','Active','0011k00000QIza5AAD');
INSERT INTO "contact" VALUES('0031k00000MPhYBAA1','Tamara','Harrison','tamara@example.com','false','','','','','','Fundraising;Event Planning','Active','0011k00000QIzaAAAT');
INSERT INTO "contact" VALUES('0031k00000MPixMAAT','Aziz','Regenstein','aziz@example.com','false','','','','','','','Active','0011k00000QJ0iNAAT');
INSERT INTO "contact" VALUES('0031k00000MPhYQAA1','Hiroko','Fernandez','hiroko@example.com','false','','','','','','','Active','0011k00000QIzaFAAT');
INSERT INTO "contact" VALUES('0031k00000MPhYLAA1','Michael','Fernandez','michael@example.com','false','','','','','','','Active','0011k00000QIzaFAAT');
CREATE TABLE job_recurrence_schedule__c (
	sf_id VARCHAR(255) NOT NULL, 
	days_of_week VARCHAR(255), 
	description VARCHAR(255), 
	desired_number_of_volunteers VARCHAR(255), 
	duration VARCHAR(255), 
	schedule_end_date VARCHAR(255), 
	schedule_start_date_time VARCHAR(255), 
	weekly_occurrence VARCHAR(255), 
	volunteer_job__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "job_recurrence_schedule__c" VALUES('a001k000002B1jLAAS','Monday;Tuesday;Wednesday;Thursday;Friday','Take the puppers of The Place for Pets for a midday walk!','5.0','1.0','2020-07-31','2019-07-17T19:00:00.000Z','Every','a031k000001OMGqAAO');
INSERT INTO "job_recurrence_schedule__c" VALUES('a001k000002B1jQAAS','Saturday','Keep the kennels of The Place for Pets clean and cozy for our adoptable dogs!','10.0','2.0','2020-08-01','2019-07-06T15:00:00.000Z','Every','a031k000001OMGrAAO');
CREATE TABLE volunteer_hours__c (
	sf_id VARCHAR(255) NOT NULL, 
	comments VARCHAR(255), 
	end_date VARCHAR(255), 
	hours_worked VARCHAR(255), 
	number_of_volunteers VARCHAR(255), 
	planned_start_date_time VARCHAR(255), 
	start_date VARCHAR(255), 
	status VARCHAR(255), 
	system_note VARCHAR(255), 
	contact__c VARCHAR(255), 
	volunteer_job__c VARCHAR(255), 
	volunteer_recurrence_schedule__c VARCHAR(255), 
	volunteer_shift__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "volunteer_hours__c" VALUES('a021k000002YotkAAC','','2019-08-24','2.0','1.0','2019-08-24T17:00:00.000Z','2019-08-24','Confirmed','','0031k00000MPhYQAA1','a031k000001OMHFAA4','','a051k000001HaSVAA0');
INSERT INTO "volunteer_hours__c" VALUES('a021k000002YotlAAC','','2019-08-24','2.0','1.0','2019-08-24T17:00:00.000Z','2019-08-24','Confirmed','','0031k00000MPhY6AAL','a031k000001OMHFAA4','','a051k000001HaSVAA0');
INSERT INTO "volunteer_hours__c" VALUES('a021k000002YotmAAC','','2019-08-24','2.0','1.0','2019-08-24T17:00:00.000Z','2019-08-24','Confirmed','','0031k00000MPhYLAA1','a031k000001OMHFAA4','','a051k000001HaSVAA0');
INSERT INTO "volunteer_hours__c" VALUES('a021k000002YostAAC','','2019-08-24','5.0','1.0','2019-08-24T19:00:00.000Z','2019-08-24','Confirmed','','0031k00000MPixMAAT','a031k000001OMHAAA4','','a051k000001HaSkAAK');
CREATE TABLE volunteer_job__c (
	sf_id VARCHAR(255) NOT NULL, 
	description VARCHAR(255), 
	display_on_website VARCHAR(255), 
	external_signup_url VARCHAR(255), 
	inactive VARCHAR(255), 
	location_city VARCHAR(255), 
	location_information VARCHAR(255), 
	location_street VARCHAR(255), 
	location_zip_postal_code VARCHAR(255), 
	location VARCHAR(255), 
	name VARCHAR(255), 
	ongoing VARCHAR(255), 
	skills_needed VARCHAR(255), 
	volunteer_website_time_zone VARCHAR(255), 
	campaign__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "volunteer_job__c" VALUES('a031k000001OMH5AAO','<p>Spread the word about the 2nd Annual Aziz&#39;s Chili Cookoff, and help us make this year&#39;s event our biggest and best yet!</p>','true','','false','','','','','','Distribute Flyers for the Chili Cookoff','false','Marketing','','7011k000000gzcnAAA');
INSERT INTO "volunteer_job__c" VALUES('a031k000001OMHAAA4','<p>Feed all the animal lovers at our 2nd Annual Aziz&#39;s Chili Cookoff, and get the chance to win chili glory!</p>','false','','false','','','','','','Chili Cooks','false','','','7011k000000gzcnAAA');
INSERT INTO "volunteer_job__c" VALUES('a031k000001OMHFAA4','<p>Help prepare for our chili cookoff and get free entry to the day!</p>','true','','false','','','','','','Setup Crew','false','Manual Labor','','7011k000000gzcnAAA');
INSERT INTO "volunteer_job__c" VALUES('a031k000001OMHPAA4','<p>Who made the best chili of the 2nd Annual Aziz&#39;s Chili Cookoff? You get to help us decide as one of our esteemed judges!</p>','false','','false','','','','','','Chili Judges','false','','','7011k000000gzcnAAA');
INSERT INTO "volunteer_job__c" VALUES('a031k000001OMHKAA4','<p>Enjoy fun treats while helping us break down after a rockin&#39; chili cookoff!</p>','true','','false','','','','','','Cleanup Crew','false','Manual Labor','','7011k000000gzcnAAA');
INSERT INTO "volunteer_job__c" VALUES('a031k000001OMGqAAO','<p>Take the puppers of The Place for Pets for a midday walk!</p>','true','','false','','','','','','Lunchtime Dog Walking','false','','','7011k000000gzcYAAQ');
INSERT INTO "volunteer_job__c" VALUES('a031k000001OMGrAAO','<p>Keep the kennels of The Place for Pets clean and cozy for our adoptable dogs!</p>','true','','false','','','','','','Weekly Kennel Cleaning','false','Manual Labor','','7011k000000gzcYAAQ');
INSERT INTO "volunteer_job__c" VALUES('a031k000001OMGsAAO','<p>Help us get our puppies ready for their new forever homes with socialization, snuggles, and positive reinforcement.</p>','false','','false','','','','','','Puppy Playtime','false','','','7011k000000gzcYAAQ');
INSERT INTO "volunteer_job__c" VALUES('a031k000001OMGtAAO','','true','','false','','','','','','Recruit Chili Cooks','false','','','7011k000000gzcnAAA');
INSERT INTO "volunteer_job__c" VALUES('a031k000001OMGuAAO','','true','','false','','','','','','Quality Entertainment','false','','','7011k000000gzcnAAA');
INSERT INTO "volunteer_job__c" VALUES('a031k000001OMGvAAO','','true','','false','','','','','','Foster Care for Small Dogs','false','','','7011k000000gzcYAAQ');
INSERT INTO "volunteer_job__c" VALUES('a031k000001OMGwAAO','','true','','false','','','','','','Foster Care for Large Dogs','false','','','7011k000000gzcYAAQ');

CREATE TABLE volunteer_recurrence_schedule__c (
	sf_id VARCHAR(255) NOT NULL, 
	comments VARCHAR(255), 
	days_of_week VARCHAR(255), 
	duration VARCHAR(255), 
	number_of_volunteers VARCHAR(255), 
	schedule_end_date VARCHAR(255), 
	schedule_start_date_time VARCHAR(255), 
	volunteer_hours_status VARCHAR(255), 
	weekly_occurrence VARCHAR(255), 
	contact__c VARCHAR(255), 
	volunteer_job__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
CREATE TABLE volunteer_shift__c (
	sf_id VARCHAR(255) NOT NULL, 
	description VARCHAR(255), 
	desired_number_of_volunteers VARCHAR(255), 
	duration VARCHAR(255), 
	start_date_time VARCHAR(255), 
	system_note VARCHAR(255), 
	total_volunteers VARCHAR(255), 
	job_recurrence_schedule__c VARCHAR(255), 
	volunteer_job__c VARCHAR(255), 
	PRIMARY KEY (sf_id)
);
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HZxyAAG','Help us get our puppies ready for their new forever homes with socialization, snuggles, and positive reinforcement.','3.0','1.0','2020-03-15T17:00:00.000Z','','','','a031k000001OMGsAAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HZxoAAG','Help us get our puppies ready for their new forever homes with socialization, snuggles, and positive reinforcement.','3.0','1.0','2019-12-15T18:00:00.000Z','','','','a031k000001OMGsAAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HaSfAAK','','5.0','2.0','2019-08-24T23:00:00.000Z','','','','a031k000001OMHPAA4');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HaSkAAK','','30.0','5.0','2019-08-24T19:00:00.000Z','','1.0','','a031k000001OMHAAA4');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HZxjAAG','Help us get our puppies ready for their new forever homes with socialization, snuggles, and positive reinforcement.','3.0','1.0','2019-10-20T17:00:00.000Z','','','','a031k000001OMGsAAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HaSBAA0','','4.0','1.0','2019-07-27T22:00:00.000Z','','','','a031k000001OMH5AAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HaS6AAK','','4.0','1.0','2019-07-20T22:00:00.000Z','','','','a031k000001OMH5AAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HZy8AAG','Help us get our puppies ready for their new forever homes with socialization, snuggles, and positive reinforcement.','3.0','1.0','2020-05-17T17:00:00.000Z','','','','a031k000001OMGsAAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HaSLAA0','','4.0','1.0','2019-08-03T22:00:00.000Z','','','','a031k000001OMH5AAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HaSMAA0','','4.0','1.0','2019-08-10T22:00:00.000Z','','','','a031k000001OMH5AAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HZxtAAG','Help us get our puppies ready for their new forever homes with socialization, snuggles, and positive reinforcement.','3.0','1.0','2020-02-16T18:00:00.000Z','','','','a031k000001OMGsAAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HZy3AAG','Help us get our puppies ready for their new forever homes with socialization, snuggles, and positive reinforcement.','3.0','1.0','2020-04-19T17:00:00.000Z','','','','a031k000001OMGsAAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HZxeAAG','Help us get our puppies ready for their new forever homes with socialization, snuggles, and positive reinforcement.','3.0','1.0','2019-09-15T17:00:00.000Z','','','','a031k000001OMGsAAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HZxfAAG','Help us get our puppies ready for their new forever homes with socialization, snuggles, and positive reinforcement.','3.0','1.0','2019-11-17T18:00:00.000Z','','','','a031k000001OMGsAAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HZxZAAW','Help us get our puppies ready for their new forever homes with socialization, snuggles, and positive reinforcement.','3.0','1.0','2019-08-18T17:00:00.000Z','','','','a031k000001OMGsAAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HZxaAAG','Help us get our puppies ready for their new forever homes with socialization, snuggles, and positive reinforcement.','3.0','1.0','2020-01-19T18:00:00.000Z','','','','a031k000001OMGsAAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HZxbAAG','Help us get our puppies ready for their new forever homes with socialization, snuggles, and positive reinforcement.','3.0','1.0','2020-06-21T17:00:00.000Z','','','','a031k000001OMGsAAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HZxcAAG','Help us get our puppies ready for their new forever homes with socialization, snuggles, and positive reinforcement.','3.0','1.0','2020-07-19T17:00:00.000Z','','','','a031k000001OMGsAAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HaSVAA0','','10.0','2.0','2019-08-24T17:00:00.000Z','','','','a031k000001OMHFAA4');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HZsCAAW','Help us get our puppies ready for their new forever homes with socialization, snuggles, and positive reinforcement.','3.0','1.0','2019-07-21T17:00:00.000Z','','','','a031k000001OMGsAAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HaSQAA0','','4.0','1.0','2019-08-17T22:00:00.000Z','','','','a031k000001OMH5AAO');
INSERT INTO "volunteer_shift__c" VALUES('a051k000001HaSaAAK','','12.0','2.0','2019-08-25T01:00:00.000Z','','','','a031k000001OMHKAA4');
COMMIT;
