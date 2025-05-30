local API = require("api")

-- CONFIG is automatically injected when user has configured the script
if CONFIG then
    print("\n--- All CONFIG keys and values ---")
    for key, value in pairs(CONFIG) do
        print(tostring(key) .. ": " .. tostring(value))
    end
    print("---------------------------------")
end

while (API.Read_LoopyLoop()) do

end
