--What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(price)
FROM sales AS s
LEFT JOIN menu AS m
	ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;


--How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date)
FROM sales
GROUP BY customer_id;


--What was the first item from the menu purchased by each customer?
WITH first_item AS(
	SELECT customer_id,product_id,
	RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS rank
	FROM sales)

SELECT customer_id,product_name
FROM first_item AS f
INNER JOIN menu AS m
	ON f.product_id = m.product_id
WHERE rank =1
GROUP BY customer_id,product_name;


--What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name,COUNT(sales.product_id) AS no_of_times_purchased
FROM menu
INNER JOIN sales
	ON menu.product_id = sales.product_id
GROUP BY product_name
ORDER BY COUNT(sales.product_id) DESC
LIMIT 1;


--Which item was the most popular for each customer?
WITH most_popular AS(
	SELECT customer_id,product_name,COUNT(product_name) AS order_count,
		RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(product_name) DESC) AS ranked
	FROM sales
	INNER JOIN menu
		ON sales.product_id = menu.product_id
	GROUP BY customer_id,product_name)

SELECT customer_id,product_name,order_count
FROM most_popular
WHERE ranked =1;



--Which item was purchased first by the customer after they became a member?
WITH first_purchase AS(
	SELECT sales.customer_id AS customer,product_name,
		RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date) AS date_ranked
	FROM sales
	INNER JOIN members
		ON sales.customer_id = members.customer_id
	INNER JOIN menu
		ON sales.product_id = menu.product_id
	WHERE order_date >= join_date)

SELECT customer,product_name
FROM first_purchase
WHERE date_ranked = 1;


--Which item was purchased just before the customer became a member?
WITH purchase_before_membership AS (
	SELECT sales.customer_id AS customer,product_name,
		ROW_NUMBER() OVER(PARTITION BY sales.customer_id ORDER BY order_date DESC) AS date_ranked
	FROM sales
	INNER JOIN members
		ON sales.customer_id = members.customer_id
	INNER JOIN menu
		ON sales.product_id = menu.product_id
	WHERE order_date < join_date)

SELECT customer,product_name
FROM purchase_before_membership
WHERE date_ranked = 1;


--What is the total items and amount spent for each member before they became a member?

SELECT customer,COUNT(product_name),SUM(price)
FROM(SELECT sales.customer_id AS customer,product_name,price
	FROM sales
	INNER JOIN members
		ON sales.customer_id = members.customer_id
	INNER JOIN menu
		ON sales.product_id = menu.product_id
	WHERE order_date < join_date) AS total_items
GROUP BY customer
ORDER BY customer;


--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?


SELECT sales.customer_id AS customer,
	SUM(CASE
		WHEN product_name = 'sushi' THEN 2*10*price
		ELSE 10*price END) AS total_point
FROM sales
INNER JOIN menu
	ON sales.product_id = menu.product_id
GROUP BY customer
ORDER BY customer;


--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?



SELECT sales.customer_id AS customer,
SUM(CASE
	WHEN (order_date < join_date) AND product_name <> 'sushi' THEN 10*price
	WHEN (order_date < join_date) AND product_name = 'sushi' THEN 2*10*price
	WHEN order_date BETWEEN join_date AND join_date + 6  THEN 2*10*price
	WHEN (order_date > join_date +6) AND product_name = 'sushi' THEN 2*10*price
	ELSE 10*price END) AS point
FROM sales
INNER JOIN members
ON sales.customer_id = members.customer_id
INNER JOIN menu
ON sales.product_id = menu.product_id
GROUP BY customer
ORDER BY customer
