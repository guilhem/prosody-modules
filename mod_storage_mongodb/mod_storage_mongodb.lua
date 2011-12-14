local next = next;
local setmetatable = setmetatable;

local params = assert ( module:get_option("mongodb") , "mongodb configuration not found" );

local mongo = require "mongo";

local conn

local keyval_store = {};
keyval_store.__index = keyval_store;

function keyval_store:get(username)
	local host = module.host or "_global";
	local store = self.store;

	-- The database name can't have a period in it (hence it can't be a host/ip)
	local namespace = params.dbname .. "." .. host;
	local v = { _id = { store = store ; username = username } };

	local cursor , err = conn:query ( namespace , v );
	if not cursor then return nil , err end;

	local r , err = cursor:next ( );
	if not r then return nil , err end;
	return r.data;
end

function keyval_store:set(username, data)
	local host = module.host or "_global";
	local store = self.store;

	-- The database name can't have a period in it (hence it can't be a host/ip)
	local namespace = params.dbname .. "." .. host;
	local v = { _id = { store = store ; username = username } };

	if next(data) ~= nil then -- set data
		v.data = data;
		return conn:insert ( namespace , v );
	else -- delete data
		return conn:remove ( namespace , v );
	end;
end

local driver = { name = "mongodb" };

function driver:open(store, typ)
	if not conn then
		conn = assert ( mongo.Connection.New ( true ) );
		assert ( conn:connect ( params.server ) );
		assert ( conn:auth ( params ) );
	end

	if not typ then -- default key-value store
		return setmetatable({ store = store }, keyval_store);
	end;
	return nil, "unsupported-store";
end

module:add_item("data-driver", driver);
