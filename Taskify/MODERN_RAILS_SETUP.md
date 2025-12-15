# Modern Rails App Setup - Taskify

This document outlines all the modern Rails gems and configurations integrated into Taskify, inspired by apps like Maybe.

## 🎯 Integrated Gems

### ✅ Authentication & Authorization
- **Devise** - User authentication with roles (`admin`, `task_maker`, `task_doer`)
- **Pundit** - Role-based authorization with comprehensive policies

### ✅ Database & Infrastructure  
- **PostgreSQL** - Configured as primary database
- **Kaminari** - Pagination for task lists

### ✅ Testing & Development
- **RSpec Rails** - Testing framework
- **Factory Bot Rails** - Test data factories
- **Shoulda Matchers** - Additional test matchers
- **Faker** - Realistic test data generation

### ✅ Frontend & UI
- **Tailwind CSS Rails** - Utility-first CSS framework
- **ViewComponent** - Reusable UI components
- **Lookbook** - Component previews and development
- **Chartkick** - Chart visualization with Chart.js

### ✅ Performance & Security
- **Brakeman** - Security vulnerability scanning
- **Rubocop Rails Omakase** - Code style and quality

## 🏗️ Architecture Overview

### User Roles & Permissions
```ruby
# User model with enum roles
enum :role, { admin: 0, task_maker: 1, task_doer: 2 }, default: :task_doer

# Role-based permissions:
# - Admins: Full access to all tasks and users
# - Task Makers: Can create/assign tasks, view own tasks
# - Task Doers: Can only view/work on assigned tasks
```

### ViewComponent Architecture
```
app/components/
├── application_component.rb       # Base component class
├── task_card_component.rb         # Task display cards
├── button_component.rb            # Reusable buttons
├── badge_component.rb             # Status/priority badges
└── previews/                      # Lookbook previews
    ├── button_component_preview.rb
    ├── badge_component_preview.rb
    └── task_card_component_preview.rb
```

### Authorization with Pundit
```
app/policies/
├── application_policy.rb          # Base policy
├── task_policy.rb                 # Task permissions
├── user_policy.rb                 # User management
└── dashboard_policy.rb            # Dashboard access
```

## 🎨 Design System

### Component Design Principles
- **Utility-first** with Tailwind CSS
- **Neutral color palette** (inspired by Maybe/N26)
- **Inter font typography** for readability
- **Responsive design** with mobile-first approach
- **Dark mode support** throughout

### Visual Hierarchy
- **Priority indicators**: Color-coded dots (red/yellow/green)
- **Status badges**: Green for completed, blue for pending
- **Due date cues**: Red for overdue, yellow for today, blue for soon
- **Hover animations**: Subtle scale and shadow effects

## 📊 Statistics & Visualization

### Chartkick Integration
- **Chart.js CDN** integration for rendering
- **Custom configuration** with Inter font family
- **Responsive charts** for task analytics
- **Tailwind color palette** integration

### Available Chart Types
```erb
<!-- Task completion over time -->
<%= line_chart tasks_over_time_data %>

<!-- Priority distribution -->
<%= pie_chart priority_distribution_data %>

<!-- Tasks by category -->
<%= column_chart category_breakdown_data %>
```

## 🔧 Development Tools

### Lookbook Component Previews
Access component library at: `http://localhost:3000/lookbook`

#### Available Previews:
- **Button Component**: All variants, sizes, and states
- **Badge Component**: Priority, status, and role badges  
- **Task Card Component**: Complete task card with interactions

### Component Usage Examples
```erb
<!-- Button Component -->
<%= render ButtonComponent.new(variant: :primary, size: :lg) { "Create Task" } %>

<!-- Badge Component -->
<%= render BadgeComponent.new(text: "High Priority", variant: :priority_high) %>

<!-- Task Card Component -->
<%= render TaskCardComponent.new(task: @task, current_user: current_user, animate_delay: 0.1) %>
```

## 📱 Mobile-First Design

### Responsive Breakpoints
- **sm**: 640px and up
- **md**: 768px and up  
- **lg**: 1024px and up
- **xl**: 1280px and up

### Navigation Patterns
- **Fixed header** with backdrop blur
- **Collapsible mobile menu** 
- **Role-based navigation** items
- **Theme toggle** for dark/light mode

## 🚀 Performance Optimizations

### Database Optimizations
- **PostgreSQL indexes** on frequently queried fields
- **Eager loading** to prevent N+1 queries
- **Pagination** with Kaminari (10 items per page)
- **Scoped queries** for role-based access

### Frontend Optimizations
- **CSS custom properties** for theming
- **Stimulus controllers** for lightweight interactivity
- **Turbo integration** for SPA-like navigation
- **Optimized animations** with CSS keyframes

## 🧪 Testing Strategy

### Test Coverage
- **Unit tests** with RSpec for models and components
- **Integration tests** for controllers and policies
- **System tests** for critical user flows
- **Component tests** for ViewComponent isolation

### Factory Bot Patterns
```ruby
# factories/users.rb
FactoryBot.define do
  factory :user do
    name { Faker::Name.full_name }
    email { Faker::Internet.email }
    role { :task_doer }
    
    trait :admin do
      role { :admin }
    end
    
    trait :task_maker do
      role { :task_maker }
    end
  end
end
```

## 🎯 Next Steps

### Recommended Enhancements
1. **Progressive Web App** features with service workers
2. **Real-time notifications** with Action Cable
3. **Advanced filtering** with search facets
4. **Bulk operations** for task management
5. **Export functionality** for task data
6. **Mobile app** with React Native or Flutter

### Component Library Expansion
1. **Form components** (inputs, selects, checkboxes)
2. **Modal components** for dialogs and confirmations
3. **Navigation components** (breadcrumbs, pagination)
4. **Feedback components** (alerts, toasts, loading states)

---

**Built with ❤️ using modern Rails practices and inspired by Maybe & N26** 