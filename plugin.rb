# plugin.rb
# name: IW4MADMIN Linking
# about: An account linking system to the official Project Moon webfront
# version: 0.0.1
# authors: Sword
# url: https://github.com/SwordSWD/forlink

gem 'rbnacl', '3.4.0'
gem 'event_emitter', '0.2.6'
gem 'websocket', '1.2.8'
gem 'websocket-client-simple', '0.3.0'
gem 'opus-ruby', '1.0.1', { require: false }
gem 'netrc', '0.11.0'
gem 'mime-types-data', '3.2019.1009'
gem 'mime-types', '3.3.1'
gem 'domain_name', '0.5.20180417'
gem 'http-cookie','1.0.3'
gem 'http-accept', '1.7.0', { require: false }
gem 'rest-client', '2.1.0.rc1'

# Add custom route to the Discourse app
Discourse::Application.routes.append do
  post 'requesttoken' => 'requesttoken#index'
end

# Create a new controller to handle the request
class RequesttokenController < ApplicationController
  requires_plugin 'my_plugin'

  def index
    # Make a POST request to the api/client endpoint
    response = Net::HTTP.post(
      URI("https://panel.projectmoon.pw/api/client/#{current_user.id}/login"),
      { password: 'somepassword' }.to_json,
      'Content-Type' => 'application/json'
    )

    if response.is_a?(Net::HTTPSuccess)
      # Handle success response
      current_user.custom_fields['linked_account'] = "https://panel.projectmoon.pw/Client/Profile/#{response.body}"
      current_user.save_custom_fields

      render json: { success: true }
    else
      # Handle error response
      render json: { success: false, error: response.message }
    end
  end
end

DiscourseEvent.on(:inject_custom_html) do |doc|
  if current_user && current_user.custom_fields['linked_account'].present?
    doc.css('header .d-header-buttons').append("<a class='btn btn-primary' href='#{current_user.custom_fields['linked_account']}'>Linked Account</a>")
  else
    doc.css('header .d-header-buttons').append('<a class="btn btn-primary" href="/requesttoken">Link Account</a>')
  end
end
