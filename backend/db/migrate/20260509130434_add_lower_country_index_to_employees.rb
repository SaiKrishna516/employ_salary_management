class AddLowerCountryIndexToEmployees < ActiveRecord::Migration[7.1]
  # The by_country scope uses WHERE LOWER(country) = ?, which cannot use
  # a plain B-tree index on the country column. This expression index makes
  # that filter O(log n) instead of a full sequential scan.
  def change
    add_index :employees,
              "LOWER(country)",
              name: "index_employees_on_lower_country"
  end
end
