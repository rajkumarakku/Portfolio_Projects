import pandas as pd
import numpy as np
from faker import Faker
from datetime import datetime, timedelta
import random

# Initialize Faker
fake = Faker()

# Set random seed for reproducibility
np.random.seed(42)
random.seed(42)

# Configuration
NUM_CUSTOMERS = 900
NUM_PRODUCTS = 700
NUM_ORDERS = 10000
NUM_SELLERS = 55

# Generate Categories
categories = [
    (1, 'electronics'),
    (2, 'clothing'),
    (3, 'home&kitchen'),
    (4, 'pet supplies'),
    (5, 'toys&games'),
    (6, 'sports&outdoors')
]

category_df = pd.DataFrame(categories, columns=['category_id', 'category_name'])

# Generate Sellers
sellers_data = []
seller_names = [
    'AmazonBasics', 'Anker', 'Samsung', 'Apple', 'Sony', 'Nike', 'Adidas', 'KitchenAid', 
    'Dell', 'HP', 'Lenovo', 'LG', 'Whirlpool', 'Microsoft', 'Logitech', 'Canon', 'Epson',
    'Philips', 'Bosch', 'Black+Decker', 'Dyson', 'Shimano', 'Columbia', 'Under Armour',
    'Puma', 'Reebok', 'Levis', 'Calvin Klein', 'Tommy Hilfiger', 'Ralph Lauren', 'Cuisinart',
    'Ninja', 'Instant Pot', 'Keurig', 'iRobot', 'Fitbit', 'Garmin', 'GoPro', 'JBL', 'Bose',
    'Hasbro', 'LEGO', 'Mattel', 'Fisher-Price', 'Nerf', 'Purina', 'Pedigree', 'Blue Buffalo',
    'Hills Science Diet', 'Iams', 'Temptations', 'Greenies', 'Kong', 'Frisco', 'BrandX'
]

origins = ['USA', 'China', 'South Korea', 'Germany', 'Japan', 'UK', 'France', 'Italy', 'Canada', 'Australia']

for i in range(NUM_SELLERS):
    seller_id = i + 1
    seller_name = seller_names[i] if i < len(seller_names) else f"Brand{seller_id}"
    origin = random.choice(origins)
    sellers_data.append((seller_id, seller_name, origin))

sellers_df = pd.DataFrame(sellers_data, columns=['seller_id', 'seller_name', 'origin'])

# Generate Products
products_data = []
electronics = ['Wireless Earbuds', 'Smartphone', 'Laptop', 'Tablet', 'Smart Watch', 
               'Bluetooth Speaker', 'Headphones', 'Power Bank', 'Camera', 'Monitor']
clothing = ['T-Shirt', 'Jeans', 'Sweater', 'Jacket', 'Dress', 'Skirt', 'Shorts', 
            'Coat', 'Hoodie', 'Polo Shirt']
home_kitchen = ['Coffee Maker', 'Blender', 'Toaster', 'Microwave', 'Air Fryer', 
                'Mixer', 'Cookware Set', 'Knife Set', 'Food Processor', 'Vacuum Cleaner']
pet_supplies = ['Dog Food', 'Cat Food', 'Pet Bed', 'Pet Toy', 'Leash', 'Collar', 
                'Pet Bowl', 'Aquarium', 'Bird Cage', 'Pet Grooming Kit']
toys_games = ['Building Blocks', 'Board Game', 'Action Figure', 'Doll', 'Puzzle', 
              'Remote Control Car', 'Stuffed Animal', 'Educational Toy', 'Outdoor Play Set', 'Art Set']
sports_outdoors = ['Tent', 'Sleeping Bag', 'Backpack', 'Hiking Boots', 'Bicycle', 
                   'Helmet', 'Yoga Mat', 'Dumbbell Set', 'Exercise Bike', 'Treadmill']

