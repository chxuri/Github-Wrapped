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

    # puts "Response status: #{response.status}"
    # puts "Response body: #{response.body.inspect}"
    @repos = JSON.parse(response.body)

    test = Faraday.get("https://api.github.com/repos/#{@repos[1]["owner"]["login"]}/#{@repos[1]["name"]}/commits") do |req|
          req.params["page"] = 1
          req.params["per_page"] = 100
          req.headers["Authorization"] = "Bearer #{session[:github_token]}"
          req.headers["Accept"] = "application/vnd.github.v3+json"
          req.headers["User-Agent"] = "wrapped"
    end

    @onePageTest = JSON.parse(test.body)

    maxCommits = 0
    @mostCommitted = @repos[0]
    @longestTimeRepo = @repos[0]
    @commits = ""
    @mostTime = 0

    @repos.each do |repo|
      repoTime = 0
      commitCount = 0
      page = 1
      loop do
        commitList = Faraday.get("https://api.github.com/repos/#{repo["owner"]["login"]}/#{repo["name"]}/commits") do |req|
          req.params["page"] = page
          req.params["per_page"] = 100
          req.headers["Authorization"] = "Bearer #{session[:github_token]}"
          req.headers["Accept"] = "application/vnd.github.v3+json"
          req.headers["User-Agent"] = "wrapped"
        end

        @commits = JSON.parse(commitList.body)

        break if @commits.empty?
        commitCount += @commits.size
        page += 1

        # loops thru commits in each repo and checks date + time
        loopCounter = 0
        for i in 0..@commits.length-2
          @debugger = "works"
          year2025 = @commits[i]["commit"]["author"]["date"][0, 4] == "2025"
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
            elsif nextHour - hour = 1
              repoTime += 60 - minute + nextMinute
            else
              repoTime += 60 - minute + nextMinute + 60
            end
          end

          loopCounter += 1
        end
      end

      if commitCount > maxCommits
        @mostCommitted = repo
        maxCommits = commitCount
      end

      if repoTime > @mostTime
        @mostTime = repoTime
        @longestTime = repo
      end
    end
  end


  # token.get("https://api.github.com/user/repos")
end
