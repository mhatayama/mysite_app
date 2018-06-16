require './config/config'

require 'sequel'
DB = Sequel.connect($cfg[:sequel_conn])

require './lib/bluebozu/post'
require 'find'

def create_table
  DB.drop_table?(:posts)
  DB.create_table :posts do
    String :post_id, primary_key: true
    String :title
    String :content, text: true
    Date :date
    String :category
  end
end

def build_db(posts_path)
  Find.find(posts_path) do |path|
    next unless File.file?(path)
    next unless File.extname(path) == ".md"

    a_date, a_post_id = File.basename(path, ".md").split('_')
    a_category = File.dirname(path).split(File::SEPARATOR).last

    a_title, a_content = nil, nil
    File.open(path, "r") do |f|
      lines = f.readlines
      first_line = lines.first
      if first_line.start_with?('# ') then
        a_title = first_line[2..-1].chomp
        a_content = lines[1..-1].join
      else
        puts "Error: can't read title #{File.absolute_path(path)}"
        raise Sequel::Rollback
      end
    end

    post = Post.create do |p|
      p.post_id = a_post_id
      p.title = a_title
      p.content = a_content
      p.date = a_date
      p.category = a_category
    end

    puts "Saved: #{post.post_id}"
  end
end

posts_path = ARGV[0]
unless posts_path then
  puts "Error: enter the posts path."
  exit 1
end

DB.transaction do
  create_table
  build_db(posts_path)
end

exit
