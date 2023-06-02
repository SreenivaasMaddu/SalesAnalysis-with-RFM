

  -------------Inspecting Data----------------------------------------------

    select * FROM [PortfolioDB].[dbo].[SampleSalesData]


  --------------Checking Unique values---------------------------------------

    select distinct STATUS FROM [PortfolioDB].[dbo].[SampleSalesData]
    select distinct year_id FROM [PortfolioDB].[dbo].[SampleSalesData]
	select distinct PRODUCTLINE FROM [PortfolioDB].[dbo].[SampleSalesData]
	select distinct COUNTRY FROM [PortfolioDB].[dbo].[SampleSalesData]
	select distinct DEALSIZE FROM [PortfolioDB].[dbo].[SampleSalesData]
	select distinct TERRITORY FROM [PortfolioDB].[dbo].[SampleSalesData]

	-----------Grouping sales by productline----------------------

	select PRODUCTLINE, sum(sales) Revenue
	FROM [PortfolioDB].[dbo].[SampleSalesData]
	group by PRODUCTLINE
	order by 2 desc


	-----------Grouping sales by YEAR_ID----------------------

    select YEAR_ID, sum(sales) Revenue
	FROM [PortfolioDB].[dbo].[SampleSalesData]
	group by YEAR_ID
	order by 2 desc


	-----------Grouping sales by DEALSIZE----------------------

	select  DEALSIZE,  sum(sales) Revenue
	FROM [PortfolioDB].[dbo].[SampleSalesData]
	group by  DEALSIZE
	order by 2 desc


   -----------What city has the highest number of sales in a specific country

	select city, sum (sales) Revenue
	FROM [PortfolioDB].[dbo].[SampleSalesData]
	where country = 'UK'
	group by city
	order by 2 desc


  ------------What is the best product in United States?

	select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
	FROM [PortfolioDB].[dbo].[SampleSalesData]
	where country = 'USA'
	group by  country, YEAR_ID, PRODUCTLINE
	order by 4 desc


	----------What was the best month for sales in a specific year? How much was earned that month? 

	select  MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency
	FROM [PortfolioDB].[dbo].[SampleSalesData]
	where YEAR_ID = 2004 --change year to see the rest
	group by  MONTH_ID
	order by 2 desc

	

	select  MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER) Frequency
	FROM [PortfolioDB].[dbo].[SampleSalesData]
	where YEAR_ID = 2004 and MONTH_ID = 11 --change year to see the rest
	group by  MONTH_ID, PRODUCTLINE
	order by 3 desc





	-----------Who is our best customer (this could be best answered with RFM)


DROP TABLE IF EXISTS #rfm
;with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) Revenue,
		avg(sales) AvgMRevenueValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) fROM [PortfolioDB].[dbo].[SampleSalesData]) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) FROM [PortfolioDB].[dbo].[SampleSalesData])) Recency
	FROM [PortfolioDB].[dbo].[SampleSalesData]
	group by CUSTOMERNAME
),
rfm_calc as
(

	select *,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by Revenue) rfm_revenue
	from rfm 
)
select 
	*, rfm_recency+ rfm_frequency+ rfm_revenue as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_revenue  as varchar)rfm_cell_string
into #rfm
from rfm_calc ;



select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_revenue,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm;



select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	FROM [PortfolioDB].[dbo].[SampleSalesData] w
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) cnt
				FROM [PortfolioDB].[dbo].[SampleSalesData]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where cnt = 3
		)
		and w.ORDERNUMBER = p.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

FROM [PortfolioDB].[dbo].[SampleSalesData] p
order by 2 desc