-- Helpers class that provides some basic methods regarding tables
table_helpers = {}

--- table_has_value
-- Checks wether the given table contains the given value
-- @param table The table that should be checked for the given value
-- @param value The value that should be checked for existence in the given table
-- @return true if the table contains the given value, otherwise false
function table_helpers.table_has_value(tab, val)
  for index, value in ipairs(tab) do
      if value == val then
          return true
      end
  end

  return false
end

--- index_for_value_in_table
-- Returns the index of the given value in this table
-- @param value The value for which the index should be returned
-- @param table The table in which the value presumably exists
-- @return The index of the element
function table_helpers.index_for_value_in_table(value,table)
  local index={}
  for k,v in pairs(table) do
    index[v]=k
  end
  return index[value]
end

return table_helpers