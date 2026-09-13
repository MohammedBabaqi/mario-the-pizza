CREATE TABLE IF NOT EXISTS users (
    uid TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    display_name TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    photo_url TEXT NOT NULL DEFAULT '',
    phone_number TEXT NOT NULL DEFAULT '',
    default_address TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS users_email_lower_idx ON users (LOWER(email));

CREATE TABLE IF NOT EXISTS pizzas (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    rating NUMERIC(3, 2) NOT NULL CHECK (rating BETWEEN 0 AND 5),
    calories INTEGER NOT NULL CHECK (calories >= 0),
    protein INTEGER NOT NULL CHECK (protein >= 0),
    fat INTEGER NOT NULL CHECK (fat >= 0),
    carbs INTEGER NOT NULL CHECK (carbs >= 0),
    ingredients JSONB NOT NULL DEFAULT '[]'::jsonb,
    category TEXT NOT NULL,
    image_url TEXT NOT NULL,
    is_popular BOOLEAN NOT NULL DEFAULT FALSE,
    is_recommended BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS orders (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(uid),
    status TEXT NOT NULL CHECK (status IN ('confirmed', 'preparing', 'baking', 'outForDelivery', 'delivered')),
    subtotal NUMERIC(10, 2) NOT NULL CHECK (subtotal >= 0),
    delivery_fee NUMERIC(10, 2) NOT NULL CHECK (delivery_fee >= 0),
    discount NUMERIC(10, 2) NOT NULL CHECK (discount >= 0),
    total NUMERIC(10, 2) NOT NULL CHECK (total >= 0),
    delivery_address TEXT NOT NULL,
    payment_method TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    estimated_delivery TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS orders_user_created_idx ON orders (user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS order_items (
    order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    id TEXT NOT NULL,
    pizza_id TEXT NOT NULL REFERENCES pizzas(id),
    pizza_name TEXT NOT NULL,
    pizza_image_url TEXT NOT NULL,
    pizza_price NUMERIC(10, 2) NOT NULL CHECK (pizza_price >= 0),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    size TEXT NOT NULL,
    crust TEXT NOT NULL,
    sauce TEXT NOT NULL,
    extra_toppings JSONB NOT NULL DEFAULT '[]'::jsonb,
    item_total NUMERIC(10, 2) NOT NULL CHECK (item_total >= 0),
    PRIMARY KEY (order_id, id)
);
