# QuickDelivery

![CI](https://github.com/AmalMselmi/quick-delivery/actions/workflows/ci.yml/badge.svg)

QuickDelivery is a food delivery platform made of a Flutter mobile client and a Laravel REST API. Customers browse restaurants, build a cart, choose a delivery point on a map, and place cash-on-delivery orders. Administrators manage restaurants, menu items and orders from a dashboard inside the same app.

## Table of contents

1. [Features](#features)
2. [Tech stack](#tech-stack)
3. [Architecture](#architecture)
4. [Repository structure](#repository-structure)
5. [Getting started](#getting-started)
6. [Configuration](#configuration)
7. [API reference](#api-reference)
8. [Data model](#data-model)
9. [Business rules](#business-rules)
10. [Testing and CI](#testing-and-ci)
11. [Security notes](#security-notes)
12. [Known limitations](#known-limitations)
13. [Roadmap](#roadmap)

## Features

**Customer**
- Registration, login and logout with token authentication
- Restaurant list with text search and cuisine filter
- Menu browsing with availability status
- Persistent cart stored locally in SQLite, restricted to one restaurant at a time
- Delivery address selection on an OpenStreetMap map, with address search, reverse geocoding and device location
- Delivery fee calculated by the server from the distance between the restaurant and the delivery point
- Order placement (cash on delivery) and order history with automatic status refresh

**Administrator**
- Role-based navigation: administrators land on the dashboard after login
- Dashboard with orders today, revenue today, pending orders, client count and recent orders
- Create, edit and delete restaurants, including their map location
- Create, edit and delete menu items
- Order list with status filter and status updates (pending, preparing, on the way, delivered, cancelled)

## Tech stack

| Layer | Technology |
|---|---|
| Mobile client | Flutter, Dart, Riverpod (`StateNotifier`), `http`, `sqflite`, `shared_preferences` |
| Maps | `flutter_map`, OpenStreetMap tiles, Nominatim, `geolocator`, `latlong2` |
| Backend | PHP 8.2+, Laravel 12, Laravel Sanctum |
| Database | SQLite (default) or MySQL |
| Testing | PHPUnit (feature tests), `flutter_test` |
| CI | GitHub Actions |

## Architecture

```
+--------------------+        HTTPS/JSON         +-----------------------+
|   Flutter client   |  <--------------------->  |    Laravel REST API   |
|                    |   Bearer token (Sanctum)  |                       |
| Riverpod providers |                           | Controllers           |
| ApiService         |                           | Admin middleware      |
| SQLite cart        |                           | Eloquent models       |
+--------------------+                           +-----------+-----------+
          |                                                  |
          | OSM tiles, Nominatim                             |
          v                                                  v
   OpenStreetMap services                        SQLite or MySQL database
```

Design decisions:

- **Server-side pricing.** The client sends only item identifiers and quantities. The server reads prices from the database, computes the subtotal and the delivery fee, and stores the order. A client cannot submit its own prices.
- **Token authentication.** Login returns a Sanctum personal access token. The app stores it in `shared_preferences` and sends it as a bearer token.
- **Role enforcement on the server.** Admin routes sit behind `auth:sanctum` and a custom `admin` middleware. Role checks in the app only control navigation.
- **Local cart.** The cart lives in SQLite on the device and survives restarts. It stores the restaurant identifier so mixed-restaurant carts can be detected before checkout.
- **Polling instead of push.** Order status screens and the admin dashboard refresh every 15 seconds.

## Repository structure

```
quick-delivery/
  .github/workflows/ci.yml     CI pipeline
  backend/                     Laravel API
    app/
      Http/Controllers/        Auth, Restaurant, Menu, Order, AdminOrder
      Http/Middleware/         AdminMiddleware
      Models/                  User, Restaurant, Menu, Order, OrderItem
      Services/DeliveryFee.php Distance-based fee calculation
    database/
      migrations/
      seeders/
    routes/api.php
    tests/Feature/
  mobile/                      Flutter app
    lib/
      models/
      providers/               Riverpod state
      screens/                 Customer screens
      screens/admin/           Administrator screens
      services/                ApiService, AuthService, DBHelper
      utils/
      widgets/
      theme.dart
    test/
```

## Getting started

### Prerequisites

- PHP 8.2 or later with the `pdo_sqlite` extension (and `pdo_mysql` if you use MySQL)
- Composer
- Flutter SDK (Dart 3.10 or later)
- An Android emulator or a physical device
- MySQL 8 (optional)

### 1. Clone the repository

```bash
git clone https://github.com/USER/quick-delivery.git
cd quick-delivery
```

### 2. Run the backend

```bash
cd backend
composer install
cp .env.example .env          # on Windows CMD: copy .env.example .env
php artisan key:generate
```

With the default SQLite configuration, create the database file and run the migrations with seed data:

```bash
touch database/database.sqlite    # on Windows CMD: type nul > database\database.sqlite
php artisan migrate:fresh --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Verify the API: `http://127.0.0.1:8000/api/restaurants` should return four restaurants as JSON.

To use MySQL instead, create an empty database and set these values in `.env` before migrating:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=quick_delivery_db
DB_USERNAME=root
DB_PASSWORD=
```

Then run `php artisan config:clear` and `php artisan migrate:fresh --seed`.

### 3. Run the mobile app

```bash
cd mobile
flutter pub get
flutter run
```

The API base URL is defined in `mobile/lib/services/api_service.dart`:

| Target | Base URL |
|---|---|
| Android emulator | `http://10.0.2.2:8000/api` (default) |
| Physical device on the same network | `http://<PC_LAN_IP>:8000/api` |
| iOS simulator or desktop | `http://localhost:8000/api` |

Because the development server uses plain HTTP, Android may require `android:usesCleartextTraffic="true"` on the `<application>` element of `AndroidManifest.xml`. Location features need the location permissions declared in the same file.

### Demo accounts

The seeder creates two demo accounts for local development only.

| Role | Email | Password |
|---|---|---|
| Administrator | `admin@quickdelivery.com` | `admin123` |
| Client | `client@quickdelivery.com` | `client123` |

Do not reuse these credentials anywhere else, and remove the seeded accounts before any real deployment.

## Configuration

| File | Purpose |
|---|---|
| `backend/.env` | Database connection, application key, session driver |
| `backend/.env.example` | Template for `.env`, committed to the repository |
| `mobile/lib/services/api_service.dart` | API base URL |
| `backend/app/Services/DeliveryFee.php` | Fee constants |

Session storage is set to `file` because the API does not use the database session table.

## API reference

Base path: `/api`. Protected routes require `Authorization: Bearer <token>` and `Accept: application/json`. Errors return JSON with a `message` field. Validation failures return status 422.

### Authentication

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/register` | none | Create a client account. The `role` field is ignored and always set to `client`. Returns 201 with `token`, `role`, `name`, `email`. |
| POST | `/login` | none | Returns `token`, `role`, `name`, `email`. Rate limited to 10 requests per minute. Returns 401 on invalid credentials. |
| POST | `/logout` | token | Revokes the user's tokens. |
| GET | `/me` | token | Returns the authenticated user. |

### Catalogue (public)

| Method | Path | Description |
|---|---|---|
| GET | `/restaurants` | List restaurants. |
| GET | `/restaurants/{id}` | Restaurant details. |
| GET | `/menu?restaurantId={id}` | Menu items, optionally filtered by restaurant. |
| GET | `/menu/{id}` | Single menu item. |

### Orders (authenticated)

| Method | Path | Description |
|---|---|---|
| GET | `/orders` | Orders of the authenticated user, newest first, with items. |
| POST | `/orders/quote` | Returns `subtotal`, `delivery_fee`, `total` without creating an order. |
| POST | `/orders` | Creates an order. Returns 201. |

Request body for `/orders` and `/orders/quote`:

```json
{
  "address": "Avenue Habib Bourguiba, Tunis",
  "latitude": 36.8065,
  "longitude": 10.1815,
  "items": [
    { "id": 1, "quantity": 2 },
    { "id": 3, "quantity": 1 }
  ]
}
```

`address` is required for `/orders` and optional for `/orders/quote`. `latitude` and `longitude` are optional.

### Administration (token and admin role)

| Method | Path | Description |
|---|---|---|
| POST | `/admin/restaurants` | Create a restaurant. Returns 201. |
| PUT | `/admin/restaurants/{id}` | Update a restaurant. |
| DELETE | `/admin/restaurants/{id}` | Delete a restaurant and, by cascade, its menu items. |
| POST | `/admin/menu` | Create a menu item. Returns 201. |
| PUT | `/admin/menu/{id}` | Update a menu item. |
| DELETE | `/admin/menu/{id}` | Delete a menu item. |
| GET | `/admin/orders?status={status}` | List all orders, optionally filtered by status. |
| PUT | `/admin/orders/{id}/status` | Update an order status. |
| GET | `/admin/stats` | Dashboard figures and the five most recent orders. |

Authenticated non-admin users receive 403 on admin routes. Missing or invalid tokens receive 401.

Allowed order statuses: `pending`, `preparing`, `on_the_way`, `delivered`, `cancelled`.

## Data model

| Table | Main columns |
|---|---|
| `users` | `id`, `name`, `email` (unique), `password` (hashed), `role` (`admin` or `client`) |
| `restaurants` | `id`, `name`, `image`, `rating`, `cuisineType`, `latitude`, `longitude` |
| `menu` | `id`, `restaurantId` (foreign key, cascade delete), `name`, `price`, `image`, `available` |
| `orders` | `id`, `user_id`, `restaurant_id`, `status`, `total`, `delivery_fee`, `address`, `latitude`, `longitude`, `payment_method` |
| `order_items` | `id`, `order_id`, `name`, `price`, `quantity` |
| `personal_access_tokens` | Sanctum tokens |

Order items store a copy of the name and price at the time of purchase, so later menu changes do not alter past orders.

## Business rules

- An order must contain at least one item, and every item must exist and be available.
- All items in an order must belong to the same restaurant. Otherwise the API returns 422.
- The subtotal is computed from current database prices. The total is the subtotal plus the delivery fee.
- Delivery fee: `2.00 + 0.50 * distance_km`, capped at `15.00`, with the distance computed by the haversine formula. A flat fee of `3.00` applies when the restaurant or the delivery point has no coordinates.
- Payment method is cash on delivery. No payment data is collected or stored.
- Cancelled orders are excluded from the revenue figure on the dashboard.

## Testing and CI

Backend tests run against an in-memory SQLite database and do not touch your development database:

```bash
cd backend
php artisan test
```

The feature tests cover:
- Login success and failure
- Guest (401) and client (403) access to admin routes
- Registration ignoring a requested `admin` role
- Order creation with server-side totals, unavailable items, and mixed-restaurant rejection
- Distance-based and flat delivery fees
- Order isolation between users
- Admin order listing, status updates, status validation and dashboard statistics

Mobile checks:

```bash
cd mobile
flutter analyze
flutter test
```

The GitHub Actions workflow in `.github/workflows/ci.yml` runs the backend tests, `flutter analyze` and `flutter test` on every push to `main` and on pull requests.

## Security notes

- Passwords are hashed by the model's `hashed` cast.
- Role assignment is controlled by the server. Public registration always creates a client.
- Order prices and fees are never accepted from the client.
- The login endpoint is rate limited.
- `.env` files, keystores and build output are excluded from version control.

## Known limitations

- The access token is stored with `shared_preferences`, which is not encrypted. A production app should use secure storage, and tokens should have an expiry.
- Sanctum tokens are created without an expiration time.
- Status updates use periodic polling every 15 seconds, not push notifications or WebSockets.
- Restaurant and menu images are external URLs entered by the administrator. There is no file upload.
- A user has a single token session: logging in revokes previous tokens.
- The public OpenStreetMap tile server and Nominatim are intended for light use. A production deployment should use a dedicated tile provider and geocoding service.
- The `menu` table and `restaurantId` column do not follow Laravel naming conventions (`menu_items`, `restaurant_id`). They are kept because the mobile client uses these field names.
- There is no online payment, courier assignment, or push notification system.

## Roadmap

- Secure token storage and token expiration
- Image upload with file storage
- WebSocket or push notifications for order status
- Online payment integration
- Pagination on list endpoints
- Integration tests for the mobile client
