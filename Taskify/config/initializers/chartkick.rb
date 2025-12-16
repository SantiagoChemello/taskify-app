# Chartkick configuration
Chartkick.options = {
  height: "300px",
  colors: [ "#3B82F6", "#10B981", "#F59E0B", "#EF4444", "#8B5CF6" ],
  library: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: "bottom",
        labels: {
          usePointStyle: true,
          padding: 20,
          font: {
            size: 12,
            family: "Inter, system-ui, sans-serif"
          }
        }
      }
    },
    scales: {
      y: {
        beginAtZero: true,
        grid: {
          color: "rgba(0, 0, 0, 0.1)"
        },
        ticks: {
          font: {
            family: "Inter, system-ui, sans-serif"
          }
        }
      },
      x: {
        grid: {
          display: false
        },
        ticks: {
          font: {
            family: "Inter, system-ui, sans-serif"
          }
        }
      }
    }
  }
}
