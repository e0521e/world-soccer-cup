--!strict

-- Admin UserIds — players with GM button access
local AdminData = {
	AdminIds = {
		6053628054, -- Replace with actual admin UserIds
		3073413856,
	},
}

function AdminData.IsAdmin(userId: number): boolean
	for _, id in ipairs(AdminData.AdminIds) do
		if id == userId then return true end
	end
	return false
end

return AdminData
