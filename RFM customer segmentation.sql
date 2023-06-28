/*Creating a Recency, frequency, monetary value (RFM) model to segment the customers into 6 categories, 'Loyal', 'Active', 'Potential Churners','New Customers'
'Slipping away' and 'Lost customers' by evaluating how recently they’ve made a purchase, how often they buy, and the size of their purchases.The predictions
can be used to predict which customers are likely to purchase the company's products again, 
how much revenue comes from new vs. repeat clients, and how to turn occasional buyers into habitual ones.*/


DROP TABLE IF EXISTS #rfm;
with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(SALES) MonetaryValue,
		avg(SALES) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from [dbo].[Sales]) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[Sales])) Recency
	from [Sales].[dbo].[Sales]
	group by CUSTOMERNAME
),
rfm_calc as
(

	select RFM.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm RFM
)
select 
	cal.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_value,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_string
into #rfm
from rfm_calc cal

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'Lost customers'  --lost customers
		when rfm_string in (133, 134, 143, 244, 334, 343, 344, 144, 234) then 'Slipping away' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_string in (311, 411, 331, 412, 423) then 'New customers'
		when rfm_string in (222, 223, 233, 322,221) then 'Potential churners'
		when rfm_string in (323, 333,321, 422, 332, 432, 232, 421) then 'Active' --(Customers who buy often & recently, but at low price points)
		when rfm_string in (433, 434, 443, 444) then 'Loyal'
	end Customer_segment

from #rfm
