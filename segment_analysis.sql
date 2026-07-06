-- =====================================================
-- Loan Default Risk Analysis - Segment Queries
-- Horizon Financial Group
-- =====================================================

-- Q1: Default rate by credit score bucket (all loans)

SELECT 
    CASE 
        WHEN borrower_profiles.credit_score BETWEEN 520 AND 599 THEN '520-599'
        WHEN borrower_profiles.credit_score BETWEEN 600 AND 649 THEN '600-649'
        WHEN borrower_profiles.credit_score BETWEEN 650 AND 699 THEN '650-699'
        WHEN borrower_profiles.credit_score BETWEEN 700 AND 749 THEN '700-749'
        WHEN borrower_profiles.credit_score >= 750 THEN '750+'
        ELSE 'Unknown'
    END AS credit_score_bucket,
    COUNT(*) AS loan_count,
    AVG(CAST(loan_applications.defaulted AS FLOAT)) AS default_rate
FROM loan_applications
INNER JOIN borrower_profiles
    ON loan_applications.borrower_id = borrower_profiles.borrower_id
GROUP BY 
    CASE 
        WHEN borrower_profiles.credit_score BETWEEN 520 AND 599 THEN '520-599'
        WHEN borrower_profiles.credit_score BETWEEN 600 AND 649 THEN '600-649'
        WHEN borrower_profiles.credit_score BETWEEN 650 AND 699 THEN '650-699'
        WHEN borrower_profiles.credit_score BETWEEN 700 AND 749 THEN '700-749'
        WHEN borrower_profiles.credit_score >= 750 THEN '750+'
        ELSE 'Unknown'
    END
-- Now same thing but the resolved-only rate --
SELECT 
    CASE 
        WHEN borrower_profiles.credit_score BETWEEN 520 AND 599 THEN '520-599'
        WHEN borrower_profiles.credit_score BETWEEN 600 AND 649 THEN '600-649'
        WHEN borrower_profiles.credit_score BETWEEN 650 AND 699 THEN '650-699'
        WHEN borrower_profiles.credit_score BETWEEN 700 AND 749 THEN '700-749'
        WHEN borrower_profiles.credit_score >= 750 THEN '750+'
        ELSE 'Unknown'
    END AS credit_score_bucket,
    COUNT(*) AS loan_count,
    AVG(CAST(loan_applications.defaulted AS FLOAT)) AS default_rate
FROM loan_applications
INNER JOIN borrower_profiles
    ON loan_applications.borrower_id = borrower_profiles.borrower_id
WHERE loan_applications.loan_status IN ('Default', 'Paid Off')
GROUP BY 
    CASE 
        WHEN borrower_profiles.credit_score BETWEEN 520 AND 599 THEN '520-599'
        WHEN borrower_profiles.credit_score BETWEEN 600 AND 649 THEN '600-649'
        WHEN borrower_profiles.credit_score BETWEEN 650 AND 699 THEN '650-699'
        WHEN borrower_profiles.credit_score BETWEEN 700 AND 749 THEN '700-749'
        WHEN borrower_profiles.credit_score >= 750 THEN '750+'
        ELSE 'Unknown'
    END

/*The 520–599 credit score bucket shows a 49% default rate overall. Notably, among loans in this bucket 
that have already reached a final outcome (paid off or defaulted), 81% ended in default, suggesting the 
true failure rate for this segment is likely higher than 49% once currently active loans resolve. */

-- Q2: Default rate by DTI ratio

SELECT 
	CASE
		WHEN dti_ratio < 20 THEN '0%-20%'
		WHEN dti_ratio < 50 THEN '20%-50%'
	    WHEN dti_ratio < 75 THEN '50%-75%'
		WHEN dti_ratio < 100 THEN '75%-100%'
		ELSE '100%+'
	END AS dti_ratio_bucket,
	count(*) as dti_count,
	avg(cast(loan_applications.defaulted AS FLOAT)) AS default_rate,
	min(dti_ratio) AS sort_helper
FROM loan_applications
GROUP BY
	CASE
		WHEN dti_ratio < 20 THEN '0%-20%'
		WHEN dti_ratio < 50 THEN '20%-50%'
	    WHEN dti_ratio < 75 THEN '50%-75%'
		WHEN dti_ratio < 100 THEN '75%-100%'
		ELSE '100%+'
	END
ORDER BY sort_helper

-- testing 2 buckets above and below 50% -- 

SELECT 
	CASE	
		WHEN dti_ratio < 50 THEN 'Under 50%' ELSE '50%+' 
	END AS dti_ratio_bucket,
	count(*) as dti_count,
	avg(cast(loan_applications.defaulted AS FLOAT)) AS default_rate
FROM loan_applications
GROUP BY
	CASE 
		WHEN dti_ratio < 50 THEN 'Under 50%' ELSE '50%+'
	END

/*My conclusion: DTI ratio shows a clear risk threshold at 50%. Loans with DTI under 50% default at 16.1%, while 
loans at or above 50% default at 34.3% — more than double. We recommend capping approvals at 50% DTI, or 
applying stricter terms/higher scrutiny above that threshold.*/

-- Q3a: Default rate by loan purpose 
 
SELECT loan_purpose, count(*) as purpose_count, avg(cast(defaulted AS FLOAT)) AS default_rate
from loan_applications
GROUP BY
	loan_purpose

-- Q3b: Average loan amount, defaulted vs non-defaulted

SELECT defaulted, avg(loan_amount) as avg_loan_amount
from loan_applications
GROUP BY
	defaulted

/* Loan purpose shows a modest default rate spread (20.6%–32.1%), but the gap is far smaller than 
credit score or DTI, and category sample sizes (50–70 loans) limit confidence in ranking individual purposes. 
Loan amount shows no meaningful difference between defaulted ($22,571 avg) and non-defaulted loans ($22,013 avg) 
, loan size is not a driver of default risk.Loan purpose shows a modest default rate spread (20.6%–32.1%), but the 
gap is far smaller than credit score or DTI, and category sample sizes (50–70 loans) limit confidence in ranking 
individual purposes. Loan amount shows no meaningful difference between defaulted ($22,571 avg) and non-defaulted 
loans ($22,013 avg) — loan size is not a driver of default risk. */

-- Q4a: Default rate by employment status

SELECT 
    borrower_profiles.employment_status,
    COUNT(*) AS employment_count,
    AVG(CAST(loan_applications.defaulted AS FLOAT)) AS default_rate
FROM loan_applications
INNER JOIN borrower_profiles
    ON loan_applications.borrower_id = borrower_profiles.borrower_id
GROUP BY 
    borrower_profiles.employment_status

/*  checked employment stats and it doesnt impact default rate */

-- Q4b: Default rate by years employed (<2 vs 2+ years)

Select 
	CASE 
		WHEN years_employed < 2 THEN '<2 years'
		WHEN years_employed >=2 THEN '>2 years'
	END AS years_of_experience,
	COUNT(*) AS bucket_count,
	avg(cast(loan_applications.defaulted AS FLOAT)) AS default_rate

from borrower_profiles
INNER JOIN loan_applications
	on borrower_profiles.borrower_id = loan_applications.borrower_id
GROUP BY
	CASE 
		WHEN years_employed < 2 THEN '<2 years'
		WHEN years_employed >=2 THEN '>2 years'
	END
