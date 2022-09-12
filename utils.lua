local M = {}

function M.table_to_string(obj)
    local function to_string(o)
        if type(o) == 'table' then
            local s = '{ '
            for k, v in pairs(o) do
                if type(k) ~= 'number' then
                    k = '"' .. k .. '"'
                end
                s = s .. '[' .. k .. '] = ' .. to_string(v) .. ','
            end
            return s .. '} '
        else
            return tostring(o)
        end
    end

    return to_string(obj)
end

return M
