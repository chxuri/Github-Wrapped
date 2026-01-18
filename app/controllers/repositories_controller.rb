class RepositoriesController < ApplicationController
  def display
    response = Faraday.get("https://api.github.com/repositories")
  end
end
