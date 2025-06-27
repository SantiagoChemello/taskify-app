# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create users with different roles
puts "Creating users..."

# Admin user
admin = User.find_or_create_by!(email: 'admin@taskify.com') do |user|
  user.name = 'Admin User'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 'admin'
end

# Task Maker users
task_maker1 = User.find_or_create_by!(email: 'manager@taskify.com') do |user|
  user.name = 'Maria Manager'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 'task_maker'
end

task_maker2 = User.find_or_create_by!(email: 'supervisor@taskify.com') do |user|
  user.name = 'Carlos Supervisor'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 'task_maker'
end

# Task Doer users
task_doer1 = User.find_or_create_by!(email: 'worker1@taskify.com') do |user|
  user.name = 'Ana Worker'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 'task_doer'
end

task_doer2 = User.find_or_create_by!(email: 'worker2@taskify.com') do |user|
  user.name = 'Luis Worker'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = 'task_doer'
end

puts "Created #{User.count} users"

# Create sample tasks with assignments
puts "Creating sample tasks..."

# Tasks created by Task Maker 1 and assigned to Task Doers
task1 = Task.find_or_create_by!(
  title: 'Revisar documentos del proyecto',
  user: task_maker1
) do |task|
  task.description = 'Revisar y validar todos los documentos del proyecto Alpha'
  task.priority = 'high'
  task.category = 'trabajo'
  task.due_date = 2.days.from_now
  task.assignee = task_doer1
end

task2 = Task.find_or_create_by!(
  title: 'Preparar presentación',
  user: task_maker1
) do |task|
  task.description = 'Crear presentación para la reunión del viernes'
  task.priority = 'medium'
  task.category = 'trabajo'
  task.due_date = 3.days.from_now
  task.assignee = task_doer2
end

# Tasks created by Task Maker 2
task3 = Task.find_or_create_by!(
  title: 'Actualizar base de datos',
  user: task_maker2
) do |task|
  task.description = 'Migrar datos del sistema antiguo al nuevo'
  task.priority = 'high'
  task.category = 'trabajo'
  task.due_date = 1.day.from_now
  task.assignee = task_doer1
end

# Unassigned task
task4 = Task.find_or_create_by!(
  title: 'Planificar próximo sprint',
  user: task_maker2
) do |task|
  task.description = 'Definir objetivos y tareas para el próximo sprint'
  task.priority = 'medium'
  task.category = 'trabajo'
  task.due_date = 1.week.from_now
  task.assignee = nil
end

# Admin tasks
task5 = Task.find_or_create_by!(
  title: 'Configurar servidor de respaldo',
  user: admin
) do |task|
  task.description = 'Instalar y configurar el nuevo servidor de respaldo'
  task.priority = 'high'
  task.category = 'trabajo'
  task.due_date = 5.days.from_now
  task.assignee = task_doer2
end

puts "Created #{Task.count} tasks"
puts "Seed data created successfully!"
puts ""
puts "Test accounts:"
puts "Admin: admin@taskify.com / password123"
puts "Task Maker: manager@taskify.com / password123"
puts "Task Maker: supervisor@taskify.com / password123"
puts "Task Doer: worker1@taskify.com / password123"
puts "Task Doer: worker2@taskify.com / password123"
