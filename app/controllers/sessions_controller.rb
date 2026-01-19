class SessionsController < ApplicationController
  def new
    redirect_to OAUTH_CLIENT.auth_code.authorize_url(
      redirect_uri: callback_url,
      scope: "user:email read:user"
    ), allow_other_host: true
  end

  def create
    code = params[:code]
    token = OAUTH_CLIENT.auth_code.get_token(code, redirect_uri: callback_url)
    response = token.get("https://api.github.com/user")
    user_data = JSON.parse(response.body)

    user = User.find_or_create_by(email: user_data["email"]) do |u|
      u.name = user_data["name"]
    end

    session[:user_id] = user.id
    session[:github_token] = token.token

    redirect_to root_path, notice: "Signed in as #{user.name}"
  end

  def callback_url
    "#{request.base_url}/auth/callback"
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Logged out!"
  end

  def index
    return unless logged_in?
    response = Faraday.get("https://api.github.com/user/repos") do |req|
      req.headers["Authorization"] = "Bearer #{session[:github_token]}"
      req.headers["Accept"] = "application/vnd.github.v3+json"
      req.headers["User-Agent"] = "wrapped"
    end
    puts "Response status: #{response.status}"
    puts "Response body: #{response.body.inspect}"
    @repos = JSON.parse(response.body)
  end


  # token.get("https://api.github.com/user/repos")
end
