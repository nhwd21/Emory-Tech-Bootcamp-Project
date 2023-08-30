# Part 2
# Objective 1

use MSBA_Team9;

# Combining tables
DROP TABLE if EXISTS reviews_raw;
CREATE TABLE reviews_raw AS
SELECT * FROM MSBA_DB1.reviews_kitchen
UNION ALL
SELECT * FROM MSBA_DB1.reviews_pet_products;

# Set review_ID for efficiency in later queries
ALTER TABLE reviews_raw
ADD PRIMARY KEY (review_id);

CREATE TABLE reviews_clean AS
SELECT * FROM reviews_raw;

-- 1: MISSING VALUES --------------------------------------------------------------------------
# Inital explpratory analysis to figure out what needs to be cleaned
DESCRIBE reviews_clean;

# Finding out how many values are missing from each column
SELECT COUNT(*)-COUNT(helpful_votes) As helpful_votes, COUNT(*)-COUNT(total_votes) As total_votes, 
COUNT(*)-COUNT(vine) As vine, COUNT(*)-COUNT(verified_purchase) As verified_purchase, 
COUNT(*)-COUNT(review_headline) As review_headline, COUNT(*)-COUNT(review_body) As review_body
FROM reviews_clean;

# Ensure our settings allow us to update our tables
SET SQL_SAFE_UPDATES = 0;

# Deleting review body where it is null
# we have over 7.5 million rows in our table
# so to lose ~450 that lack review bodies is insignificant

DELETE FROM reviews_clean
WHERE review_body is NULL;

# Figuring out what star ratings there are
SELECT DISTINCT star_rating FROM reviews_clean; -- (0-5)
SELECT review_headline, star_rating FROM reviews_clean WHERE star_rating IS NULL;

# If review headline is null, fill it with the corresponding star rating as text
# there are already many instances where the review headline corresponds with 
UPDATE reviews_clean
SET review_headline = CASE
    WHEN star_rating = 5 THEN 'Five Stars'
    WHEN star_rating = 4 THEN 'Four Stars'
    WHEN star_rating = 3 THEN 'Three Stars'
    WHEN star_rating = 2 THEN 'Two Stars'
    WHEN star_rating = 1 THEN 'One Star'
    ELSE review_headline
END
WHERE review_headline IS NULL;

# If the review date is 0000-00-00, we know it's the default value
# However, in all instances of the default date value, we found that the date was identified in the review body
# So, replace all values of the default date with the corresponding review body
UPDATE reviews_clean
SET review_date = review_body
WHERE review_date = '0000-00-00';

-- 2: DATA TYPES ------------------------------------------------------------------------------
# Figure out the datatypes, and how columns utilize them
DESCRIBE reviews_clean;
SELECT DISTINCT(vine) from MSBA_Team9.reviews_clean;
SELECT DISTINCT(verified_purchase) from MSBA_Team9.reviews_clean;

# We've identified the columns vine and verified_purchase to be booleans but they're formatted as integers
# create two new columns with the BOOLEAN (TinyINT) datatype
ALTER TABLE MSBA_Team9.reviews_clean
ADD vine_boolean BOOLEAN,
ADD verified_purchase_boolean BOOLEAN;

# Use the existing columns to fill our new columns
UPDATE MSBA_Team9.reviews_clean
SET vine_boolean = CASE WHEN vine = 1 THEN 1 ELSE 0 END;
UPDATE MSBA_Team9.reviews_clean
SET verified_purchase_boolean = CASE WHEN verified_purchase = 1 THEN 1 ELSE 0 END;

-- 3: TEXT PROCESSING -------------------------------------------------------------------------
# Luckily, our server is MySQL 8.0+, so we have access to REGEX in our query
# Use nested REGEXP replacements to eliminate numbers, punctuation, and common start/stop words from review_body
# Then, run a REGEXP replacement on the resulting strings to replace instances of 2 or more spaces consecutively with only 1 space
# Then, run a REGEXP replacement on the resulting strings to remove any leading or trailing spaces
# Finally, set all resulting text to lowercase
SELECT 
	LOWER(
		REGEXP_REPLACE(
			REGEXP_REPLACE(
				REGEXP_REPLACE(review_body, 
				'[0-9]|[\\p{P}]|\\b(?:the|and|of|a|in|to|for|with|on|as)\\b', '')
			,'([ ]* ){2,}', ' '),
		'^( )+|( )+$|<br >|VIDEOID[A-Za-z0-9]+', '')
	) AS cleaned_reviews
FROM reviews_raw;

# Now that we know our REGEX query works, let's use it to replace the column with cleaned text
ALTER TABLE reviews_clean
ADD cleaned_review_body varchar(255);
# add the cleaned reviews to the new column

UPDATE reviews_clean
SET cleaned_review_body = 
	LOWER(
		REGEXP_REPLACE(
			REGEXP_REPLACE(
				REGEXP_REPLACE(review_body, 
				'\\d+|[\\p{P}]|\\b(?:the|and|of|a|in|to|for|with|on|as)\\b', '')
			,'([ ]* ){2,}', ' '),
		'^( )+|( )+$|<br >|VIDEOID[A-Za-z0-9]+', '')
	);

-- 4: DATA DOMAIN VALIDATION & STANDARDIZATION ------------------------------------------------
# Identified that there are instances where the product_category contains a date
SELECT DISTINCT(product_category), COUNT(*) FROM MSBA_Team9.reviews_clean
GROUP BY product_category;
# Drop instances where the product_category isn't correctly identified
DELETE FROM reviews_clean
WHERE product_category NOT IN ('Kitchen', 'Pet Products');

-- 5: Redundant or Irrelevant Attributes ------------------------------------------------------
DESCRIBE reviews_clean;
# Only 1 distinct marketplace value
SELECT DISTINCT marketplace FROM reviews_clean;
# So we can drop the column
ALTER TABLE reviews_clean DROP COLUMN marketplace;

# and we can drop the non-boolean (tinyint) versions of the vine and verified_purchase columns, as well as review_body, now that we've replaced them
ALTER TABLE reviews_clean 
DROP COLUMN vine,
DROP COLUMN verified_purchase,
DROP COLUMN review_body;

# and now let's update our column names
ALTER TABLE reviews_clean
RENAME COLUMN vine_boolean TO vine,
RENAME COLUMN verified_purchase_boolean TO verified_purchase,
RENAME COLUMN cleaned_review_body TO review_body;

# Data Analysis questions Q1-Q4

SELECT COUNT(*) AS num_rows FROM reviews_clean;
SELECT COUNT(*) AS num_columns
FROM information_schema.columns 
WHERE table_name = 'reviews_clean' AND table_schema = 'MSBA_Team9';

SELECT COUNT(DISTINCT product_id) as unique_products
FROM reviews_clean; 

SELECT COUNT(DISTINCT customer_id) as unique_customers
FROM reviews_clean;

SELECT COUNT(DISTINCT product_id, product_parent) AS unique_combinations
FROM reviews_clean;

CREATE TABLE question_5 AS
SELECT star_rating, verified_purchase
FROM reviews_clean;
# Get the average of all star ratings in the table
SELECT AVG(star_rating) FROM question_5;
# Get the avg star ratings for each verified_purchase value
SELECT verified_purchase, AVG(star_rating) as avg_star_rating
FROM question_5
GROUP BY verified_purchase;

CREATE TABLE question_6 AS
SELECT star_rating
FROM reviews_clean;
# Get the count total number of reviews for each of the distinct possible star_rating values
SELECT star_rating, COUNT(star_rating) AS num_of_reviews
FROM question_6
GROUP BY star_rating
ORDER BY star_rating DESC;