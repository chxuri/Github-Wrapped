class SessionsController < ApplicationController
  def new
    redirect_to OAUTH_CLIENT.auth_code.authorize_url(
      redirect_uri: callback_url,
      scope: "user:email read:user"
    ), allow_other_host: true
  end

  def create
    # puts callback_url
    code = params[:code]
    token = OAUTH_CLIENT.auth_code.get_token(code, redirect_uri: callback_url)
    response = token.get("https://api.github.com/user")
    user_data = JSON.parse(response.body)

    session[:github_token] = token.token
    session[:github_username] = user_data["login"]
    session[:github_name] = user_data["name"]

    redirect_to root_path, notice: "Signed in as #{session[:github_name]}"
  end

  # def current_user
  # @current_user ||= User.find_by(id: session[:user_id])
  # session[:github_name]
  # <p>Session user id: <%= session[:user_id].inspect %></p>
  # end

  def callback_url
    if Rails.env.production?
      "https://brief-kaycee-chxuri-cac0f3b7.koyeb.app/auth/callback"
    else
      "http://localhost:3000/auth/callback"
    end
    # "#{request.base_url}/auth/callback"
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Logged out!"
  end


  def index
    return unless logged_in?
    # Rails.logger.debug "TOKEN: #{session[:github_token].inspect}"
    response = Faraday.get("https://api.github.com/user/repos") do |req|
      req.headers["Authorization"] = "Bearer #{session[:github_token]}"
      req.headers["Accept"] = "application/vnd.github.v3+json"
      req.headers["User-Agent"] = "wrapped"
    end

    # puts "Response status: #{response.status}"
    # puts "Response body: #{response.body.inspect}"
    @repos = JSON.parse(response.body)
    unless @repos.is_a?(Array)
      @repos = []
      return
    end

    return if @repos.blank?

    # test = Faraday.get("https://api.github.com/repos/#{@repos[1]["owner"]["login"]}/#{@repos[1]["name"]}/commits") do |req|
    #      req.params["page"] = 1
    #      req.params["per_page"] = 100
    #      req.headers["Authorization"] = "Bearer #{session[:github_token]}"
    #   req.headers["Accept"] = "application/vnd.github.v3+json"
    #  req.headers["User-Agent"] = "wrapped"
    # end

    # @onePageTest = JSON.parse(test.body)

    @maxCommits = 0
    @mostCommitted = @repos.first
    @longestTimeRepo = @repos.first
    @commits = ""
    @mostTime = 0

    @repos.each do |repo|
      repoTime = 0
      commitCount = 0
      page = 1
      loop do
        # Rails.logger.info repo.class
        # Rails.logger.info repo.inspect
        commitList = Faraday.get("https://api.github.com/repos/#{repo["owner"]["login"]}/#{repo["name"]}/commits") do |req|
          req.params["page"] = page
          req.params["per_page"] = 100
          req.headers["Authorization"] = "Bearer #{session[:github_token]}"
          req.headers["Accept"] = "application/vnd.github.v3+json"
          req.headers["User-Agent"] = "wrapped"
        end

        @commits = JSON.parse(commitList.body)

        break if @commits.empty?
        # commitCount += @commits.size
        # page += 1

        # loops thru commits in each repo and checks date + time
        @loopCounter = 0
        for i in 0..@commits.length-2
          if @commits[i]["author"] && @commits[i]["author"]["login"] == session[:github_username]

            # <!--<p>name: <%= @current_user.name %><p>-->
            # @commitCheck = @commits[0]["commit"]["author"]["date"][0, 4].to_i
            # @debugger = "works"
            year2025 = (@commits[i]["commit"]["author"]["date"][0, 4].to_i == 2025)
            month = @commits[i]["commit"]["author"]["date"][5, 7].to_i
            nextMonth = @commits[i+1]["commit"]["author"]["date"][5, 7].to_i
            day = @commits[i]["commit"]["author"]["date"][8, 10].to_i
            nextDay = @commits[i+1]["commit"]["author"]["date"][8, 10].to_i
            hour = @commits[i]["commit"]["author"]["date"][11, 13].to_i
            nextHour = @commits[i+1]["commit"]["author"]["date"][11, 13].to_i
            minute = @commits[i]["commit"]["author"]["date"][14, 16].to_i
            nextMinute = @commits[i+1]["commit"]["author"]["date"][14, 16].to_i

            checkTime = false

            if year2025 && (month == nextMonth) && (day == nextDay)
              if (nextHour - hour <= 1) || (nextHour - hour == 2 && (60 - minute + nextMinute + 60 <= 90))
                checkTime = true
              end
            elsif year2025 && (month == nextMonth + 1 && nextDay == 1) || (day + 1 == nextDay)
              if (nextHour - hour <= 1) || ((nextHour - hour == 2 || 12 - nextHour - hour == 2) && (60 - minute + nextMinute + 60 <= 90))
                checkTime = true
              end
            end

            if checkTime
              if nextHour - hour == 0
                repoTime += nextMinute - minute
              elsif nextHour - hour == 1
                repoTime += 60 - minute + nextMinute
              else
                repoTime += 60 - minute + nextMinute + 60
              end
            end

            @loopCounter += 1
            commitCount += 1
          end
        end
        page += 1
      end

      if commitCount > @maxCommits
        @mostCommitted = repo
        @maxCommits = commitCount
      end

      if repoTime > @mostTime
        @mostTime = repoTime
        @longestTimeRepo = repo
      end
    end
  end


  # token.get("https://api.github.com/user/repos")
end
