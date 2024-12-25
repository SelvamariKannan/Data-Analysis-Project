-- BOGOF & 500
	select distinct product_code from fact_events
	where base_price > 500 && promo_type="BOGOF";

-- desc city and count
	select city,count(store_id) from dim_stores
    group by city
    order by count(store_id) desc ;

-- revenue
	SELECT campaign_name,concat(round(sum(base_price * `quantity_sold(before_promo)`)/1000000,2),'M')
		 as `Total_Revenue(Before_Promotion)`,
		concat(round(sum(
		case
		when promo_type = "BOGOF" then base_price * 0.5 * 2*(`quantity_sold(after_promo)`)
		when promo_type = "50% OFF" then base_price * 0.5 * `quantity_sold(after_promo)`
		when promo_type = "25% OFF" then base_price * 0.75* `quantity_sold(after_promo)`
		when promo_type = "33% OFF" then base_price * 0.67 * `quantity_sold(after_promo)`
		when promo_type = "500 cashback" then (base_price-500)*  `quantity_sold(after_promo)`
		end)/1000000,2),'M') as `Total_Revenue(After_Promotion)`
		 FROM retail_events_db.fact_events join dim_campaigns c using (campaign_id) group by campaign_id;



-- isu%
		with cte1 as(
		SELECT *,(if(promo_type = "BOGOF",`quantity_sold(after_promo)` * 2 ,`quantity_sold(after_promo)`)) as quantities_sold_AP 
		FROM retail_events_db.fact_events 
		join dim_campaigns using(campaign_id)
		join dim_products using (product_code)
		where campaign_name = "Diwali" ),

		cte2 as(
		select 
		campaign_name, category,
		((sum(quantities_sold_AP) - sum(`quantity_sold(before_promo)`))/sum(`quantity_sold(before_promo)`)) * 100 as `ISU%`
		 from cte1 group by category 
		 )
		 
		 select campaign_name, category, `ISU%`, rank() over(order by `ISU%`DESC) as `ISU%_Rank` from cte2;
 
 
 
	with cte1 as(
		SELECT category,product_name,sum(base_price * `quantity_sold(before_promo)`) as Total_Revenue_BP,
		sum(
		case
		when promo_type = "BOGOF" then base_price * 0.5 * 2*(`quantity_sold(after_promo)`)
		when promo_type = "50% OFF" then base_price * 0.5 * `quantity_sold(after_promo)`
		when promo_type = "25% OFF" then base_price * 0.75* `quantity_sold(after_promo)`
		when promo_type = "33% OFF" then base_price * 0.67 * `quantity_sold(after_promo)`
		when promo_type = "500 cashback" then (base_price-500)*  `quantity_sold(after_promo)`
		end) as Total_Revenue_AP FROM retail_events_db.fact_events 
		join dim_products using (product_code) 
		join dim_campaigns using(campaign_id)
		group by product_name,category),

		cte2 as(
		select *,(total_revenue_AP - total_revenue_BP) as IR,  
		((total_revenue_AP - total_revenue_BP)/total_revenue_BP) * 100 as `IR%`
		from cte1)

		select product_name,category,`IR`,`IR%`, rank() over(order by`IR%` DESC ) as Rank_IR from cte2 limit 5;
