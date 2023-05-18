CREATE SCHEMA if not exists dannys_diner;

use dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  

-- What is the total amount each customer spent at the restaurant?

select s.customer_id, sum(price)
from sales s
inner join menu m
on s.product_id = m.product_id
group by s.customer_id;

-- How many days has each customer visited the restaurant?

select customer_id , count(distinct order_date) as Days
from sales
group by customer_id;

-- What was the first item from the menu purchased by each customer?

with temp_table as (
select customer_id,product_name ,row_number() over(partition by customer_id order by order_date) as a
from sales
join menu
on sales.product_id = menu.product_id)
select customer_id , product_name
from temp_table
where a = 1;


-- What is the most purchased item on the menu and how many times was it purchased by all customers?

select product_name , count(product_name) as Total_Purchase
from sales
join menu
on sales.product_id = menu.product_id
group by product_name
order by Total_Purchase desc
limit 1;



-- Which item was the most popular for each customer?

with temp_table as(
select distinct customer_id , product_name , count(product_name) over(partition by customer_id,product_name) as Total_Sales
from sales s
join menu m
on m.product_id = s.product_id)
select customer_id , product_name , max(Total_Sales)
from temp_table
group by customer_id;


-- Which item was purchased first by the customer after they became a member?

with temp_table as(
select s.customer_id , product_name , row_number() over(partition by customer_id order by order_date) numbering
from sales s
join menu m
on s.product_id = m.product_id
join members me
on me.customer_id = s.customer_id
where order_date >= join_date)
select customer_id, product_name
from temp_table
where numbering = 1;


-- Which item was purchased just before the customer became a member?

select customer_id , product_name
from 
(select s.customer_id, product_name , order_date , dense_rank() over(partition by customer_id order by order_date desc) numbering
from sales s
join menu m
on m.product_id = s.product_id
join members me
on s.customer_id = me.customer_id
where order_date < join_date) temp_table
where numbering = 1;


-- What is the total items and amount spent for each member before they became a member?

select s.customer_id , count(product_name) , sum(price)
from sales s
join menu m
on s.product_id = m.product_id
join members me
on me.customer_id = s.customer_id
where order_date < join_date
group by customer_id
order by customer_id;

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select customer_id , 
sum(case
when lower(product_name) = 'sushi' then price*10*2
else price*10
end) as Total_Points
from sales s
join menu m
on s.product_id = m.product_id
group by customer_id;


-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?

with temp_table as (
select s.customer_id , order_date , price , product_name,
join_date + interval 6 day as validity_date # Till what date they earn 2x points
from sales s
join menu m
on s.product_id = m.product_id
join members me
on me.customer_id = s.customer_id
where join_date <= order_date and month(order_date) = 1 # Customer who are already a member and in month of JAN
)
select customer_id , 
sum(case 
when lower(product_name) = 'sushi' then price*10*2
when order_date <= validity_date then price*10*2 # Customer gaining 2x points on 1st week order
else price*10 
end) as Total_Points
from temp_table
group by customer_id;





