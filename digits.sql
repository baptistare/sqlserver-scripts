IF OBJECT_ID('dbo.digits', 'U') IS NOT NULL DROP TABLE dbo.digits;

CREATE TABLE dbo.digits(digit INT NOT NULL PRIMARY KEY);

INSERT INTO dbo.digits(digit) VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

SELECT digit FROM dbo.digits;

IF OBJECT_ID('dbo.nums', 'U') IS NOT NULL DROP TABLE dbo.nums;

CREATE TABLE dbo.nums(n INT NOT NULL PRIMARY KEY);

INSERT		dbo.nums (n)
SELECT		D6.digit * 100000 + D5.digit * 10000 + D4.digit * 1000 + D3.digit * 100 + D2.digit * 10 + D1.digit + 1 AS n
--INTO		nums
FROM		dbo.digits AS D1
CROSS JOIN	dbo.digits AS D2
CROSS JOIN	dbo.digits AS D3
CROSS JOIN	dbo.digits AS D4
CROSS JOIN	dbo.digits AS D5
CROSS JOIN	dbo.digits AS D6
ORDER BY	n;

SELECT n FROM dbo.nums;

SELECT		DATEADD(day, n-1, '20160101') AS orderdate
FROM		dbo.nums
WHERE		n <= DATEDIFF(day, '20160101', '20160110') + 1
ORDER BY	orderdate;

--SELECT DATEADD(day, nums.n - 1, '20060101') AS orderdate, O.orderid, O.custid, O.empid
--FROM dbo.nums
--LEFT OUTER JOIN Sales.Orders AS O
--ON DATEADD(day, nums.n - 1, '20060101') = O.orderdate
--WHERE nums.n <= DATEDIFF(day, '20060101', '20081231') + 1
--ORDER BY orderdate;