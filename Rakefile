require 'active_record'
require_relative 'lib/medium'

namespace :db do
  desc 'Create database'
  task :create do
    ActiveRecord::Base.connection.execute <<-EOS
      CREATE TABLE media (
       id integer PRIMARY KEY,
       path string NOT NULL UNIQUE,
       mtime integer NOT NULL,
       width integer NOT NULL,
       bit_depth integer NOT NULL,
       hevc boolean NOT NULL,
       size integer NOT NULL,
       duration integer NOT NULL,
       locked boolean DEFAULT 'f',
       failed boolean DEFAULT 'f'
      );
      CREATE UNIQUE INDEX media_path ON media(path);
    EOS
  end

  desc 'Drop database'
  task :drop do
    FileUtils.rm('data.sqlite3')
  end
end
