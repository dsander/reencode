require 'active_record'
require_relative 'lib/medium'

namespace :db do
  desc 'Create database'
  task :create do
    ActiveRecord::Base.connection.execute <<-EOS
      CREATE SEQUENCE media_id_seq;
      CREATE TABLE media (
       id integer NOT NULL DEFAULT nextval('media_id_seq'::regclass),
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
