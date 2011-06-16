# Application Generator Template
# Modifies a Rails app to use RSpec, Cucumber, Factory Girl, MySQL and Devise...

# Based on: http://github.com/fortuity/rails3-mongoid-devise/

# If you are customizing this template, you can use any methods provided by Thor::Actions
# http://rdoc.info/rdoc/wycats/thor/blob/f939a3e8a854616784cac1dcff04ef4f3ee5f7ff/Thor/Actions.html
# and Rails::Generators::Actions
# http://github.com/rails/rails/blob/master/railties/lib/rails/generators/actions.rb

puts "Modifying a new Rails app to use SQLite and Devise"

#----------------------------------------------------------------------------
# Create the database
#----------------------------------------------------------------------------
puts "creating the database..."
run 'rake db:create:all'

#----------------------------------------------------------------------------
# Set up git
#----------------------------------------------------------------------------
puts "setting up source control with 'git'..."
# specific to Mac OS X

append_file '.gitignore' do <<-FILE
.DS_Store
Thumbs.db
.rvmrc
*.log
*.swp
*.pid
*~ 
.redcar
tmp/**/*
config/database.yml
db/*.sqlite3
.idea
public/uploads/
nbproject/
public/static/
public/system/
FILE
end
git :init
git :add => '.'
git :commit => "-m 'Initial commit of unmodified new Rails app'"

#----------------------------------------------------------------------------
# Remove the usual cruft
#----------------------------------------------------------------------------
puts "removing unneeded files..."
run 'rm public/index.html'
run 'rm public/images/rails.png'
run 'rm README'
run 'touch README'


#----------------------------------------------------------------------------
# jQuery Option
#----------------------------------------------------------------------------
gem 'jquery-rails', '1.0.11'

#----------------------------------------------------------------------------
# Set up jQuery
#----------------------------------------------------------------------------

run 'rm public/javascripts/rails.js'
puts "replacing Prototype with jQuery"
# "--ui" enables optional jQuery UI
run 'rails generate jquery:install --ui'

#----------------------------------------------------------------------------
# Set up Devise
#----------------------------------------------------------------------------
puts "setting up Gemfile for Devise..."
append_file 'Gemfile', "\n# Bundle gem needed for Devise\n"
gem 'devise', '1.3.4'

puts "installing Devise gem (takes a few minutes!)..."
run 'bundle install'

puts "creating 'config/initializers/devise.rb' Devise configuration file..."
run 'rails generate devise:install'
run 'rails generate devise:views'

puts "modifying environment configuration files for Devise..."
gsub_file 'config/environments/development.rb', /# Don't care if the mailer can't send/, '### ActionMailer Config'
gsub_file 'config/environments/development.rb', /config.action_mailer.raise_delivery_errors = false/ do
<<-RUBY
config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  # A dummy setup for development - no deliveries, but logged
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default :charset => "utf-8"
RUBY
end
gsub_file 'config/environments/production.rb', /config.i18n.fallbacks = true/ do
<<-RUBY
config.i18n.fallbacks = true

  config.action_mailer.default_url_options = { :host => 'yourhost.com' }
  ### ActionMailer Config
  # Setup for production - deliveries, no errors raised
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default :charset => "utf-8"
RUBY
end

puts "creating a User model and modifying routes for Devise..."
run 'rails generate devise User'
run 'rake db:migrate'




#----------------------------------------------------------------------------
# Create a home page
#----------------------------------------------------------------------------
puts "create a home controller and view"
generate(:controller, "home index")
gsub_file 'config/routes.rb', /get \"home\/index\"/, 'root :to => "home#index"'

puts "set up a simple demonstration of Devise"
gsub_file 'app/controllers/home_controller.rb', /def index/ do
<<-RUBY
def index
    @users = User.all
RUBY
end

append_file 'app/views/home/index.html.erb' do <<-FILE
<% @users.each do |user| %>
  <p>User: <%=link_to user.email, user %></p>
<% end %>
  FILE
end

#----------------------------------------------------------------------------
# Create a users page
#----------------------------------------------------------------------------
generate(:controller, "users show")
gsub_file 'config/routes.rb', /get \"users\/show\"/, '#get \"users\/show\"'
gsub_file 'config/routes.rb', /devise_for :users/ do
<<-RUBY
devise_for :users
  resources :users, :only => :show
RUBY
end

gsub_file 'app/controllers/users_controller.rb', /def show/ do
<<-RUBY
before_filter :authenticate_user!

  def show
    @user = User.find(params[:id])
RUBY
end

append_file 'app/views/users/show.html.erb' do <<-FILE
<p>User: <%= @user.email %></p>
FILE
end

create_file "app/views/devise/menu/_login_items.html.erb" do <<-FILE
<% if user_signed_in? %>
<li>
<%= link_to('Logout', destroy_user_session_path) %>        
</li>
<% else %>
<li>
<%= link_to('Login', new_user_session_path)  %>  
</li>
<% end %>
FILE
end

create_file "app/views/devise/menu/_registration_items.html.erb" do <<-FILE
<% if user_signed_in? %>
<li>
<%= link_to('Edit account', edit_user_registration_path) %>
</li>
<% else %>
<li>
<%= link_to('Sign up', new_user_registration_path)  %>
</li>
<% end %>
FILE
end

puts "Setup blueprint"
get "https://raw.github.com/joshuaclayton/blueprint-css/master/blueprint/screen.css", "public/stylesheets/screen.css"
get "https://raw.github.com/joshuaclayton/blueprint-css/master/blueprint/ie.css", "public/stylesheets/ie.css"
get "https://raw.github.com/joshuaclayton/blueprint-css/master/blueprint/print.css", "public/stylesheets/print.css"

#----------------------------------------------------------------------------
# Generate Application Layout
#----------------------------------------------------------------------------
gsub_file 'app/views/layouts/application.html.erb', /<%= stylesheet_link_tag :all %>\n/, ''


inject_into_file 'app/views/layouts/application.html.erb', :after => "</title>\n" do
<<-RUBY
<link rel="stylesheet" href="/stylesheets/screen.css" type="text/css" media="screen, projection">
<link rel="stylesheet" href="/stylesheets/print.css" type="text/css" media="print">
<!--[if lt IE 8]>
  <link rel="stylesheet" href="/stylesheets/ie.css" type="text/css" media="screen, projection">
<![endif]-->
<link rel="stylesheet" href="/stylesheets/application.css" type="text/css" media="print">
RUBY
end


inject_into_file 'app/views/layouts/application.html.erb', :after => "<body>\n" do
<<-RUBY
<div class="container"> 
<ul class="hmenu">
<%= render 'devise/menu/registration_items' %>
<%= render 'devise/menu/login_items' %>
</ul>
<p style="color: green"><%= notice %></p>
<p style="color: red"><%= alert %></p>
RUBY
end

inject_into_file 'app/views/layouts/application.html.erb', :before => "\n</body>" do
<<-RUBY
</div>
RUBY
end

#----------------------------------------------------------------------------
# Add Stylesheets
#----------------------------------------------------------------------------
create_file 'public/stylesheets/application.css' do <<-FILE
ul.hmenu {
  list-style: none;	
  margin: 0 0 2em;
  padding: 0;
}

ul.hmenu li {
  display: inline;  
}
FILE
end

#----------------------------------------------------------------------------
# Create a default user
#----------------------------------------------------------------------------
puts "creating a default user"
append_file 'db/seeds.rb' do <<-FILE
puts 'SETTING UP DEFAULT USER LOGIN'
user = User.create! :email => 'holin.he@gmail.com', :password => 'please', :password_confirmation => 'please'
puts 'New user created'
FILE
end
run 'rake db:seed'

#----------------------------------------------------------------------------
# Setup RSpec & Cucumber
#----------------------------------------------------------------------------
puts 'Setting up RSpec, Cucumber, factory_girl, faker'
append_file 'Gemfile' do <<-FILE
gem "will_paginate", '3.0.pre2'
FILE
end 

run 'bundle install'
run 'script/rails generate rspec:install'
run 'script/rails generate cucumber:install'
run 'rake db:migrate'
run 'rake db:test:prepare'

run 'touch spec/factories.rb'
#----------------------------------------------------------------------------
# Finish up
#----------------------------------------------------------------------------
puts "checking everything into git..."
git :add => '.'
git :commit => "-am 'initial setup'"

puts "Done setting up your Rails app."
