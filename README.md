# MoneyMate - Digital Wallet API

MoneyMate is a Ruby on Rails API-based digital wallet application that enables users to manage their finances through deposits, withdrawals, transfers, and transaction tracking.


## Features

- User authentication with JWT tokens
- Wallet management (deposit, withdraw, transfer)
- Balance checking
- Transaction history with pagination

## Tech Stack

- **Language**: Ruby 3.x with Sorbet typing
- **Framework**: Ruby on Rails 7.1
- **Database**: PostgreSQL
- **Authentication**: Devise with JWT
- **Currency Handling**: Money gem

## System Architecture

The application follows a service-oriented architecture within a Rails monolith:

- **Models**: User, Wallet, Transaction
- **Controllers**: API endpoints for wallet operations and user data
- **Services**: Business logic separation for wallet operations, user transactions, and authorization

### Database Schema

- **Users**: Account information and authentication
- **Wallets**: Store user balances
- **Transactions**: Record of all financial activities
- **JWT Denylist**: For token revocation

## Setup Instructions

### Prerequisites

- Ruby 3.x
- PostgreSQL
- Bundler

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/moushumiseal/MoneyMate
   cd MoneyMate
   ```

2. Install dependencies
   ```bash
   bundle install
   ```

3. Set up environment variables
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials and JWT secret
   ```

4. Set up the database
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed 
   ```

5. Run the server
   ```bash
   rails server
   ```

## API Endpoints

Base URL: `/money_mate/api`

### Authentication

- **POST** `/users/sign_up` - Register new user
- **POST** `/users/sign_in` - Login user
- **DELETE** `/users/sign_out` - Logout user

### Wallet Operations

- **POST** `/wallets/:id/deposit` - Add money to wallet
  ```json
  {
    "amount": 100.00,
    "currency": "SGD"
  }
  ```

- **POST** `/wallets/:id/withdraw` - Remove money from wallet
  ```json
  {
    "amount": 50.00,
    "currency": "SGD"
  }
  ```

- **POST** `/wallets/:id/transfer` - Transfer money to another user
  ```json
  {
    "amount": 25.00,
    "currency": "SGD",
    "receiver_id": 123
  }
  ```

### User Information

- **GET** `/users/:id/balance` - Get wallet balance
- **GET** `/users/:id/transactions` - View transaction history
  - Query params: `page` (default: 1), `per_page` (default: 10, max: 100)

## Testing with Postman

### Setup Postman Collection

1. Download [Postman](https://www.postman.com/downloads/)
2. Create a new collection named "MoneyMate API"
3. Set up environment variables:
   - `base_url`: `http://localhost:3000/money_mate/api`
   - `auth_token`: (this will be populated after login)

### Authentication Flow

1. **Register a User**
   - Method: `POST`
   - URL: `{{base_url}}/users`
   - Headers: `Content-Type: application/json`
   - Body:
     ```json
     {
       "user": {
         "email": "test@example.com",
         "password": "password123",
         "password_confirmation": "password123",
         "name": "Test User"
       }
     }
     ```

2. **Login**
   - Method: `POST`
   - URL: `{{base_url}}/users/sign_in`
   - Headers: `Content-Type: application/json`
   - Body:
     ```json
     {
       "user": {
         "email": "test@example.com",
         "password": "password123"
       }
     }
     ```
   - In Tests tab, add script to extract token:
     ```javascript
     var responseJson = pm.response.json();
     if (responseJson.token) {
       pm.environment.set("auth_token", responseJson.token);
     }
     ```

### Testing Wallet Operations

For all wallet operations, add this header:
- `Authorization`: `Bearer {{auth_token}}`

1. **Get User ID and Wallet ID**
   - After logging in, note the user ID from the response
   - You'll need this to identify your wallet

2. **Deposit Money**
   - Method: `POST`
   - URL: `{{base_url}}/wallets/:wallet_id/deposit`
   - Body:
     ```json
     {
       "amount": 1000.00
     }
     ```

3. **Check Balance**
   - Method: `GET`
   - URL: `{{base_url}}/users/:user_id/balance`

4. **Withdraw Money**
   - Method: `POST`
   - URL: `{{base_url}}/wallets/:wallet_id/withdraw`
   - Body:
     ```json
     {
       "amount": 500.00
     }
     ```

