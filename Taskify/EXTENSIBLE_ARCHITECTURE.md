# 🏗️ Arquitectura Extensible con Concerns

## 📋 Resumen Ejecutivo

Esta arquitectura utiliza **Rails Concerns** para crear un sistema modular, escalable y mantenible que permite agregar nuevas funcionalidades sin modificar el código base existente.

## 🧩 **¿Qué son los Concerns?**

Los **Concerns** son módulos Ruby que:
- Agrupan funcionalidad relacionada de manera coherente
- Pueden ser incluidos en múltiples modelos
- Mantienen el código DRY (Don't Repeat Yourself)
- Facilitan el testing independiente
- Mejoran la organización del código

## 🎯 **Ventajas de esta Arquitectura**

### ✅ **Modularidad**
```ruby
# Cada funcionalidad es independiente
include Categorizable    # Sistema de categorías
include Notifiable       # Sistema de notificaciones  
include Auditable        # Sistema de auditoría
```

### ✅ **Reutilización**
```ruby
# Los mismos concerns pueden usarse en diferentes modelos
class Task < ApplicationRecord
  include Notifiable
end

class Project < ApplicationRecord
  include Notifiable  # Misma funcionalidad, diferentes contextos
end
```

### ✅ **Mantenibilidad**
- Cambios en un concern afectan a todos los modelos que lo usan
- Testing independiente de cada funcionalidad
- Fácil desactivación de funcionalidades

### ✅ **Escalabilidad**
- Agregar nuevas funcionalidades sin tocar código existente
- Configuración por modelo
- Performance optimizada

## 🚀 **Funcionalidades Implementadas**

### 1. **Sistema de Categorías (`Categorizable`)**

#### Características:
- **Categorías múltiples por tarea**
- **Colores automáticos**
- **Estadísticas de uso**
- **Filtrado por categoría**

#### Uso:
```ruby
# Agregar categoría
task.add_category("trabajo", user: current_user)

# Obtener categorías populares
Task.popular_categories(limit: 5)

# Filtrar por categoría
Task.with_category("personal")
```

#### Datos que se almacenan:
- Nombre de categoría (normalizado)
- Color hexadecimal
- Prioridad de visualización
- Usuario que creó la categoría
- Estadísticas de uso

### 2. **Sistema de Notificaciones (`Notifiable`)**

#### Tipos de Notificaciones:
- ✉️ **task_assigned**: Asignación de tareas
- ✅ **task_completed**: Tareas completadas
- ⚠️ **task_overdue**: Tareas vencidas
- ⏰ **task_due_soon**: Tareas próximas a vencer
- ✏️ **task_updated**: Cambios en tareas
- 🗑️ **task_deleted**: Tareas eliminadas
- 📅 **deadline_reminder**: Recordatorios
- 📊 **weekly_summary**: Resúmenes semanales

#### Canales de Notificación:
- **Tiempo Real**: ActionCable/WebSockets
- **Email**: Mailers con colas de trabajo
- **In-App**: Notificaciones en la interfaz

#### Uso:
```ruby
# Notificación manual
task.notify_assignee(:task_assigned, custom_message: "Nueva tarea urgente")

# Notificación automática (via callbacks)
task.update!(assignee: new_user)  # Auto-notifica

# Configuración por usuario
user.should_receive_notification?(:task_overdue)
```

### 3. **Sistema de Auditoría (`Auditable`)**

#### Características:
- **Rastreo automático** de todos los cambios
- **Configuración granular** de qué auditar
- **Historial completo** con metadata
- **Análisis de actividad**

#### Datos Auditados:
```ruby
# Configurar qué atributos auditar
audit_attributes :title, :description, :status, :assignee_id

# Datos almacenados automáticamente:
{
  action: 'update',
  changes_data: {
    'assignee_id' => { from: nil, to: 5 },
    'status' => { from: 'pending', to: 'completed' }
  },
  user: current_user,
  ip_address: '192.168.1.100',
  user_agent: 'Mozilla/5.0...',
  performed_at: '2024-01-15T10:30:00Z'
}
```

#### Consultas Útiles:
```ruby
# Historial de una tarea
task.audit_history(limit: 20)

# Quién cambió qué
task.who_changed_what(:assignee_id)

# Análisis de actividad
task.change_summary
# => {
#   total_changes: 15,
#   last_change: 2024-01-15,
#   change_frequency: 2.3,
#   most_active_user: User<id: 3>
# }
```

## 🔧 **Cómo Extender el Sistema**

### **Ejemplo 1: Agregar Sistema de Comentarios**

```ruby
# app/models/concerns/commentable.rb
module Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, as: :commentable, dependent: :destroy
    
    after_create :notify_about_new_comment, if: :should_notify_comments?
  end

  def add_comment(content, user:)
    comments.create!(
      content: content,
      user: user,
      created_at: Time.current
    )
  end

  def latest_comments(limit: 5)
    comments.includes(:user).order(created_at: :desc).limit(limit)
  end
end

# Uso en el modelo
class Task < ApplicationRecord
  include Commentable  # ¡Nueva funcionalidad agregada!
end
```

### **Ejemplo 2: Sistema de Archivos Adjuntos**

```ruby
module Attachable
  extend ActiveSupport::Concern

  included do
    has_many_attached :files
    
    validates :files, content_type: { 
      in: %w[image/jpeg image/png application/pdf text/plain],
      message: 'debe ser una imagen, PDF o texto'
    }
  end

  def attach_file(file, user:)
    files.attach(file)
    audit_changes(action: 'file_attached', user: user)
  end

  def total_file_size
    files.sum { |file| file.byte_size }
  end
end
```

### **Ejemplo 3: Sistema de Etiquetas (Tags)**

```ruby
module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings
  end

  def tag_with(tag_names, user: nil)
    tag_names.each do |name|
      tag = Tag.find_or_create_by(name: name.strip.downcase)
      tags << tag unless tags.include?(tag)
    end
    
    audit_changes(action: 'tags_updated', user: user)
  end

  def remove_tag(tag_name)
    tag = tags.find_by(name: tag_name.strip.downcase)
    tags.delete(tag) if tag
  end
end
```

## 📊 **Migraciones Necesarias**

### **Para Categorías**
```ruby
# db/migrate/create_categories.rb
class CreateCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false, index: { unique: true }
      t.string :color, default: '#6b7280'
      t.integer :priority, default: 0
      t.boolean :active, default: true
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.timestamps
    end

    create_table :task_categories do |t|
      t.references :task, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.timestamps
    end

    add_index :task_categories, [:task_id, :category_id], unique: true
  end
end
```

### **Para Notificaciones**
```ruby
# db/migrate/create_notifications.rb
class CreateNotifications < ActiveRecord::Migration[7.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :notifiable, polymorphic: true, null: false
      t.string :notification_type, null: false
      t.text :message, null: false
      t.json :data, default: {}
      t.boolean :read, default: false
      t.datetime :read_at
      t.timestamps
    end

    add_index :notifications, [:user_id, :read]
    add_index :notifications, [:notifiable_type, :notifiable_id]
    add_index :notifications, :notification_type
  end
end
```

### **Para Auditoría**
```ruby
# db/migrate/create_audit_logs.rb
class CreateAuditLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :audit_logs do |t|
      t.references :user, foreign_key: true, null: true
      t.references :auditable, polymorphic: true, null: false
      t.string :action, null: false
      t.json :changes_data, default: {}
      t.json :details, default: {}
      t.string :ip_address
      t.text :user_agent
      t.datetime :performed_at, null: false
    end

    add_index :audit_logs, [:auditable_type, :auditable_id]
    add_index :audit_logs, :performed_at
    add_index :audit_logs, [:user_id, :performed_at]
  end
end
```

## 🎛️ **Configuración y Personalización**

### **Configuración Global**
```ruby
# config/application.rb
config.x.notifications.cleanup_days = 30
config.x.notifications.batch_size = 100
config.x.audit.retention_days = 365
config.x.categories.max_per_task = 5
```

### **Configuración por Usuario**
```ruby
# Agregar a User model
class User < ApplicationRecord
  def notification_preferences
    @notification_preferences ||= {
      email_notifications: true,
      real_time_notifications: true,
      weekly_summary: true,
      task_reminders: true
    }
  end

  def should_receive_notification?(type)
    notification_preferences[type.to_sym] != false
  end
end
```

## 🧪 **Testing de Concerns**

### **Ejemplo de Spec para Notifiable**
```ruby
# spec/concerns/notifiable_spec.rb
RSpec.shared_examples 'notifiable' do
  let(:model) { described_class }
  let(:instance) { create(model.to_s.underscore.to_sym) }

  describe '#notify_users' do
    it 'creates notifications for specified users' do
      users = create_list(:user, 2)
      
      expect {
        instance.notify_users(users, :task_assigned)
      }.to change(Notification, :count).by(2)
    end
  end

  describe 'callbacks' do
    it 'sends notification on creation' do
      expect {
        create(model.to_s.underscore.to_sym, assignee: create(:user))
      }.to change(Notification, :count).by(1)
    end
  end
end

# En el spec del modelo
RSpec.describe Task, type: :model do
  it_behaves_like 'notifiable'
end
```

## 🚦 **Performance y Optimización**

### **Consultas Optimizadas**
```ruby
# Uso de includes para evitar N+1
Task.includes(:categories, :notifications, :audit_logs)
    .with_category('trabajo')
    .limit(10)

# Caché de consultas frecuentes
def popular_categories_cached
  Rails.cache.fetch('popular_categories', expires_in: 1.hour) do
    Category.popular.limit(10).to_a
  end
end
```

### **Jobs en Background**
```ruby
# app/jobs/notification_cleanup_job.rb
class NotificationCleanupJob < ApplicationJob
  def perform(days = 30)
    Notification.cleanup_old_notifications(days: days)
  end
end

# Programar limpieza automática
# config/schedule.rb (usando whenever gem)
every 1.day, at: '2:00 am' do
  runner "NotificationCleanupJob.perform_later"
end
```

## 🔮 **Futuras Extensiones Posibles**

1. **Sistema de Workflows**
   - Estados personalizados
   - Transiciones automáticas
   - Aprobaciones por roles

2. **Integración con APIs Externas**
   - Slack/Teams notifications
   - Calendar sync
   - Email providers

3. **Análisis Avanzado**
   - Métricas de productividad
   - Reportes automáticos
   - Dashboards personalizados

4. **Sistema de Plantillas**
   - Tareas recurrentes
   - Proyectos predefinidos
   - Automatización

## 💡 **Conclusión**

Esta arquitectura con concerns proporciona:

- ✅ **Flexibilidad**: Fácil agregar/quitar funcionalidades
- ✅ **Mantenibilidad**: Código organizado y testeable
- ✅ **Escalabilidad**: Soporta crecimiento del sistema
- ✅ **Reutilización**: Concerns aplicables a múltiples modelos
- ✅ **Performance**: Optimizado para consultas complejas

El sistema está preparado para crecer y adaptarse a nuevos requerimientos sin comprometer la calidad del código existente. 