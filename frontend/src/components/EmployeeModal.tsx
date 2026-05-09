import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { employeeApi } from "../lib/api";
import type { Employee } from "../lib/api";
import {
  employeeSchema,
  type EmployeeFormValues,
  CURRENCIES,
  EMPLOYMENT_TYPES,
  JOB_TITLES,
  DEPARTMENTS,
  COUNTRIES,
} from "../lib/schemas";

interface Props {
  employee?: Employee | null;
  onClose: () => void;
}

function Field({
  label,
  error,
  children,
  fullWidth = false,
  required = false,
}: {
  label: string;
  error?: string;
  children: React.ReactNode;
  fullWidth?: boolean;
  required?: boolean;
}) {
  return (
    <div className={fullWidth ? "col-span-2" : ""}>
      <label className="block text-xs font-medium text-gray-400 mb-1">
        {label}
        {required && <span className="text-red-400 ml-0.5">*</span>}
      </label>
      {children}
      {error && <p className="text-red-400 text-xs mt-1">{error}</p>}
    </div>
  );
}

const selectCls =
  "w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-violet-500";
const inputCls = selectCls;

export default function EmployeeModal({ employee, onClose }: Props) {
  const qc = useQueryClient();
  const isEdit = !!employee;

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<EmployeeFormValues>({
    resolver: zodResolver(employeeSchema),
    defaultValues: { currency: "USD", employment_type: "full_time" },
  });

  useEffect(() => {
    if (employee) {
      reset({
        full_name:       employee.full_name,
        email:           employee.email,
        job_title:       employee.job_title,
        department:      employee.department,
        country:         employee.country,
        salary:          employee.salary,
        currency:        employee.currency as EmployeeFormValues["currency"],
        employment_type: employee.employment_type,
        hired_on:        employee.hired_on,
      });
    }
  }, [employee, reset]);

  const mutation = useMutation({
    mutationFn: (data: EmployeeFormValues) =>
      isEdit
        ? employeeApi.update(employee!.id, data as Partial<Omit<Employee, "id">>)
        : employeeApi.create(data as Omit<Employee, "id">),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["employees"] });
      onClose();
    },
  });

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
      <div className="bg-gray-900 border border-gray-700 rounded-2xl w-full max-w-lg shadow-2xl max-h-[90vh] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-800 shrink-0">
          <h2 className="text-lg font-semibold text-white">
            {isEdit ? "Edit Employee" : "Add Employee"}
          </h2>
          <button onClick={onClose} className="text-gray-400 hover:text-white text-2xl leading-none">×</button>
        </div>

        {/* Scrollable form */}
        <form
          onSubmit={handleSubmit((d) => mutation.mutate(d))}
          className="px-6 py-5 space-y-4 overflow-y-auto"
        >
          <div className="grid grid-cols-2 gap-4">
            {/* Text inputs */}
            <Field label="Full Name" error={errors.full_name?.message} fullWidth required>
              <input
                {...register("full_name")}
                className={inputCls}
                required
                placeholder="Jane Smith"
              />
            </Field>

            <Field label="Email" error={errors.email?.message} fullWidth required>
              <input
                {...register("email")}
                type="email"
                className={inputCls}
                required
                placeholder="jane@example.com"
              />
            </Field>

            {/* Salary + Hired On */}
            <Field label="Salary" error={errors.salary?.message} required>
              <input
                {...register("salary", { valueAsNumber: true })}
                type="number"
                min={1}
                max={9_999_999}
                className={inputCls}
                required
                placeholder="90000"
              />
            </Field>

            <Field label="Hired On" error={errors.hired_on?.message} required>
              <input
                {...register("hired_on")}
                type="date"
                className={inputCls}
                required
                max={new Date().toISOString().split("T")[0]}
              />
            </Field>

            {/* ── Dropdowns populated from constants.json (YAML on backend) ── */}
            <Field label="Job Title" error={errors.job_title?.message} required>
              <select {...register("job_title")} className={selectCls} required defaultValue="">
                <option value="" disabled>— Select —</option>
                {JOB_TITLES.map((t) => (
                  <option key={t} value={t}>{t}</option>
                ))}
              </select>
            </Field>

            <Field label="Department" error={errors.department?.message} required>
              <select {...register("department")} className={selectCls} required defaultValue="">
                <option value="" disabled>— Select —</option>
                {DEPARTMENTS.map((d) => (
                  <option key={d} value={d}>{d}</option>
                ))}
              </select>
            </Field>

            <Field label="Country" error={errors.country?.message} required>
              <select {...register("country")} className={selectCls} required defaultValue="">
                <option value="" disabled>— Select —</option>
                {COUNTRIES.map((c) => (
                  <option key={c} value={c}>{c}</option>
                ))}
              </select>
            </Field>

            <Field label="Currency" error={errors.currency?.message} required>
              <select {...register("currency")} className={selectCls} required>
                {CURRENCIES.map((c) => (
                  <option key={c} value={c}>{c}</option>
                ))}
              </select>
            </Field>

            <Field label="Employment Type" error={errors.employment_type?.message} fullWidth required>
              <select {...register("employment_type")} className={selectCls} required>
                {EMPLOYMENT_TYPES.map(({ value, label }) => (
                  <option key={value} value={value}>{label}</option>
                ))}
              </select>
            </Field>
          </div>

          {/* Required field legend */}
          <p className="text-xs text-gray-500">
            <span className="text-red-400">*</span> Required fields
          </p>

          {mutation.isError && (
            <p className="text-red-400 text-sm bg-red-950/40 border border-red-800 rounded-lg px-3 py-2">
              Something went wrong. Please check your inputs and try again.
            </p>
          )}

          <div className="flex justify-end gap-3 pt-2 shrink-0">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 rounded-lg text-sm text-gray-400 hover:text-white hover:bg-gray-800"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={mutation.isPending}
              className="px-5 py-2 rounded-lg text-sm font-medium bg-violet-600 hover:bg-violet-500 text-white disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {mutation.isPending ? "Saving…" : isEdit ? "Save Changes" : "Add Employee"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
