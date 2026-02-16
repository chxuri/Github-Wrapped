require "oauth2"

OAUTH_CLIENT = OAuth2::Client.new(
  ENV.fetch("OAUTH_CLIENT_ID"),
  ENV.fetch("OAUTH_CLIENT_SECRET"),
  site: "https://github.com",
  authorize_url: "/login/oauth/authorize",
  token_url: "/login/oauth/access_token"
)
