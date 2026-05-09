import { useState, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  flexRender,
  createColumnHelper,
  type SortingState,
} from "@tanstack/react-table";
import { insightsApi } from "../lib/api";
import { formatSalary } from "../lib/schemas";

interface JobTitleRow {
  job_title: string;
  min: number;
  max: number;
  avg: number;
  count: number;
}

const col = createColumnHelper<JobTitleRow>();

function StatCard({
  label,
  value,
  accent = "violet",
}: {
  label: string;
  value: string;
  accent?: string;
}) {
  const colors: Record<string, string> = {
    violet: "from-violet-900/40 border-violet-700/50",
    emerald: "from-emerald-900/40 border-emerald-700/50",
    amber: "from-amber-900/40 border-amber-700/50",
    sky: "from-sky-900/40 border-sky-700/50",
  };
  return (
    <div
      className={`bg-gradient-to-br ${colors[accent]} border rounded-xl p-5`}
    >
      <p className="text-xs font-medium text-gray-400 uppercase tracking-wide mb-1">
        {label}
      </p>
      <p className="text-2xl font-bold text-white">{value}</p>
    </div>
  );
}

function SalaryBandChart({ bands }: { bands: { band: string; count: number }[] }) {
  const maxCount = Math.max(...bands.map((b) => b.count), 1);
  return (
    <div className="space-y-2">
      {bands.map((b) => (
        <div key={b.band} className="flex items-center gap-3 text-sm">
          <span className="text-gray-400 w-28 shrink-0 text-right">{b.band}</span>
          <div className="flex-1 bg-gray-800 rounded-full h-5 overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-violet-600 to-indigo-500 rounded-full transition-all duration-500"
              style={{ width: `${(b.count / maxCount) * 100}%` }}
            />
          </div>
          <span className="text-gray-300 w-12 text-right">{b.count}</span>
        </div>
      ))}
    </div>
  );
}

export default function InsightsPage() {
  const [selectedCountry, setSelectedCountry] = useState("");
  const [sorting, setSorting] = useState<SortingState>([]);

  const { data: countriesData } = useQuery({
    queryKey: ["insight-countries"],
    queryFn: () => insightsApi.countries().then((r) => r.data),
  });

  const countries = countriesData?.countries ?? [];

  const { data: insights, isLoading } = useQuery({
    queryKey: ["insights", selectedCountry],
    queryFn: () => insightsApi.get(selectedCountry).then((r) => r.data),
    enabled: !!selectedCountry,
  });

  const jobRows: JobTitleRow[] = useMemo(
    () => insights?.by_job_title ?? [],
    [insights]
  );

  const columns = useMemo(
    () => [
      col.accessor("job_title", { header: "Job Title" }),
      col.accessor("avg", {
        header: "Avg Salary",
        cell: (info) => formatSalary(info.getValue()),
      }),
      col.accessor("min", {
        header: "Min",
        cell: (info) => formatSalary(info.getValue()),
      }),
      col.accessor("max", {
        header: "Max",
        cell: (info) => formatSalary(info.getValue()),
      }),
      col.accessor("count", { header: "Headcount" }),
    ],
    []
  );

  const table = useReactTable({
    data: jobRows,
    columns,
    state: { sorting },
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
  });

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-white">Salary Insights</h1>
        <p className="text-gray-400 text-sm mt-1">
          Select a country to explore salary data
        </p>
      </div>

      {/* Country Selector */}
      <div className="flex items-center gap-3">
        <label className="text-sm text-gray-400 font-medium">Country</label>
        <select
          value={selectedCountry}
          onChange={(e) => setSelectedCountry(e.target.value)}
          className="bg-gray-800 border border-gray-700 rounded-lg px-4 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-violet-500 min-w-48"
        >
          <option value="">— Select country —</option>
          {countries.map((c) => (
            <option key={c} value={c}>{c}</option>
          ))}
        </select>
      </div>

      {/* Content */}
      {!selectedCountry && (
        <div className="text-center py-24 text-gray-600">
          <div className="text-5xl mb-4">📊</div>
          <p className="text-lg">Select a country to view salary insights</p>
        </div>
      )}

      {selectedCountry && isLoading && (
        <div className="text-center py-16 text-gray-500">Loading…</div>
      )}

      {insights && !isLoading && (
        <div className="space-y-8">
          {/* Stat Cards */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <StatCard
              label="Headcount"
              value={insights.overall.count.toLocaleString()}
              accent="sky"
            />
            <StatCard
              label="Min Salary"
              value={formatSalary(insights.overall.min)}
              accent="emerald"
            />
            <StatCard
              label="Max Salary"
              value={formatSalary(insights.overall.max)}
              accent="amber"
            />
            <StatCard
              label="Avg Salary"
              value={formatSalary(insights.overall.avg)}
              accent="violet"
            />
          </div>

          {/* Job Title Breakdown */}
          <div className="rounded-xl border border-gray-800 overflow-hidden">
            <div className="px-5 py-4 border-b border-gray-800 bg-gray-800/40">
              <h2 className="text-sm font-semibold text-white">
                Salary by Job Title
              </h2>
              <p className="text-xs text-gray-500 mt-0.5">
                Click column headers to sort
              </p>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-gray-800/60">
                  {table.getHeaderGroups().map((hg) => (
                    <tr key={hg.id}>
                      {hg.headers.map((header) => (
                        <th
                          key={header.id}
                          onClick={header.column.getToggleSortingHandler()}
                          className="px-4 py-3 text-left text-xs font-semibold text-gray-400 uppercase tracking-wide cursor-pointer select-none hover:text-white transition-colors"
                        >
                          {flexRender(
                            header.column.columnDef.header,
                            header.getContext()
                          )}
                          {header.column.getIsSorted() === "asc"
                            ? " ↑"
                            : header.column.getIsSorted() === "desc"
                            ? " ↓"
                            : ""}
                        </th>
                      ))}
                    </tr>
                  ))}
                </thead>
                <tbody className="divide-y divide-gray-800">
                  {table.getRowModel().rows.map((row) => (
                    <tr
                      key={row.id}
                      className="hover:bg-gray-800/40 transition-colors"
                    >
                      {row.getVisibleCells().map((cell) => (
                        <td
                          key={cell.id}
                          className="px-4 py-3 text-gray-200 whitespace-nowrap"
                        >
                          {flexRender(
                            cell.column.columnDef.cell,
                            cell.getContext()
                          )}
                        </td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Salary Band Chart */}
          {insights.salary_bands.length > 0 && (
            <div className="rounded-xl border border-gray-800 p-5 bg-gray-900/40">
              <h2 className="text-sm font-semibold text-white mb-4">
                Salary Band Distribution
              </h2>
              <SalaryBandChart bands={insights.salary_bands} />
            </div>
          )}
        </div>
      )}
    </div>
  );
}
