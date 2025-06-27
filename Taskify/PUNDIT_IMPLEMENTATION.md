# Pundit Authorization Implementation

This document outlines the complete Pundit authorization system implemented in the Taskify application.

## Overview

Pundit has been integrated throughout the application to handle all authorization logic, replacing the previous manual authorization methods. The system provides role-based access control with three user roles:

- **Admin**: Full system access
- **Task Maker**: Can create and manage tasks
- **Task Doer**: Can complete assigned tasks

## Configuration

### ApplicationController
- Includes `Pundit::Authorization`
- Implements `verify_authorized` and `verify_policy_scoped` checks
- Handles `Pundit::NotAuthorizedError` exceptions
- Skips authorization for dashboard, statistics, settings, and home controllers

### User Roles
- `admin`: Full access to all resources
- `task_maker`: Can create tasks and assign them
- `task_doer`: Can complete assigned tasks

## Policies Implemented

### ApplicationPolicy (Base Policy)
- Default deny-all policy
- All other policies inherit from this
- Includes base Scope class

### TaskPolicy
**Permissions:**
- `index?`: Any authenticated user
- `show?`: Uses Task model's `can_be_viewed_by?` method
- `create?`: Admin and Task Makers only
- `update?/edit?`: Uses Task model's `can_be_edited_by?` method
- `destroy?`: Same as update
- `assign?`: Admin (any task), Task Makers (own tasks only)
- `complete?`: 
  - Admin: Any task
  - Task Maker: Own tasks or assigned tasks
  - Task Doer: Only assigned tasks

**Scope:**
- Uses Task model's `visible_to_user(user)` scope

### UserPolicy
**Permissions:**
- `index?`: Admin only
- `show?`: Admin or own profile
- `create?`: Admin only
- `update?/edit?`: Admin or own profile
- `destroy?`: Admin only (cannot delete self)
- `manage_roles?`: Admin only
- `assign_tasks?`: Admin and Task Makers
- `edit_profile?`: Admin or own profile

**Scope:**
- Admin: All users
- Others: Only own user record

### DashboardPolicy
**Permissions:**
- `index?`: Any authenticated user

## Controller Updates

### TasksController
- Replaced all manual authorization with Pundit calls
- Uses `policy_scope(Task)` for index actions
- Uses `authorize @task` for individual actions
- Uses `authorize @task, :assign?` for assignment
- Uses `authorize @task, :complete?` for completion

### UsersController
- Replaced `authorize_admin!` with Pundit calls
- Uses `authorize User` for index
- Uses `authorize @user` for individual actions
- Uses `policy_scope(User)` for user listing

## Helper Methods

### can_assign_task?(task)
- Updated to use `policy(task).assign?`
- Available in views for conditional display

## Authorization Flow

1. **Request arrives** → Controller action called
2. **Policy check** → `authorize resource` or `authorize resource, :action?`
3. **Policy evaluation** → Checks user role and resource ownership
4. **Success** → Action proceeds
5. **Failure** → `Pundit::NotAuthorizedError` raised → User redirected with error message

## Policy Verification

The application includes Pundit's built-in verification:
- `verify_authorized`: Ensures every action has authorization
- `verify_policy_scoped`: Ensures index actions use policy scopes
- Skipped for controllers that don't need authorization (dashboard, settings, etc.)

## Error Handling

- `Pundit::NotAuthorizedError` is caught and handled gracefully
- Users see "No tienes permisos para realizar esta acción" message
- Redirected to appropriate fallback location

## Benefits of Pundit Implementation

1. **Centralized Authorization**: All authorization logic in policy classes
2. **Testable**: Policies can be unit tested independently
3. **Consistent**: Same authorization patterns across the application
4. **Maintainable**: Easy to modify permissions in one place
5. **Secure**: Automatic verification ensures no unauthorized actions

## Usage Examples

### In Controllers
```ruby
# Index with scope
@tasks = policy_scope(Task).includes(:user, :assignee)

# Standard authorization
authorize @task

# Specific action authorization
authorize @task, :assign?
```

### In Views
```erb
<% if policy(@task).assign? %>
  <!-- Assignment form -->
<% end %>

<% if can_assign_task?(@task) %>
  <!-- Helper method usage -->
<% end %>
```

### Testing Policies
```ruby
# In specs
let(:policy) { TaskPolicy.new(user, task) }
expect(policy.show?).to be_truthy
```

## Future Enhancements

- Add more granular permissions as needed
- Implement resource-specific scopes
- Add policy caching for performance
- Create custom policy methods for complex authorization rules 