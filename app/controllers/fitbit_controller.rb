#http://www.fitbitclient.com/guide/getting-started
#http://keas-fitbit.herokuapp.com/fitbit?oauth_token=c03f209de94008314375dfc3ec922340&oauth_verifier=mc51um9ohths7l80jb71h7513e

class FitbitController < ApplicationController
  
  def authorize
    
  end
  
  def index 
    # Load the existing yml config
    config = begin
      Fitgem::Client.symbolize_keys(YAML.load(File.open("config/.fitgem.yml")))
    rescue ArgumentError => e
      puts "Could not parse YAML: #{e.message}"
      exit
    end
    client = Fitgem::Client.new(config[:oauth])
  
    # With USER CREDENTIALS token and secret, try to use them to reconstitute a usable Fitgem::Client
    if config[:oauth][:token] && config[:oauth][:secret]
      begin
        access_token = client.reconnect(config[:oauth][:token], config[:oauth][:secret])
      rescue Exception => e
        puts "Error: Could not reconnect Fitgem::Client due to invalid keys in .fitgem.yml"
        exit
      end
    # Without USER CREDENTIALS secret and token, initialize Fitgem::Client
    # and send user to login and get a verifier token
    else
      request_token = client.request_token
      token = request_token.token
      secret = request_token.secret
      auth_url = "http://www.fitbit.com/oauth/authorize?oauth_token=#{token}"
    
      #User shouldbe redirected back to callback URL you previously setup on Fitbit API Developer site
    
      puts "Go to #{auth_url} and then enter the verifier code below"
      verifier = gets.chomp  #whatever was typed in the command line

      begin
        access_token = client.authorize(token, secret, { :oauth_verifier => verifier })
      rescue Exception => e
        puts "Error: Could not authorize Fitgem::Client with supplied oauth verifier"
        exit
      end

      puts 'Verifier is: '+verifier
      puts "Token is:    "+access_token.token
      puts "Secret is:   "+access_token.secret

      user_id = client.user_info['user']['encodedId']
      puts "Current User is: "+user_id

      config[:oauth].merge!(:token => access_token.token, :secret => access_token.secret, :user_id => user_id)

      # Write the whole oauth token set back to the config file
      File.open("config/.fitgem.yml", "w") {|f| f.write(config.to_yaml) }
    end
  end

  
end