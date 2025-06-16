# Taskify: Una aplicación de gestión de tareas

Taskify es una aplicación web minimalista y elegante para gestionar tus tareas diarias. Diseñada para ser simple pero potente, te ayuda a organizar tus actividades personales y profesionales de manera eficiente, sin complicaciones innecesarias.

## Algunas características de Taskify

- 📝 Organiza tus tareas de forma intuitiva y visual
- 🎯 Establece prioridades y fechas límite fácilmente
- 👥 Colabora con tu equipo en tiempo real
- 📱 Accede desde cualquier dispositivo, en cualquier momento
- 🎨 Interfaz limpia y minimalista que no distrae
- 🔔 Notificaciones inteligentes para no perder nada importante

## Configuración Local

### Requisitos

- Ruby 3.4.4
- PostgreSQL 14 o superior
- Node.js 18 o superior
- Yarn

### Instalación Rápida

```bash
# 1. Clona el repositorio
git clone https://github.com/SantiagoChemello/taskify_app.git
cd taskify

# 2. Instala las dependencias
bundle install
yarn install

# 3. Configura la base de datos
rails db:create
rails db:migrate
rails db:seed  # Crea datos iniciales

# 4. Inicia el servidor
rails server
```

La aplicación estará disponible en `http://localhost:3000`
