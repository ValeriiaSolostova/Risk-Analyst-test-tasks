--Creating tables for SQL using xlxs files

CREATE TABLE loan_table (
loan_id BIGSERIAL NOT NULL, 
loan_rate FLOAT NOT NULL, 
amount INT NOT NULL, 
term INT NOT NULL, 
status VARCHAR NOT NULL, 
start_date DATE NOT NULL,
date_of_default DATE
);

CREATE TABLE investors (
investor_id BIGSERIAL NOT NULL, 
date DATE NOT NULL, 
loan_id INT NOT NULL, 
amount FLOAT NOT NULL, 
principal_payment FLOAT NOT NULL,
interest_payment FLOAT NOT NULL
);
--Необходимо рассчитать число активных займов в портфелях инвесторов. В качестве ответа нужно предоставить разницу по модулю этих значений между инвесторами с id = 1 и id = 3.

SELECT COUNT(l.status),l.status, i.investor_id
FROM loan_table AS l
JOIN investors AS i
ON i.loan_id = l.loan_id
WHERE i.investor_id IN ('1','3')
AND l.status = 'active'
GROUP BY i.investor_id, l.status;

--Необходимо рассчитать, какую долю от общей суммы каждого займа составляет инвестиция каждого конкретного инвестора.Среди рассчитанных значений  получить среднее значение по всем займам, а также максимальное значение для займа с id = 3.

WITH InvestorCashflowSummary AS (
  SELECT
    i.loan_id,
    i.investor_id,
    SUM(i.amount) AS total_investment
  FROM
    investors AS i 
  GROUP BY
    i.loan_id, i.investor_id
)

SELECT
  l.loan_id,
  l.amount AS total_loan_amount,
  ic.investor_id,
  ic.total_investment,
  ic.total_investment / l.amount AS investment_percenta
FROM
  loan_table AS l
  LEFT JOIN InvestorCashflowSummary AS ic ON l.loan_id = ic.loan_id
ORDER BY
  l.loan_id, ic.investor_id;
  
  
  SELECT
  AVG(investment_percenta) AS average_investment_percentage
FROM
  (
    WITH InvestorCashflowSummary AS (
  SELECT
    i.loan_id,
    i.investor_id,
    SUM(i.amount) AS total_investment
  FROM
    investors AS i 
  GROUP BY
    i.loan_id, i.investor_id
)

SELECT
  l.loan_id,
  l.amount AS total_loan_amount,
  ic.investor_id,
  ic.total_investment,
  ic.total_investment / l.amount AS investment_percenta
FROM
  loan_table AS l
  LEFT JOIN InvestorCashflowSummary AS ic ON l.loan_id = ic.loan_id
ORDER BY
  l.loan_id, ic.investor_id
  ) AS subquery;
  
  SELECT
  MAX(investment_percenta) AS max_investment_percentage_for_loan_3
FROM
  (
    WITH InvestorCashflowSummary AS (
  SELECT
    i.loan_id,
    i.investor_id,
    SUM(i.amount) AS total_investment
  FROM
    investors AS i 
  GROUP BY
    i.loan_id, i.investor_id
)

SELECT
  l.loan_id,
  l.amount AS total_loan_amount,
  ic.investor_id,
  ic.total_investment,
  ic.total_investment / l.amount AS investment_percenta
FROM
  loan_table AS l
  LEFT JOIN InvestorCashflowSummary AS ic ON l.loan_id = ic.loan_id
ORDER BY
  l.loan_id, ic.investor_id
  ) AS subquery
WHERE
  loan_id = 3;
 
 -- Необходимо рассчитать относительное значение дохода (или потерь) инвесторов на конец дня 01.03.2023 по каждому.
 
 WITH InvestorCashflowSummary AS (
  SELECT
    ic.loan_id,
    ic.investor_id,
    MAX(ic.date) AS last_operation_date,
    SUM(ic.principal_payment + ic.interest_payment) AS total_revenue,
    MAX(CASE WHEN l.status = 'default' AND ic.date <= l.date_of_default THEN l.amount - ic.principal_payment ELSE 0 END) AS potential_loss
  FROM
    investors as ic
    JOIN loan_table as l ON ic.loan_id = l.loan_id
  WHERE
    ic.date <= '2023-03-01'
  GROUP BY
    ic.loan_id, ic.investor_id
)

SELECT
  ic.loan_id,
  ic.investor_id,
  ic.last_operation_date,
  ic.total_revenue,
  ic.potential_loss,
  (ic.total_revenue - ic.potential_loss) / l.amount AS relative_profit_loss
FROM
  InvestorCashflowSummary ic
  JOIN loan_table l ON ic.loan_id = l.loan_id
ORDER BY
  ic.loan_id, ic.investor_id;
  
  SELECT MIN(relative_profit_loss), MAX(relative_profit_loss)
  FROM (WITH InvestorCashflowSummary AS (
  SELECT
    ic.loan_id,
    ic.investor_id,
    MAX(ic.date) AS last_operation_date,
    SUM(ic.principal_payment + ic.interest_payment) AS total_revenue,
    MAX(CASE WHEN l.status = 'default' AND ic.date <= l.date_of_default THEN l.amount - ic.principal_payment ELSE 0 END) AS potential_loss
  FROM
    investors as ic
    JOIN loan_table as l ON ic.loan_id = l.loan_id
  WHERE
    ic.date <= '2023-03-01'
  GROUP BY
    ic.loan_id, ic.investor_id
)

SELECT
  ic.loan_id,
  ic.investor_id,
  ic.last_operation_date,
  ic.total_revenue,
  ic.potential_loss,
  (ic.total_revenue - ic.potential_loss) / l.amount AS relative_profit_loss
FROM
  InvestorCashflowSummary ic
  JOIN loan_table l ON ic.loan_id = l.loan_id
ORDER BY
  ic.loan_id, ic.investor_id);
  
  WITH InvestorCashflowSummary AS (
  SELECT
    ic.loan_id,
    ic.investor_id,
    MAX(ic.date) AS last_operation_date,
    SUM(ic.principal_payment + ic.interest_payment) AS total_revenue,
    MAX(CASE WHEN l.status = 'default' AND ic.date <= l.date_of_default THEN l.amount - ic.principal_payment ELSE 0 END) AS potential_loss
  FROM
    investors ic
    JOIN loan_table l ON ic.loan_id = l.loan_id
  WHERE
    ic.date <= '2023-03-01'
  GROUP BY
    ic.loan_id, ic.investor_id
)

SELECT
  ABS(MAX(ic.total_revenue - ic.potential_loss) - MIN(ic.total_revenue - ic.potential_loss)) * 10000 AS result
FROM
  InvestorCashflowSummary ic
GROUP BY ic.loan_id, ic.investor_id
ORDER BY
  ic.loan_id, ic.investor_id;

-- Необходимо рассчитать помесячный относительный доход инвесторов с даты начала их инвестирования по конец наблюдений 01.02.2024.

WITH MonthlyInvestorCashflow AS (
  SELECT
    investor_id,
    DATE_TRUNC('month', date) AS month,
    SUM(principal_payment + interest_payment) AS monthly_revenue
  FROM
    investors
  WHERE
    date <= '2024-02-01'
  GROUP BY
    investor_id, DATE_TRUNC('month', date)
)

SELECT
  investor_id,
  month,
  COALESCE(SUM(monthly_revenue) OVER (PARTITION BY investor_id ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS cumulative_revenue
FROM
  MonthlyInvestorCashflow
ORDER BY
  investor_id, month;
  
 