# First-boot setup, run by `rails runner` after migrations. Exits non-zero to be run again next boot.
email = ENV["DISCOURSE_ADMIN_EMAIL"].to_s.strip
password = ENV["DISCOURSE_ADMIN_PASSWORD"].to_s

# Railway's edge terminates TLS and forwards plain HTTP; without this, links and cookies say http.
SiteSetting.force_https = true

if User.real.where(admin: true).exists?
  puts "railway-setup: an admin exists, nothing to do"
  exit 0
end
if email.empty? || password.length < SiteSetting.min_admin_password_length
  puts "railway-setup: set DISCOURSE_ADMIN_EMAIL and a DISCOURSE_ADMIN_PASSWORD of at least " \
       "#{SiteSetting.min_admin_password_length} characters to create the admin"
  exit 1
end

user = User.new(email: email, username: UserNameSuggester.suggest(email.split("@").first),
                password: password, active: true, approved: true, trust_level: TrustLevel[4])
user.save!
user.grant_admin!
user.email_tokens.update_all(confirmed: true)
user.activate
puts "railway-setup: created admin #{user.username} <#{email}>"
