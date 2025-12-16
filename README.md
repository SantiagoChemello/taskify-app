# Taskify: Task Management Application

Taskify is a minimalist and elegant web application for managing your daily tasks. Designed to be simple yet powerful, it helps you organize your personal and professional activities efficiently, without unnecessary complications.

<img width="968" height="446" alt="Screenshot 2025-12-15 at 19 07 13" src="https://github.com/user-attachments/assets/ca87112e-c320-49ca-8fb3-3dd8a4239b77" />

## Features

- 📝 Organize tasks intuitively and visually
- 🎯 Set priorities and deadlines easily
- 👥 Collaborate with your team in real-time
- 📱 Access from any device, anytime
- 🎨 Clean and minimalist interface that doesn't distract
- 🔔 Smart notifications so you don't miss anything important

## Requirements

Before running the project, ensure you have the following installed:

- **Ruby 3.4.4** (check with `ruby -v`)
- **PostgreSQL 14 or higher** (check with `psql --version`)
- **Node.js 18 or higher** (check with `node -v`)
- **npm** (comes with Node.js)

## Quick Setup

1. **Navigate to the project directory:**
   ```bash
   cd Taskify
   ```

2. **Install Ruby dependencies:**
   ```bash
   bundle install
   ```

3. **Install JavaScript dependencies:**
   ```bash
   npm install
   ```

4. **Set up the database:**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed  # Creates demo data and users
   ```

5. **Start the server:**
   ```bash
   rails server
   ```

The application will be available at `http://localhost:3000`

## Demo Credentials

After running `rails db:seed`, you can use these accounts to test the application:

**Admin:**
- Email: `admin@taskify.com`
- Password: `password123`

**Task Makers (can create and assign tasks):**
- Email: `manager@taskify.com` | Password: `password123`
- Email: `supervisor@taskify.com` | Password: `password123`

**Task Doers (can complete assigned tasks):**
- Email: `worker1@taskify.com` | Password: `password123`
- Email: `worker2@taskify.com` | Password: `password123`

## Running with Tailwind CSS Watcher

To run both the Rails server and Tailwind CSS watcher simultaneously:

```bash
bin/dev
```

This uses the `Procfile.dev` to start both processes.

## Troubleshooting

- **Database connection errors:** Ensure PostgreSQL is running (`brew services start postgresql` on macOS)
- **Asset compilation errors:** Clear the cache with `rails tmp:clear`
- **Port already in use:** Stop any existing Rails server or use a different port: `rails server -p 3001`

## 🧰 Tech Stack

```ruby
# Backend
Ruby 3.4.4        # Programming language
Rails 7.2.2       # Web framework
PostgreSQL        # Database
Puma              # Web server

# Frontend
Tailwind CSS      # Utility-first CSS framework
Hotwire           # Turbo + Stimulus
ViewComponent     # View components for Rails
Chart.js          # Data visualization library
Chartkick         # Charts for Rails

# Authentication & Authorization
Devise            # Authentication solution
Pundit            # Authorization system

# JavaScript
Importmap         # ES module import maps (no bundler required)
Stimulus          # JavaScript framework
Turbo             # SPA-like page accelerator

# Additional Tools
Kaminari          # Pagination
Sprockets         # Asset pipeline
RSpec             # Testing framework
Factory Bot       # Test data generation
RuboCop           # Code style and quality linter
Lookbook          # Component previews (development)
