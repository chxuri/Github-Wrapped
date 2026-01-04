require "oauth2"

OAUTH_CLIENT = OAuth2::Client.new(
  ENV["OAUTH_CLIENT_ID"],
  ENV["OAUTG_CLIENT_SECRET"],
  site: "https://github.com",
  authorize_url: "/login/oauth/authorize",
  token_url: "/oauth/token"
)
