ActiveRecord::Base.establish_connection(database: 'reencode', adapter: 'postgresql', user: 'reencode', password: 'password', host: 'htpc')

class Medium < ActiveRecord::Base
end