5. **Create Second User for Transfer Testing**
   - Repeat the registration process with different email
   - Note the second user's ID

6. **Transfer Money**
   - Method: `POST`
   - URL: `{{base_url}}/wallets/:wallet_id/transfer`
   - Body:
     ```json
     {
       "amount": 250.00,
       "receiver_id": 2
     }
     ```

7. **View Transaction History**
   - Method: `GET`
   - URL: `{{base_url}}/users/:user_id/transactions`
   - Optional Query Params: `page=1&per_page=20`

### Testing Error Scenarios

1. **Insufficient Funds**
   - Attempt to withdraw or transfer more than available balance

2. **Invalid Amount**
   - Try to deposit, withdraw, or transfer a negative amount

3. **Access Another User's Wallet**
   - Try to access another user's wallet with your authentication token

4. **Transfer to Self**
   - Attempt to transfer money to your own wallet

## Design Decisions

### Currency Handling
- Used the Money gem to prevent floating-point errors in financial calculations
- Currently supporting SGD currency, with architecture allowing for future multi-currency support

### Transaction Types
- Implemented three distinct transaction types: deposit, withdraw, and transfer
- Each type has appropriate validation rules and affects wallet balances differently

### Authorization
- Created a dedicated UserAuthorizationService to ensure users can only access their own data
- JWT token-based authentication for secure API access

### Database Indexes
- Added strategic indexes on transaction status and wallet relationships to improve query performance

### Transaction Safety
- Implemented database locking to prevent race conditions during wallet operations
- Used ActiveRecord transactions to ensure atomic operations

## Testing the Application

Run the test suite:
```bash
rails test
```

### Sample Workflow for Testing:

1. Register two users
2. Deposit money to first user's wallet
3. Transfer money from first user to second user
4. Check both users' transaction histories and balances

## Code Navigation Guide for Reviewers

When reviewing this codebase, start with:

1. **Database Schema** (`db/schema.rb`) - To understand the data model
2. **Routes** (`config/routes.rb`) - To see the available API endpoints
3. **Models** - Examine the relationships and validations
   - `app/models/user.rb`
   - `app/models/wallet.rb`
   - `app/models/transaction.rb`
4. **Controllers** - API endpoints and request handling
   - `app/controllers/api/wallets_controller.rb` - Wallet operations (deposit, withdraw, transfer)
   - `app/controllers/api/users_controller.rb` - User-related operations (balance, transaction history)
5. **Services** - Core business logic
   - `app/services/wallet_service.rb` - Main wallet operations
   - `app/services/user_authorization_service.rb` - Security
   - `app/services/user_wallet_service.rb` - Balance handling
   - `app/services/user_transaction_service.rb` - Transaction history

### Key Implementation Details

The `WalletsController` handles the core wallet operations:
- **Deposit** - Adds money to a wallet
- **Withdraw** - Removes money if sufficient funds exist
- **Transfer** - Moves money between wallets

Each action includes error handling for:
- Invalid amount values (negative or zero)
- Insufficient funds
- Invalid transaction types (e.g., transfers to self)

Authorization is handled by the `authorize_wallet_access!` method, which ensures users can only operate on their own wallets.

## Areas for Improvement

Based on the time constraints and project scope, several features were not implemented but could enhance the application in future iterations:

1. Multi-currency support - Architecture supports it, but currently limited to SGD
2. Email notifications - Could be added for transaction confirmations and security alerts
3. Scheduled transfers - Future-dated or recurring transfers between users
4. Transaction rollbacks/cancellations - Status field exists but functionality not fully implemented
5. Rate limiting - Protection against API abuse would be important in production
6. Transfer limits - Implementation of daily/monthly transfer caps for security
7. Comprehensive error handling - Production-ready error tracking and reporting
8. Fraud detection - Pattern recognition for suspicious activities
9. Internationalization - Support for multiple languages in error messages and system communications
10. Advanced Search - Enhanced transaction filtering capabilities
11. Webhooks - Add notifications for transactions
12. Admin Panel - Create administrative functions for system oversight
13. Performance Optimization - Add caching for frequent balance checks
14. API Documentation - Generate comprehensive API docs with Swagger/OpenAPI

## Development Time

- Total time spent: Approximately 20 hours
  - Database design: 3 hours
  - Core wallet functionality: 8 hours
  - API endpoints and authentication: 5 hours
  - Testing and documentation: 4 hours
