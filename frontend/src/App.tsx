import { NavLink, Outlet } from "react-router-dom";

export default function App() {
  return (
    <div className="min-h-screen bg-gray-950 text-gray-100">
      {/* Top Navigation */}
      <nav className="border-b border-gray-800 bg-gray-900/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-6 flex items-center h-14 gap-8">
          <span className="text-violet-400 font-bold text-lg tracking-tight">
            💼 SalaryTool
          </span>
          <div className="flex gap-1">
            {[
              { to: "/employees", label: "Employees" },
              { to: "/insights", label: "Insights" },
            ].map(({ to, label }) => (
              <NavLink
                key={to}
                to={to}
                className={({ isActive }) =>
                  `px-4 py-1.5 rounded-md text-sm font-medium transition-colors ${
                    isActive
                      ? "bg-violet-600 text-white"
                      : "text-gray-400 hover:text-white hover:bg-gray-800"
                  }`
                }
              >
                {label}
              </NavLink>
            ))}
          </div>
        </div>
      </nav>

      {/* Page content */}
      <main className="max-w-7xl mx-auto px-6 py-8">
        <Outlet />
      </main>
    </div>
  );
}