for i in range(NUM_PRODUCTS):
    product_id = i + 1
    category_id = random.randint(1, 6)
    
    if category_id == 1:
        product_name = f"{random.choice(electronics)} Model {random.randint(1, 5)}"
        price = round(random.uniform(50, 550), 2)
        cogs = round(price * random.uniform(0.3, 0.6), 2)
    elif category_id == 2:
        product_name = f"{random.choice(clothing)} Style {random.randint(1, 5)}"
        price = round(random.uniform(15, 115), 2)
        cogs = round(price * random.uniform(0.3, 0.6), 2)
    elif category_id == 3:
        product_name = f"{random.choice(home_kitchen)} Series {random.randint(1, 5)}"
        price = round(random.uniform(25, 325), 2)
        cogs = round(price * random.uniform(0.3, 0.6), 2)
    elif category_id == 4:
        product_name = f"{random.choice(pet_supplies)} Pack {random.randint(1, 5)}"
        price = round(random.uniform(10, 100), 2)
        cogs = round(price * random.uniform(0.3, 0.6), 2)
    elif category_id == 5:
        product_name = f"{random.choice(toys_games)} Edition {random.randint(1, 5)}"
        price = round(random.uniform(20, 100), 2)
        cogs = round(price * random.uniform(0.3, 0.6), 2)
    else:
        product_name = f"{random.choice(sports_outdoors)} Pro {random.randint(1, 5)}"
        price = round(random.uniform(30, 300), 2)
        cogs = round(price * random.uniform(0.3, 0.6), 2)
    
    products_data.append((product_id, product_name, price, cogs, category_id))

products_df = pd.DataFrame(products_data, columns=['product_id', 'product_name', 'price', 'cogs', 'category_id'])

# Generate Customers
customers_data = []
us_states = [
    'California', 'Texas', 'Florida', 'New York', 'Pennsylvania', 'Illinois', 'Ohio', 'Georgia',
    'North Carolina', 'Michigan', 'New Jersey', 'Virginia', 'Washington', 'Arizona', 'Massachusetts',
    'Tennessee', 'Indiana', 'Missouri', 'Maryland', 'Wisconsin', 'Colorado', 'Minnesota', 'South Carolina',
    'Alabama', 'Louisiana', 'Kentucky', 'Oregon', 'Oklahoma', 'Connecticut', 'Utah', 'Iowa', 'Nevada',
    'Arkansas', 'Mississippi', 'Kansas', 'New Mexico', 'Nebraska', 'West Virginia', 'Idaho', 'Hawaii',
    'New Hampshire', 'Maine', 'Montana', 'Rhode Island', 'Delaware', 'South Dakota', 'North Dakota',
    'Alaska', 'Vermont', 'Wyoming'
]

for i in range(NUM_CUSTOMERS):
    customer_id = i + 1
    first_name = fake.first_name()
    last_name = fake.last_name()
    state = random.choice(us_states)
    customers_data.append((customer_id, first_name, last_name, state))

customers_df = pd.DataFrame(customers_data, columns=['customer_id', 'first_name', 'last_name', 'state'])

# Generate Orders
orders_data = []
order_statuses = ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled', 'Returned']
start_date = datetime(2021, 1, 1)
end_date = datetime(2024, 12, 31)

for i in range(NUM_ORDERS):
    order_id = i + 1
    order_date = fake.date_between(start_date=start_date, end_date=end_date)
    customer_id = random.randint(1, NUM_CUSTOMERS)
    seller_id = random.randint(1, NUM_SELLERS)
    order_status = random.choice(order_statuses)
    orders_data.append((order_id, order_date, customer_id, seller_id, order_status))

orders_df = pd.DataFrame(orders_data, columns=['order_id', 'order_date', 'customer_id', 'seller_id', 'order_status'])

# Generate Order Items
order_items_data = []

