# Case Study 1: Danny's Diner

## Solution


### 1. What is the total amount each customer spent at the restaurant?

````sql
SELECT s.customer_id, SUM(price)
FROM sales AS s
LEFT JOIN menu AS m
	ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id
````

#### Answer:
| Customer_id | Total_sales |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |


### 2. How many days has each customer visited the restaurant?

````sql
SELECT customer_id, COUNT(DISTINCT order_date)
FROM sales
GROUP BY customer_id
````

#### Answer:
| Customer_id | Times_visited |
| ----------- | ----------- |
| A           | 4          |
| B           | 6          |
| C           | 2          |


### 3. What was the first item from the menu purchased by each customer?

````sql
WITH first_item AS(
	SELECT customer_id,product_id,
	RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS rank
	FROM sales)

SELECT customer_id,product_name
FROM first_item AS f
INNER JOIN menu AS m
	ON f.product_id = m.product_id
WHERE rank =1
GROUP BY customer_id,product_name
````

#### Answer:
| Customer_id | product_name | 
| ----------- | ----------- |
| A           | curry        | 
| A           | sushi        | 
| B           | curry        | 
| C           | ramen        |

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

````sql
SELECT product_name,COUNT(sales.product_id) AS no_of_times_purchased
FROM menu
INNER JOIN sales
	ON menu.product_id = sales.product_id
GROUP BY product_name
ORDER BY COUNT(sales.product_id) DESC
LIMIT 1;
````

#### Answer:
| Product_name  | no_of_times_Purchased | 
| ----------- | ----------- |
| ramen       | 8|


### 5. Which item was the most popular for each customer?

````sql
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
````

#### Answer:
| Customer_id | Product_name | order_Count |
| ----------- | ---------- |------------  |
| A           | ramen        |  3   |
| B           | sushi        |  2   |
| B           | curry        |  2   |
| B           | ramen        |  2   |
| C           | ramen        |  3   |


### 6. Which item was purchased first by the customer after they became a member?

````sql
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
````

#### Answer:
| customer_id |  product_name |
| ----------- | ----------  |
| A           |  curry        |
| B           |  sushi        |


### 7. Which item was purchased just before the customer became a member?

````sql
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
````

#### Answer:
| customer_id |product_name |
| ----------- | ----------  |
| A           |  sushi      | 
| B           |  sushi      |



### 8. What is the total items and amount spent for each member before they became a member?

````sql
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

````

#### Answer:
| customer_id |Items | price |
| ----------- | ---------- |----------  |
| A           | 2 |  25       |
| B           | 3 |  40       |


### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?

````sql
SELECT sales.customer_id AS customer,
	SUM(CASE
		WHEN product_name = 'sushi' THEN 2*10*price
		ELSE 10*price END) AS total_point
FROM sales
INNER JOIN menu
	ON sales.product_id = menu.product_id
GROUP BY customer
ORDER BY customer;
````

#### Answer:
| customer | total_Points | 
| ----------- | -------|
| A           | 860 |
| B           | 940 |
| C           | 360 |

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?


````sql
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
ORDER BY customer;
````


#### Answer:
| Customer| Points | 
| ----------- | ---------- |
| A           | 1370 |
| B           | 940 |
