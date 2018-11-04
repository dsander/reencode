require 'active_record'
require_relative 'lib/medium'

namespace :db do
  desc 'Create database'
  task :create do
    ActiveRecord::Base.connection.execute <<-EOS
      CREATE TABLE media (
       id INTEGER  NOT NULL PRIMARY KEY AUTOINCREMENT ,
       path text NOT NULL UNIQUE,
       mtime integer NOT NULL,
       width integer NOT NULL,
       bit_depth integer NOT NULL,
       hevc boolean NOT NULL,
       size integer NOT NULL,
       duration integer NOT NULL,
       locked boolean DEFAULT false,
       failed boolean DEFAULT false
      );
      CREATE UNIQUE INDEX media_path ON media(path);
      CONSTRAINT media_pkey PRIMARY KEY (id);
    EOS
  end

  desc 'Drop database'
  task :drop do
    ActiveRecord::Base.connection.execute 'DROP TABLE media;'
  end
end
