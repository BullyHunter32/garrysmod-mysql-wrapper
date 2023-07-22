Rust.MySQL = Rust.MySQL or {
    Database = false,
}

local credentials = {
    Host = "localhost",
    Username = "",
    Password = "",
    Table = "",
    Port = 3306,
}

local bSuccess = pcall(require, "mysqloo")

local QUERY_QUEUE = {}
function Rust.MySQL:Query(query, callback, errCallback)
    callback = callback or function()end
    if not self.Initialized then
        table.insert(QUERY_QUEUE, {query, callback})
        return
    end

    if self.Database then
        if istable(query) then
            query = Rust.MySQL:ExpandFormatted(query)
        end

        local q = self.Database:query(query)
        q.onSuccess = function(q, data)
            callback(data)
        end

        q.onError = type(errCallback) == "function" and errCallback or function( err, sql )
            ErrorNoHalt("=============================\n[FATAL ERROR][MySQL] ERROR: ", err, "Query = \""..tostring(sql).."\"\n=============================\n")
        end

        q:start()
    else
        return callback(sql.Query(query))
    end
end

function Rust.MySQL:Format(str, ...)
    local fmt = {...}
    return {str, fmt}
end

function Rust.MySQL:ExpandFormatted(data)
    local query = data[1]
    local format = data[2]
    for i = 1, #format do
        format[i] = self.Database:escape(format[i])
    end

    return query:format(unpack(format))
end

function Rust.MySQL:Connect()
    self.Initialized = true
    if mysqloo then
        self.Database = mysqloo.connect(credentials.Host, credentials.Username, credentials.Password, credentials.Table, credentials.Password)
        self.Database.onConnectionFailed = function(db, err)
            ErrorNoHalt("\n=============================\n")
            ErrorNoHalt("[FATAL ERROR][MySQL] ERROR: ", err)
            ErrorNoHalt("\n=============================\n")
        end
        self.Database.onConnected = function(db)
            print("Connected to the MySQL database!")
            for i = 1, #QUERY_QUEUE do

                local query = QUERY_QUEUE[1]
                if istable(query) then
                    query = Rust.MySQL:ExpandFormatted(query)
                end
                self:Query(query, QUERY_QUEUE[2])
            end
        end
        self.Database:connect()
    end
    self.Initialized = true
end

Rust.MySQL:Connect()
