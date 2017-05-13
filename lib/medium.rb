ActiveRecord::Base.establish_connection(database: 'data.sqlite3', adapter: 'sqlite3')

class Medium < ActiveRecord::Base
end