for i in range(NUM_ORDERS):
    order_item_id = i + 1
    order_id = i + 1
    product_id = random.randint(1, NUM_PRODUCTS)
    quantity = random.randint(1, 5)
    price_per_unit = products_df[products_df['product_id'] == product_id]['price'].values[0]
    total_price = round(price_per_unit * quantity, 2)
    order_items_data.append((order_item_id, order_id, product_id, quantity, price_per_unit, total_price))

order_items_df = pd.DataFrame(order_items_data, columns=['order_item_id', 'order_id', 'product_id', 'quantity', 'price_per_unit', 'total_price'])

# Generate Payments
payments_data = []
payment_modes = ['Credit Card', 'Debit Card', 'PayPal', 'Amazon Pay', 'Gift Card']
payment_statuses = ['Failed', 'Pending', 'Completed']

for i in range(NUM_ORDERS):
    payment_id = i + 1
    order_id = i + 1
    order_date = orders_df[orders_df['order_id'] == order_id]['order_date'].values[0]
    payment_date = order_date + timedelta(days=random.randint(0, 2))
    payment_mode = random.choice(payment_modes)
    payment_status = random.choices(payment_statuses, weights=[1, 1, 8], k=1)[0]
    payments_data.append((payment_id, order_id, payment_date, payment_mode, payment_status))

payments_df = pd.DataFrame(payments_data, columns=['payment_id', 'order_id', 'payment_date', 'payment_mode', 'payment_status'])

# Generate Shipping
shipping_data = []
shipping_providers = ['UPS', 'FedEx', 'USPS', 'DHL', 'Amazon Logistics', 'Bluedart']
delivery_statuses = ['Pending', 'Processing', 'Shipped', 'Out for Delivery', 'Delivered', 'Returned']

for i in range(NUM_ORDERS):
    shipping_id = i + 1
    order_id = i + 1
    order_date = orders_df[orders_df['order_id'] == order_id]['order_date'].values[0]
    shipping_date = order_date + timedelta(days=random.randint(3, 10))
    
    # 10% chance of return
    if random.random() < 0.1:
        return_date = shipping_date + timedelta(days=random.randint(5, 15))
    else:
        return_date = None
        
    shipping_provider = random.choice(shipping_providers)
    delivery_status = random.choice(delivery_statuses)
    shipping_data.append((shipping_id, order_id, shipping_date, return_date, shipping_provider, delivery_status))

shipping_df = pd.DataFrame(shipping_data, columns=['shipping_id', 'order_id', 'shipping_date', 'return_date', 'shipping_provider', 'delivery_status'])

# Generate Inventory
inventory_data = []

for i in range(NUM_PRODUCTS):
    inventory_id = i + 1
    product_id = i + 1
    stock = random.randint(0, 1000)
    warehouse_id = random.randint(1, 10)
    last_stock_date = fake.date_between(start_date=start_date, end_date=end_date)
    inventory_data.append((inventory_id, product_id, stock, warehouse_id, last_stock_date))

inventory_df = pd.DataFrame(inventory_data, columns=['inventory_id', 'product_id', 'stock', 'warehouse_id', 'last_stock_date'])

# Save to CSV files
category_df.to_csv('category.csv', index=False)
sellers_df.to_csv('sellers.csv', index=False)
products_df.to_csv('products.csv', index=False)
customers_df.to_csv('customers.csv', index=False)
orders_df.to_csv('orders.csv', index=False)
order_items_df.to_csv('order_items.csv', index=False)
payments_df.to_csv('payments.csv', index=False)
shipping_df.to_csv('shipping.csv', index=False)
inventory_df.to_csv('inventory.csv', index=False)

# Print summary
print("Data generation completed!")
print(f"Categories: {len(category_df)}")
print(f"Sellers: {len(sellers_df)}")
print(f"Products: {len(products_df)}")
print(f"Customers: {len(customers_df)}")
print(f"Orders: {len(orders_df)}")
print(f"Order Items: {len(order_items_df)}")
print(f"Payments: {len(payments_df)}")
print(f"Shipping: {len(shipping_df)}")
print(f"Inventory: {len(inventory_df)}")
