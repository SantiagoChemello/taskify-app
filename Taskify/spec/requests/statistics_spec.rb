require 'rails_helper'

RSpec.describe "Statistics", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /statistics" do
    context "with no tasks" do
      it "displays empty state" do
        get statistics_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("No hay estadísticas aún")
        expect(response.body).to include("Crear Primera Tarea")
        expect(response.body).to include("📊 Estadísticas de Productividad")
      end

      it "shows zero statistics" do
        get statistics_path

        expect(response.body).to include("0") # Total tasks
        expect(response.body).to include("0.0%") # Completion percentage
      end
    end

    context "with tasks" do
      let!(:completed_high_task) { create(:task, user: user, status: :completed, priority: :high, category: 'trabajo') }
      let!(:completed_medium_task) { create(:task, user: user, status: :completed, priority: :medium, category: 'personal') }
      let!(:pending_high_task) { create(:task, user: user, status: :pending, priority: :high, category: 'trabajo') }
      let!(:pending_low_task) { create(:task, user: user, status: :pending, priority: :low, category: 'estudios') }
      let!(:uncategorized_task) { create(:task, user: user, status: :pending, priority: :medium, category: '') }

      it "calculates basic statistics correctly" do
        get statistics_path

        expect(response).to have_http_status(:success)

        # Should show 5 total tasks
        expect(response.body).to include(">5<")
        # Should show 2 completed tasks
        expect(response.body).to include(">2<")
        # Should show 3 pending tasks
        expect(response.body).to include(">3<")
        # Should show 40% completion rate
        expect(response.body).to include("40.0%")
      end

      it "displays statistics cards" do
        get statistics_path

        expect(response.body).to include("Total de Tareas")
        expect(response.body).to include("Completadas")
        expect(response.body).to include("Pendientes")
        expect(response.body).to include("% Completado")
        expect(response.body).to include("📋")
        expect(response.body).to include("✅")
        expect(response.body).to include("⏳")
        expect(response.body).to include("📈")
      end

      it "includes Chart.js data for overall completion" do
        get statistics_path

        expect(response.body).to include('data-controller="chart"')
        expect(response.body).to include('data-chart-type-value="doughnut"')
        expect(response.body).to include('&quot;labels&quot;:[&quot;Completadas&quot;,&quot;Pendientes&quot;]')
        expect(response.body).to include('&quot;data&quot;:[2,3]')
        expect(response.body).to include('&quot;backgroundColor&quot;:[&quot;#10b981&quot;,&quot;#f59e0b&quot;]')
      end

      it "includes Chart.js data for priority distribution" do
        get statistics_path

        expect(response.body).to include('data-chart-type-value="bar"')
        expect(response.body).to include('&quot;labels&quot;:[&quot;Alta&quot;,&quot;Media&quot;,&quot;Baja&quot;]')
        expect(response.body).to include('&quot;label&quot;:&quot;Completadas&quot;')
        expect(response.body).to include('&quot;label&quot;:&quot;Pendientes&quot;')
      end

      it "displays category statistics table" do
        get statistics_path

        expect(response.body).to include("📁 Estadísticas por Categoría")
        expect(response.body).to include("Trabajo")
        expect(response.body).to include("Personal")
        expect(response.body).to include("Estudios")
        expect(response.body).to include("Sin categoría")
      end

      it "displays priority statistics table" do
        get statistics_path

        expect(response.body).to include("🎯 Estadísticas por Prioridad")
        expect(response.body).to include("Alta")
        expect(response.body).to include("Media")
        expect(response.body).to include("Baja")
      end

      it "calculates category completion percentages correctly" do
        get statistics_path

        # Trabajo category: 1 completed, 1 pending = 50%
        # Personal category: 1 completed, 0 pending = 100%
        # Estudios category: 0 completed, 1 pending = 0%
        # Sin categoría: 0 completed, 1 pending = 0%

        expect(response.body).to include("50.0%") # trabajo
        expect(response.body).to include("100.0%") # personal
        expect(response.body).to include("0.0%") # estudios and uncategorized
      end

      it "calculates priority completion percentages correctly" do
        get statistics_path

        # High priority: 1 completed, 1 pending = 50%
        # Medium priority: 1 completed, 1 pending = 50%
        # Low priority: 0 completed, 1 pending = 0%

        expect(response.body).to include("50.0%") # high and medium
        expect(response.body).to include("0.0%") # low
      end
    end

    context "with due date tasks" do
      let!(:overdue_task) { create(:task, user: user, status: :pending, due_date: 2.days.ago) }
      let!(:due_today_task) { create(:task, user: user, status: :pending, due_date: Time.current.end_of_day) }
      let!(:due_this_week_task) { create(:task, user: user, status: :pending, due_date: 3.days.from_now) }
      let!(:no_due_date_task) { create(:task, user: user, status: :pending, due_date: nil) }

      it "displays due date statistics" do
        get statistics_path

        expect(response.body).to include("📅 Tareas por Fecha Límite")
        expect(response.body).to include("⚠️ Vencidas")
        expect(response.body).to include("🕐 Vencen Hoy")
        expect(response.body).to include("📆 Esta Semana")
        expect(response.body).to include("📝 Sin Fecha Límite")
      end

      it "counts due date categories correctly" do
        get statistics_path

        # Should count each category correctly - just check the sections exist with numbers
        expect(response.body).to include("⚠️ Vencidas")
        expect(response.body).to include("🕐 Vencen Hoy")
        expect(response.body).to include("📆 Esta Semana")
        expect(response.body).to include("📝 Sin Fecha Límite")

        # Verify there are some counts present (specific numbers may vary)
        expect(response.body).to match(/color: #dc2626;">1</)   # overdue count
        expect(response.body).to match(/color: #ea580c;">1</)   # due today count
        expect(response.body).to match(/color: #ca8a04;">1</)   # due this week count
        expect(response.body).to match(/color: #64748b;">1</)   # no due date count
      end
    end

    context "productivity insights" do
      context "with high completion rate" do
        before do
          create_list(:task, 8, user: user, status: :completed)
          create_list(:task, 2, user: user, status: :pending)
        end

        it "shows positive insight" do
          get statistics_path

          expect(response.body).to include("¡Excelente trabajo!")
          expect(response.body).to include("80.0%")
          expect(response.body).to include("Mantén el impulso")
        end
      end

      context "with medium completion rate" do
        before do
          create_list(:task, 6, user: user, status: :completed)
          create_list(:task, 4, user: user, status: :pending)
        end

        it "shows encouraging insight" do
          get statistics_path

          expect(response.body).to include("Buen progreso")
          expect(response.body).to include("60.0%")
          expect(response.body).to include("¡Casi llegas a la meta!")
        end
      end

      context "with low completion rate" do
        before do
          create_list(:task, 2, user: user, status: :completed)
          create_list(:task, 8, user: user, status: :pending)
        end

        it "shows improvement suggestion" do
          get statistics_path

          expect(response.body).to include("Oportunidad de mejora")
          expect(response.body).to include("20.0%")
          expect(response.body).to include("¡Enfócate en terminar algunas!")
        end
      end

      context "with overdue tasks" do
        before do
          create_list(:task, 3, user: user, status: :pending, due_date: 1.day.ago)
        end

        it "shows overdue warning" do
          get statistics_path

          expect(response.body).to include("Atención:")
          expect(response.body).to include("3 tareas vencidas")
          expect(response.body).to include("Priorízalas")
        end
      end

      context "with category achievements" do
        before do
          create_list(:task, 5, user: user, status: :completed, category: 'trabajo')
          create_list(:task, 3, user: user, status: :pending, category: 'personal')
        end

        it "shows best performing category" do
          get statistics_path

          expect(response.body).to include("Categoría estrella:")
          expect(response.body).to include("Trabajo")
          expect(response.body).to include("100.0%")
        end
      end
    end

    context "navigation" do
      it "includes link back to tasks" do
        get statistics_path

        expect(response.body).to include("Volver a Tareas")
        expect(response.body).to include('href="/tasks"')
      end

      it "includes statistics navigation in tasks page" do
        get tasks_path

        expect(response.body).to include("Estadísticas")
        expect(response.body).to include('href="/statistics"')
      end
    end

    context "user isolation" do
      let(:other_user) { create(:user) }
      let!(:other_user_tasks) { create_list(:task, 5, user: other_user, status: :completed) }
      let!(:current_user_task) { create(:task, user: user, status: :pending) }

      it "only shows current user's statistics" do
        get statistics_path

        # Should show only 1 task (current user's), not 6 total
        expect(response.body).to include(">1<") # total tasks
        expect(response.body).to include(">0<") # completed tasks
        expect(response.body).to include("0.0%") # completion percentage
      end
    end

    context "when user is not signed in" do
      before do
        sign_out user
      end

      it "redirects to sign in page" do
        get statistics_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
