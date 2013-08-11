require 'sinatra'
require 'haml'
require 'csv'
require 'json'
require 'sinatra/reloader'

helpers do
  def reload_data(file='data.csv')
    csv_data = CSV.read file
    headers = csv_data.shift.map {|i| i.to_s }
    string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
    array_of_hashes = string_data.map {|row| Hash[*headers.zip(row).flatten] }


    headers << "Drafted" unless headers.include? "Drafted"

    array_of_hashes.map{|player|
      if player["Drafted"]=="true" || player["Drafted"] == true
        player["Drafted"]=true
      else
        player["Drafted"]=false
      end
    }

    settings.data_headers = headers
    settings.draft_rankings = array_of_hashes
  end
end

configure do
  file = 'FFN_Draft_Rankings.csv'
  # file = 'data.csv'
  csv_data = CSV.read file
  headers = csv_data.shift.map {|i| i.to_s }
  string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
  array_of_hashes = string_data.map {|row| Hash[*headers.zip(row).flatten] }


  headers << "Drafted" unless headers.include? "Drafted"

  array_of_hashes.map{|player|
    if player["Drafted"]=="true" || player["Drafted"] == true
      player["Drafted"]=true
    else
      player["Drafted"]=false
    end
  }

  set :data_headers, headers
  set :draft_rankings, array_of_hashes

  # csv_data = CSV.read 'data.csv'
  # headers = csv_data.shift.map {|i| i.to_s }
  # string_data = csv_data.map {|row| row.map {|cell| cell.to_s } }
  # array_of_hashes = string_data.map {|row| Hash[*headers.zip(row).flatten] }

  # headers << "Drafted" unless headers.include? "Drafted"
  # array_of_hashes.map{|player| player["Drafted"]||=false}
end

get "/" do
  haml :show
end

get "/load" do
  content_type :json
  settings.draft_rankings.to_json
end

get "/best" do
  content_type :json

  pos = params[:position]
  bye = Integer(params[:bye]) rescue nil

  results = settings.draft_rankings.select{|p| p["Drafted"] == false}

  results = settings.draft_rankings.select{|p| p["Position"] == pos} unless pos == "All"
  results = results.select{|p| p["Bye Week"].to_i!=bye} if bye

  results.sort{|a,b| a["Overall Rank"].to_i<=>b["Overall Rank"].to_i}.reverse

  "#{results.first["Player"]} (#{results.first["Position"]})"
end

post "/save" do
  content_type :json
  ph = JSON.parse(params[:players])
  f=open('data.csv','w')
  f.write settings.data_headers.join(',') + "\n"
  ph.map{|player| f.write(player.values.join(',') + "\n")}
  f.close
  reload_data
  settings.draft_rankings.to_json
end