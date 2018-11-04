ActiveRecord::Base.establish_connection(database: 'reencode.db', adapter: 'sqlite3')

class Medium < ActiveRecord::Base
end
