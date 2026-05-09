import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  flexRender,
  createColumnHelper,
  type SortingState,
} from "@tanstack/react-table";
import { employeeApi, type Employee } from "../lib/api";
import {
  formatSalary,
  formatDate,
  EMPLOYMENT_TYPE_LABELS,
} from "../lib/schemas";
import EmployeeModal from "../components/EmployeeModal";

const col = createColumnHelper<Employee>();

export default function EmployeesPage() {
  const qc = useQueryClient();

  // ── Server-side filter state ─────────────────────────────────────────
  const [search, setSearch] = useState("");
  const [country, setCountry] = useState("");
  const [empType, setEmpType] = useState("");
  const [page, setPage] = useState(1);

  // ── Modal state ──────────────────────────────────────────────────────
  const [modalOpen, setModalOpen] = useState(false);
  const [editEmployee, setEditEmployee] = useState<Employee | null>(null);

  // ── Delete confirm ───────────────────────────────────────────────────
  const [deleteId, setDeleteId] = useState<number | null>(null);

  // ── Client-side sort ─────────────────────────────────────────────────
  const [sorting, setSorting] = useState<SortingState>([]);

  const { data, isLoading } = useQuery({
    queryKey: ["employees", { search, country, empType, page }],
    queryFn: () =>
      employeeApi
        .list({
          search: search || undefined,
          country: country || undefined,
          employment_type: empType || undefined,
          page,
          per_page: 25,
        })
        .then((r) => r.data),
    placeholderData: (prev) => prev,
  });

  const employees: Employee[] = useMemo(
    () =>
      (data?.data ?? []).map((d) => ({
        ...d.attributes,
        id: Number(d.id),
      })),
    [data]
  );

  const meta = data?.meta;

  const deleteMutation = useMutation({
    mutationFn: (id: number) => employeeApi.delete(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["employees"] });
      setDeleteId(null);
    },
  });

  const columns = useMemo(
    () => [
      col.accessor("full_name", { header: "Full Name" }),
      col.accessor("job_title", { header: "Job Title" }),
      col.accessor("department", { header: "Department" }),
      col.accessor("country", { header: "Country" }),
      col.accessor("salary", {
        header: "Salary",
        cell: (info) =>
          formatSalary(info.getValue(), info.row.original.currency),
      }),
      col.accessor("employment_type", {
        header: "Type",
        cell: (info) => EMPLOYMENT_TYPE_LABELS[info.getValue()] ?? info.getValue(),
      }),
      col.accessor("hired_on", {
        header: "Hired On",
        cell: (info) => formatDate(info.getValue()),
      }),
      col.display({
        id: "actions",
        header: "Actions",
        cell: ({ row }) => (
          <div className="flex gap-2">
            <button
              onClick={() => {
                setEditEmployee(row.original);
                setModalOpen(true);
              }}
              className="text-xs px-2 py-1 rounded bg-gray-700 hover:bg-violet-600 text-white transition-colors"
            >
              Edit
            </button>
            <button
              onClick={() => setDeleteId(row.original.id)}
              className="text-xs px-2 py-1 rounded bg-gray-700 hover:bg-red-600 text-white transition-colors"
            >
              Delete
            </button>
          </div>
        ),
      }),
    ],
    []
  );

  const table = useReactTable({
    data: employees,
    columns,
    state: { sorting },
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    manualPagination: true,
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Employees</h1>
          {meta && (
            <p className="text-sm text-gray-400 mt-0.5">
              {meta.total_count.toLocaleString()} total
            </p>
          )}
        </div>
        <button
          onClick={() => {
            setEditEmployee(null);
            setModalOpen(true);
          }}
          className="px-4 py-2 rounded-lg bg-violet-600 hover:bg-violet-500 text-white text-sm font-medium transition-colors"
        >
          + Add Employee
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3">
        <input
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1); }}
          placeholder="Search by name…"
          className="bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-violet-500 w-52"
        />
        <input
          value={country}
          onChange={(e) => { setCountry(e.target.value); setPage(1); }}
          placeholder="Filter by country…"
          className="bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-violet-500 w-48"
        />
        <select
          value={empType}
          onChange={(e) => { setEmpType(e.target.value); setPage(1); }}
          className="bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-violet-500"
        >
          <option value="">All types</option>
          {Object.entries(EMPLOYMENT_TYPE_LABELS).map(([val, label]) => (
            <option key={val} value={val}>{label}</option>
          ))}
        </select>
      </div>

      {/* Table */}
      <div className="rounded-xl border border-gray-800 overflow-hidden">
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
                      {flexRender(header.column.columnDef.header, header.getContext())}
                      {header.column.getIsSorted() === "asc" ? " ↑" : header.column.getIsSorted() === "desc" ? " ↓" : ""}
                    </th>
                  ))}
                </tr>
              ))}
            </thead>
            <tbody className="divide-y divide-gray-800">
              {isLoading ? (
                <tr>
                  <td colSpan={columns.length} className="px-4 py-12 text-center text-gray-500">
                    Loading…
                  </td>
                </tr>
              ) : employees.length === 0 ? (
                <tr>
                  <td colSpan={columns.length} className="px-4 py-12 text-center text-gray-500">
                    No employees found
                  </td>
                </tr>
              ) : (
                table.getRowModel().rows.map((row) => (
                  <tr
                    key={row.id}
                    className="hover:bg-gray-800/40 transition-colors"
                  >
                    {row.getVisibleCells().map((cell) => (
                      <td key={cell.id} className="px-4 py-3 text-gray-200 whitespace-nowrap">
                        {flexRender(cell.column.columnDef.cell, cell.getContext())}
                      </td>
                    ))}
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Pagination */}
      {meta && meta.total_pages > 1 && (
        <div className="flex items-center justify-between text-sm text-gray-400">
          <button
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page === 1}
            className="px-4 py-2 rounded-lg bg-gray-800 hover:bg-gray-700 disabled:opacity-40 transition-colors text-white"
          >
            ← Prev
          </button>
          <span>
            Page {meta.current_page} of {meta.total_pages}
          </span>
          <button
            onClick={() => setPage((p) => Math.min(meta.total_pages, p + 1))}
            disabled={page === meta.total_pages}
            className="px-4 py-2 rounded-lg bg-gray-800 hover:bg-gray-700 disabled:opacity-40 transition-colors text-white"
          >
            Next →
          </button>
        </div>
      )}

      {/* Add/Edit Modal */}
      {modalOpen && (
        <EmployeeModal
          employee={editEmployee}
          onClose={() => {
            setModalOpen(false);
            setEditEmployee(null);
          }}
        />
      )}

      {/* Delete Confirmation */}
      {deleteId !== null && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm">
          <div className="bg-gray-900 border border-gray-700 rounded-2xl p-6 w-full max-w-sm shadow-2xl">
            <h3 className="text-lg font-semibold text-white mb-2">Delete Employee?</h3>
            <p className="text-gray-400 text-sm mb-6">
              This action cannot be undone.
            </p>
            <div className="flex gap-3 justify-end">
              <button
                onClick={() => setDeleteId(null)}
                className="px-4 py-2 rounded-lg text-sm text-gray-400 hover:text-white hover:bg-gray-800"
              >
                Cancel
              </button>
              <button
                onClick={() => deleteMutation.mutate(deleteId)}
                disabled={deleteMutation.isPending}
                className="px-4 py-2 rounded-lg text-sm font-medium bg-red-600 hover:bg-red-500 text-white disabled:opacity-50"
              >
                {deleteMutation.isPending ? "Deleting…" : "Delete"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
