#!/usr/bin/ruby

require 'bundler/setup'
require 'sinatra/base'
require 'mysql2'
require 'sequel'

class CFG < Sinatra::Base
  use Rack::Logger

  configure do
    # way too lazy to make 50000 erb files
    enable :inline_templates

    # turn on logging. FIXME: why does DEBUG not take?
    set :logging, Logger::DEBUG

    # global database object
    set :db, Sequel.mysql2(host: 'localhost', user: 'cfg', database: 'cfg')

    # max number of times to recurse. this is absurdly
    set :max_depth, 100
  end


  # Find all tuples that belong to id, and
  # return one at random.
  def random_result(id)
    result = settings.db[:cfg_map].where('map_key = ?', id).order(Sequel.lit('rand()')).limit(1)
    sql = result.sql
    result = result.first  

    logger.debug "searching for #{id}"
    if !result
      raise "Can't find a record for $#{id}"
    else
      logger.debug "#{sql} #=> #{result[:map_val]}"
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


  # Creates a new entry in the table with the (k)ey and (v)al
  # Returns the id of the new row
  def create(k, v)
    # just anal about logging sql, so heres this
    logger.debug settings.db[:cfg_map].insert_sql(map_key: k, map_val: v)

    # actually create the row. returns the id of the new record
    settings.db[:cfg_map].insert(map_key: k, map_val: v)
  end



  ### Sinatra routes
  get '/quote/:name' do
    erb :quote, locals: { 
      who: params[:name], 
      what: parse(' $' + params[:name], 0)
    }
  end

  get '/list' do
    "what even is a database"
  end

  get '/new' do
    erb :new
  end

  post '/create' do
    id = create(params[:key], params[:val])    
    redirect to("/quote/#{params[:key]}")
  end
end


__END__

@@ layout
<html>
  <head>
    <title>CFG</title>
  </head>
  <body>
    <h1>C F G</h1>
    <%= yield %>
  </body>
</html>

@@ new
<form action='/create' method="post">
  <p>
    <label for='key'>Key:</label>
    <input name='key' value='' />
  </p>

  <p>
    <label for='val'>Val:</label>
    <input name='val' value='' />  
  </p>
  <input type='submit' value="Create Record" />
</form>

@@ quote
<strong><%= who %></strong> says <strong><%= what %></strong>
