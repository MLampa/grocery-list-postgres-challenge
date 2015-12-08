require "sinatra"
require "pg"
require 'pry'

configure :development do
  set :db_config, { dbname: "grocery_list_development" }
end

configure :test do
  set :db_config, { dbname: "grocery_list_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

def get_groceries
  db_connection do |conn|
    sql_query = 'SELECT * FROM groceries'
    conn.exec(sql_query)
  end
end

def save_groceries(params)
  unless params[:name].empty?
    db_connection do |conn|
      sql_query = 'INSERT INTO groceries (name) VALUES ($1)'
      data = [params[:name]]
      conn.exec_params(sql_query, data)
    end
  end
end

def get_items(id)
  db_connection do |conn|
    sql_query = %(
      SELECT *
      FROM groceries
      WHERE groceries.id = ($1)
    )
    data = [id]
    conn.exec_params(sql_query, data)
  end
end

def get_grocery_item(id)
  db_connection do |conn|
    sql_query = %(
    SELECT groceries.*, comments.*
    FROM groceries
    FULL JOIN comments ON groceries.id = comments.grocery_id
    WHERE groceries.id = ($1)
    )
    data = [id]
    conn.exec_params(sql_query, data)
  end
end

def save_items(params)
    db_connection do |conn|
      sql_query = 'INSERT INTO groceries (body, grocery_id)
      VALUES ($1, $2)'
      data = [params[:body], params[:grocery_id]]
      conn.exec_params(sql_query, data)
    end

end

get "/" do
  redirect "/groceries"
end

get "/groceries" do
  @groceries = get_groceries
  erb :groceries
end

get "/groceries/:id" do
  @grocery_items = get_items(params[:id]).first
  @items = get_grocery_item(params[:id])
  erb :show
end

post "/groceries/:id" do
  save_items(params)
  redirect '/groceries'
end

post "/groceries" do
  save_groceries(params)
  redirect "/groceries"
end
