-- -- 1. 
-- --     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT SUM(total_claim_count),npi
From prescription
GROUP BY total_claim_count,npi
ORDER BY total_claim_count DESC;

--Answer: Coffey, NPI 1912011792, number of claims 4538, dirty doctor scenario on that Oxycodone



    
-- --     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT total_claim_count AS total_claims,nppes_provider_last_org_name AS last_name, nppes_provider_first_name AS first_name,npi,specialty_description
From prescriber AS presc
JOIN prescription AS rx USING (npi)
ORDER BY rx.total_claim_count DESC
LIMIT 1;
--Answer: 4538	"COFFEY"	"DAVID"	1912011792	"Family Practice"


-- -- 2. 
-- --     a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT DISTINCT prescriber.specialty_description AS specialty, SUM(total_claim_count)
From prescriber
JOIN prescription USING (npi)
GROUP BY prescriber.specialty_description
ORDER BY SUM(total_claim_count)DESC
LIMIT 1;

--Answer: Family Practice, 9,752,347


-- --     b. Which specialty had the most total number of claims for opioids?
SELECT DISTINCT prescriber.specialty_description AS specialty, SUM(total_claim_count)AS claims,drug.opioid_drug_flag AS opioid
From prescriber
JOIN prescription USING (npi)
JOIN drug
ON prescription.drug_name=drug.drug_name 
WHERE drug.opioid_drug_flag LIKE 'Y'
GROUP BY specialty,opioid
ORDER BY claims DESC
LIMIT 1;

--Answer: Nurse Practitioner, 900,845

-- --     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT DISTINCT prescriber.specialty_description AS specialty, prescription.total_claim_count AS claims
FROM prescriber
JOIN prescription USING (npi)
GROUP BY specialty,claims
ORDER BY claims ;
--Answer: not ready for this yet "Providers with fewer than 11 claims are not included in the data file"

-- --     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- -- 3. 
-- --     a. Which drug (generic_name) had the highest total drug cost?
SELECT d.generic_name,SUM(MONEY(sc.total_drug_cost)) AS g
FROM prescription AS sc
	INNER JOIN drug AS d USING (drug_name)
WHERE sc.total_drug_cost IS NOT NULL
GROUP BY d.generic_name
ORDER BY g DESC
LIMIT 1;

--Answer: Pirfenidone, $2,829,174.30


-- --     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT generic_name AS generic,ROUND(total_drug_cost/total_day_supply,2) AS price_per_day
FROM prescription
JOIN drug USING (drug_name)
GROUP BY generic,price_per_day
ORDER BY price_per_day DESC
LIMIT 1;
--Answer: "IMMUN GLOB G(IGG)/GLY/IGA OV50"	$7,141.11


-- -- 4. 
-- --     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT
	CASE WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
	WHEN opioid_drug_flag= 'Y' THEN  'opioid'
	ELSE 'neither' END AS drug_type,
	drug
	
FROM drug;



-- --     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT SUM(total_drug_cost)AS money,
	CASE WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
	WHEN opioid_drug_flag= 'Y' THEN  'opioid'
	ELSE 'neither' END AS drug_type
FROM drug AS d
JOIN prescription AS rx USING (drug_name)
GROUP BY drug_type;

5. 
-- --     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT DISTINCT cbsaname AS cbsa_count
FROM cbsa
WHERE cbsaname LIKE '%TN%'
GROUP BY cbsaname;

--Answer: 10





-- --     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsa.cbsaname,population.population
FROM cbsa
JOIN fips_county USING (fipscounty)
JOIN population USING (fipscounty)
ORDER BY population.population DESC;
	
				

--Answer: Largets= "Memphis, TN-MS-AR"	population:937847, Smallest= "Nashville-Davidson--Murfreesboro--Franklin, TN"	population:8773

-- --     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT population,cbsa,cbsaname,county
FROM population AS pop
FULL JOIN cbsa USING(fipscounty) AS cb
JOIN fips_county USING (fipscounty)
WHERE cbsa IS NULL
ORDER BY population DESC
LIMIT 1;
--Answer: Population: 95523			"SEVIER"



-- -- 6. 
-- --     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name,total_claim_count
FROM prescription
JOIN drug USING (drug_name)
WHERE total_claim_count>=3000
GROUP BY drug_name,total_claim_count;

-- --     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name,total_claim_count,opioid_drug_flag
FROM prescription
JOIN drug USING (drug_name)
WHERE total_claim_count>=3000
GROUP BY drug_name,total_claim_count,opioid_drug_flag;

-- --     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT drug_name,total_claim_count,opioid_drug_flag,prescriber.nppes_provider_last_org_name AS last_name, prescriber.nppes_provider_first_name AS first_name
FROM prescription
JOIN drug USING (drug_name)
JOIN prescriber  
ON prescriber.npi=prescription.npi
WHERE total_claim_count>=3000
GROUP BY drug_name,total_claim_count,opioid_drug_flag,last_name,first_name;

-- -- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

-- --     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

-- --     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
 
 SELECT prescriber.npi,drug_name,total_claim_count
 FROM prescriber
 CROSS JOIN drug
 LEFT JOIN prescription
 USING(npi,drug_name)
 WHERE specialty_description = 'Pain Management'
 		AND nppes_provider_city = 'Nahsville'
		AND opioid_drug_flag = 'Y'
ORDER BY drug_name;

-- --     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
