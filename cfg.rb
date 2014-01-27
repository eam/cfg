#!/usr/bin/ruby

require 'bundler/setup'
require 'mysql2'
require 'sequel'
require 'sinatra'

DB = Sequel.mysql2(host: 'localhost', user: 'cfg', database: 'cfg') unless defined?(DB)


MaxDepth = 100

# Find all tuples that belong to id, and
# return one at random.
def random_result(id)
	result = DB[:cfg_map].where('map_key = ?', id).order(Sequel.lit('rand()')).limit(1)
	sql = result.sql
	result = result.first

	puts "#{sql} #=> #{result[:map_val]}"

	if !result
		raise "Can't find a record for $#{id}"
	else
		result[:map_val]
	end
end

# Recusively re-parse until MaxDepth is hit or no more to interpolate
# FIXME: layered '$' need work, better regex
def parse(target, depth)
  target.gsub!(/([^$])(\$*)\$(\w+)/) do |s|
    "#{$1}#{$2}" + random_result($3)
  end
  if target[/[^$]\$*\$\w+/] == nil
    target
  elsif depth < MaxDepth
    parse(target, depth + 1)
  else
    "Max depth reached"
  end
end


print parse(' $' + ARGV[0].to_s, 0), "\n"


get '/quote/:name' do
  "#{params[:name]} says: #{parse(' $' + params[:name], 0)}"
end

get '/list' do
  
end
