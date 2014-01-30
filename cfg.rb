#!/usr/bin/ruby

require 'bundler/setup'
require 'sinatra/base'
require 'mysql2'
require 'sequel'


class CFG < Sinatra::Base
  use Rack::Logger

  configure do
    set :db, Sequel.mysql2(host: 'localhost', user: 'cfg', database: 'cfg')
    set :max_depth, 100
  end

  helpers do
    def logger
      request.logger
    end
  end


  # Find all tuples that belong to id, and
  # return one at random.
  def random_result(id)
  	result = settings.db[:cfg_map].where('map_key = ?', id).order(Sequel.lit('rand()')).limit(1)
  	sql = result.sql
  	result = result.first

  	logger.debug "#{sql} #=> #{result[:map_val]}"

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
    elsif depth < settings.max_depth
      parse(target, depth + 1)
    else
      "Max depth reached"
    end
  end



  get '/quote/:name' do
    "#{params[:name]} says: #{parse(' $' + params[:name], 0)}"
  end

  get '/list' do
    
  end

  get '/' do

  end


end



